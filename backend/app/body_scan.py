from __future__ import annotations

import base64
import binascii
from io import BytesIO

import numpy as np
from PIL import Image, ImageOps, UnidentifiedImageError
from sklearn.ensemble import RandomForestRegressor

from .schemas import BodyScanRequest, BodyScanResponse, Measurements


MEASUREMENT_NAMES = (
    "height",
    "neck",
    "shoulder",
    "chest",
    "underbust",
    "waist",
    "high_hip",
    "hip",
    "sleeve",
    "wrist",
    "inseam",
)

MEASUREMENT_LIMITS = {
    "height": (120.0, 230.0),
    "neck": (20.0, 70.0),
    "shoulder": (25.0, 75.0),
    "chest": (55.0, 190.0),
    "underbust": (50.0, 170.0),
    "waist": (45.0, 190.0),
    "high_hip": (55.0, 200.0),
    "hip": (60.0, 210.0),
    "sleeve": (35.0, 90.0),
    "wrist": (10.0, 35.0),
    "inseam": (45.0, 110.0),
}


class BodyScanError(ValueError):
    pass


class BodyScanEstimator:
    """Experimental silhouette-to-measurement regression.

    The estimator intentionally reports conservative confidence. Training data
    is synthetic and the model has not been validated for purchasing, medical,
    or made-to-measure use.
    """

    def __init__(self) -> None:
        self._model = self._build_model()

    @staticmethod
    def _build_model() -> RandomForestRegressor:
        rng = np.random.default_rng(2026)
        rows: list[list[float]] = []
        targets: list[list[float]] = []

        for _ in range(2600):
            height = float(np.clip(rng.normal(168, 12), 135, 210))
            frame = float(np.clip(rng.normal(1.0, 0.16), 0.68, 1.48))
            shoulder = float(np.clip(height * (0.235 + 0.025 * (frame - 1)) + rng.normal(0, 1.3), 28, 61))
            chest = float(np.clip(height * 0.54 * frame + rng.normal(0, 4), 58, 170))
            waist = float(np.clip(chest * rng.uniform(0.70, 0.96), 46, 168))
            hip = float(np.clip(max(waist * rng.uniform(1.04, 1.28), chest * rng.uniform(0.92, 1.12)), 62, 185))
            underbust = float(np.clip(chest * rng.uniform(0.84, 0.94), 52, 160))
            high_hip = float(np.clip((waist + hip) * rng.uniform(0.48, 0.53), 57, 185))
            neck = float(np.clip(shoulder * rng.uniform(0.80, 0.92), 24, 58))
            sleeve = float(np.clip(height * rng.uniform(0.335, 0.375), 40, 83))
            wrist = float(np.clip(height * rng.uniform(0.087, 0.108), 11, 25))
            inseam = float(np.clip(height * rng.uniform(0.435, 0.495), 52, 102))

            visible_shoulder = shoulder * rng.normal(1.0, 0.025)
            visible_chest = chest / rng.normal(1.92, 0.08)
            visible_waist = waist / rng.normal(2.02, 0.09)
            visible_hip = hip / rng.normal(1.91, 0.08)
            rows.append([height, visible_shoulder, visible_chest, visible_waist, visible_hip])
            targets.append(
                [height, neck, shoulder, chest, underbust, waist, high_hip, hip, sleeve, wrist, inseam]
            )

        model = RandomForestRegressor(
            n_estimators=180,
            max_depth=16,
            min_samples_leaf=3,
            random_state=2026,
            n_jobs=-1,
        )
        model.fit(np.asarray(rows), np.asarray(targets))
        return model

    def analyze(self, request: BodyScanRequest) -> BodyScanResponse:
        image = self._decode_image(request.image_base64)
        array = self._prepare_image(image)
        mask, separation = self._foreground_mask(array)
        bounds = self._subject_bounds(mask)
        x_min, y_min, x_max, y_max = bounds
        subject_height_px = y_max - y_min + 1
        scale = request.reference_height_cm / subject_height_px

        ratios = (0.22, 0.33, 0.49, 0.61)
        widths = [self._width_at(mask, bounds, ratio) * scale for ratio in ratios]
        row = np.asarray([[request.reference_height_cm, *widths]], dtype=float)
        raw = self._model.predict(row)[0]
        raw[0] = request.reference_height_cm

        values: dict[str, float] = {}
        for index, name in enumerate(MEASUREMENT_NAMES):
            low, high = MEASUREMENT_LIMITS[name]
            values[name] = round(float(np.clip(raw[index], low, high)), 1)

        quality, warnings = self._quality(mask, bounds, separation)
        confidence_multipliers = {
            "height": 0.99,
            "neck": 0.52,
            "shoulder": 0.82,
            "chest": 0.72,
            "underbust": 0.52,
            "waist": 0.70,
            "high_hip": 0.64,
            "hip": 0.73,
            "sleeve": 0.57,
            "wrist": 0.42,
            "inseam": 0.62,
        }
        confidence = {
            name: round(float(np.clip(quality * multiplier, 0.25, 0.92)), 2)
            for name, multiplier in confidence_multipliers.items()
        }
        scan_confidence = round(float(np.mean(list(confidence.values()))), 2)

        return BodyScanResponse(
            measurements=Measurements(**values),
            scan_confidence=scan_confidence,
            image_quality=round(quality, 2),
            measurement_confidence=confidence,
            quality_warnings=warnings,
            model_version="body-silhouette-rf-demo-0.1.0",
            validation_status=(
                "Unvalidated prototype. ROC-AUC is not an appropriate metric for continuous "
                "measurements; evaluate with centimetre MAE and within-tolerance rate on a "
                "consented, diverse reference dataset."
            ),
            disclaimer=(
                "Photo-derived measurements are approximate and can change with pose, clothing, "
                "lens distortion, and camera angle. Verify with a tape measure and each brand's "
                "garment chart before purchasing or altering clothing."
            ),
        )

    @staticmethod
    def _decode_image(value: str) -> Image.Image:
        encoded = value.split(",", 1)[-1] if value.startswith("data:") else value
        try:
            raw = base64.b64decode(encoded, validate=True)
        except (binascii.Error, ValueError) as error:
            raise BodyScanError("The captured photo could not be decoded.") from error
        if len(raw) > 12 * 1024 * 1024:
            raise BodyScanError("The photo is larger than the 12 MB scan limit.")
        try:
            return ImageOps.exif_transpose(Image.open(BytesIO(raw))).convert("RGB")
        except (UnidentifiedImageError, OSError) as error:
            raise BodyScanError("Use a valid JPEG, PNG, or WebP photo.") from error

    @staticmethod
    def _prepare_image(image: Image.Image) -> np.ndarray:
        if image.width < 96 or image.height < 160:
            raise BodyScanError("Use a clearer full-body photo with more resolution.")
        scale = min(1.0, 512 / max(image.width, image.height))
        if scale < 1:
            image = image.resize(
                (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
                Image.Resampling.LANCZOS,
            )
        return np.asarray(image, dtype=np.float32)

    @staticmethod
    def _foreground_mask(image: np.ndarray) -> tuple[np.ndarray, float]:
        height, width, _ = image.shape
        side = max(2, round(width * 0.07))
        top = max(2, round(height * 0.04))
        border = np.concatenate(
            [
                image[:, :side].reshape(-1, 3),
                image[:, -side:].reshape(-1, 3),
                image[:top].reshape(-1, 3),
            ]
        )
        background = np.median(border, axis=0)
        distance = np.linalg.norm(image - background, axis=2)
        border_distance = np.linalg.norm(border - background, axis=1)
        threshold = float(np.clip(np.percentile(border_distance, 90) * 1.8, 24, 68))
        mask = distance > threshold

        for _ in range(2):
            padded = np.pad(mask.astype(np.uint8), 1)
            neighbours = sum(
                padded[y : y + height, x : x + width]
                for y in range(3)
                for x in range(3)
            )
            mask = neighbours >= 4

        subject_distance = distance[mask]
        separation = 0.0 if subject_distance.size == 0 else float(np.mean(subject_distance) / 180)
        return mask, float(np.clip(separation, 0, 1))

    @staticmethod
    def _subject_bounds(mask: np.ndarray) -> tuple[int, int, int, int]:
        height, width = mask.shape
        rows = np.where(mask.sum(axis=1) >= max(3, width * 0.018))[0]
        columns = np.where(mask.sum(axis=0) >= max(3, height * 0.012))[0]
        if rows.size == 0 or columns.size == 0:
            raise BodyScanError("No full-body silhouette was found. Use a plain, contrasting background.")

        x_min, x_max = int(columns[0]), int(columns[-1])
        y_min, y_max = int(rows[0]), int(rows[-1])
        if (y_max - y_min) < height * 0.43 or (x_max - x_min) < width * 0.08:
            raise BodyScanError("Move back so the full person is visible from head to feet.")
        return x_min, y_min, x_max, y_max

    @staticmethod
    def _width_at(
        mask: np.ndarray,
        bounds: tuple[int, int, int, int],
        ratio: float,
    ) -> float:
        x_min, y_min, x_max, y_max = bounds
        height = y_max - y_min + 1
        center_y = y_min + round(height * ratio)
        radius = max(2, round(height * 0.025))
        samples: list[int] = []
        for row in mask[max(y_min, center_y - radius) : min(y_max + 1, center_y + radius + 1)]:
            active = np.where(row[x_min : x_max + 1])[0]
            if active.size:
                splits = np.split(active, np.where(np.diff(active) > 2)[0] + 1)
                samples.append(max(len(run) for run in splits))
        if not samples:
            raise BodyScanError("The body outline is incomplete. Retake the photo against a plain background.")
        return float(np.percentile(samples, 70))

    @staticmethod
    def _quality(
        mask: np.ndarray,
        bounds: tuple[int, int, int, int],
        separation: float,
    ) -> tuple[float, list[str]]:
        image_height, image_width = mask.shape
        x_min, y_min, x_max, y_max = bounds
        coverage = (y_max - y_min + 1) / image_height
        subject_center = ((x_min + x_max) / 2) / image_width
        centered = max(0.0, 1 - abs(subject_center - 0.5) * 2.2)
        coverage_score = max(0.0, 1 - abs(coverage - 0.78) / 0.45)
        quality = float(np.clip(0.35 + 0.25 * centered + 0.25 * coverage_score + 0.15 * separation, 0.35, 0.90))

        warnings: list[str] = []
        if y_min <= image_height * 0.02 or y_max >= image_height * 0.98:
            warnings.append("The head or feet may be clipped; leave space around the whole body.")
        if abs(subject_center - 0.5) > 0.13:
            warnings.append("Stand closer to the center of the guide.")
        if separation < 0.35:
            warnings.append("Use a plain background that contrasts with the clothing.")
        if coverage < 0.55:
            warnings.append("Move closer while keeping the full body in frame.")
        if not warnings:
            warnings.append("Image framing passed the prototype quality checks.")
        return quality, warnings
