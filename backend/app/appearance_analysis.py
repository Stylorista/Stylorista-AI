from __future__ import annotations

import base64
import binascii
from io import BytesIO

import numpy as np
from PIL import Image, ImageOps, UnidentifiedImageError

from .ai_engine import PALETTES
from .schemas import (
    AccessorySuggestion,
    AppearanceAnalysisRequest,
    AppearanceAnalysisResponse,
)


_ACCESSORIES = {
    "Spring": (
        ("Delicate gold hoops", "Warm shine brightens the colors nearest your face."),
        ("Ivory silk scarf", "A light warm neutral keeps the look fresh."),
        ("Caramel mini bag", "Soft golden brown grounds a bright palette."),
        ("Warm pearl hair clip", "Creamy pearl is gentler than stark white."),
    ),
    "Summer": (
        ("Silver drop earrings", "Cool, softly reflective metal suits a muted palette."),
        ("Dusty-blue scarf", "A softened blue adds color without hard contrast."),
        ("Dove-gray shoulder bag", "Cool gray works as an easy everyday neutral."),
        ("Rose-quartz pendant", "A diffused pink accent complements soft coloring."),
    ),
    "Autumn": (
        ("Antique-bronze earrings", "Rich warm metal echoes an earthy palette."),
        ("Tortoiseshell sunglasses", "Warm mottled contrast feels cohesive near the face."),
        ("Cognac leather belt", "A grounded brown links warm wardrobe colors."),
        ("Olive structured bag", "Muted green adds color while staying versatile."),
    ),
    "Winter": (
        ("Silver geometric earrings", "Crisp cool shine supports higher contrast."),
        ("Black structured bag", "A clear dark neutral keeps the outfit polished."),
        ("Jewel-tone scarf", "Saturated color creates a strong face-framing accent."),
        ("Crystal pendant", "Clean sparkle works well with a cool, clear palette."),
    ),
}


class AppearanceAnalysisError(ValueError):
    pass


class AppearanceAnalyzer:
    """Conservative color-direction analysis for accessory styling.

    This does not identify a person or infer ethnicity, health, or other
    sensitive traits. It samples visible color from a broad portrait region and
    returns aesthetic guidance with deliberately limited confidence.
    """

    def analyze(
        self, request: AppearanceAnalysisRequest
    ) -> AppearanceAnalysisResponse:
        image = self._decode_image(request.image_base64)
        array = self._prepare_image(image)
        lighting_quality, quality_warnings = self._lighting_quality(array)
        sample, coverage, contrast = self._sample_visible_tone(array)
        red, green, blue = (float(channel) for channel in sample)
        warmth = ((red - blue) + 0.2 * (red - green)) / 255
        brightness = (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255
        saturation = (max(red, green, blue) - min(red, green, blue)) / 255

        if abs(warmth) < 0.035:
            temperature = "neutral"
        else:
            temperature = "warm" if warmth > 0 else "cool"
        depth = "light" if brightness > 0.68 else "deep" if brightness < 0.38 else "medium"

        if temperature == "warm":
            season = "Spring" if brightness > 0.58 and saturation > 0.12 else "Autumn"
        elif temperature == "cool":
            season = "Summer" if brightness > 0.52 and contrast < 0.62 else "Winter"
        else:
            season = "Summer" if brightness > 0.60 else "Winter" if contrast > 0.58 else "Autumn"

        palette = PALETTES[season]
        confidence = float(
            np.clip(
                0.32
                + min(coverage, 0.18) * 1.25
                + min(contrast, 0.75) * 0.14
                + lighting_quality * 0.22,
                0.42,
                0.88,
            )
        )
        sampled_color = "#{:02X}{:02X}{:02X}".format(
            *(int(np.clip(channel, 0, 255)) for channel in sample)
        )

        return AppearanceAnalysisResponse(
            color_season=season,
            complexion_direction=f"{temperature.title()} · {depth} visual direction",
            sampled_color=sampled_color,
            confidence=round(confidence, 2),
            lighting_quality=round(lighting_quality, 2),
            quality_warnings=quality_warnings,
            palette=palette["palette"],
            metals=palette["metals"],
            accessories=[
                AccessorySuggestion(name=name, reason=reason)
                for name, reason in _ACCESSORIES[season]
            ],
            styling_notes=[
                f"Start with {palette['metals'][0]} near the face.",
                "Repeat one accessory color in the shoes, bag, or outer layer.",
                "For a steadier result, retake the photo in indirect daylight without a filter.",
            ],
            model_version="appearance-color-calibrated-demo-0.2.0",
            disclaimer=(
                "Prototype aesthetic guidance from visible photo color, not identity, ethnicity, "
                "health, or biometric analysis. Lighting, makeup, filters, background, and camera "
                "white balance can change the result. The API processes the image in memory and "
                "does not store it."
            ),
        )

    @staticmethod
    def _decode_image(value: str) -> Image.Image:
        encoded = value.split(",", 1)[-1] if value.startswith("data:") else value
        try:
            raw = base64.b64decode(encoded, validate=True)
        except (binascii.Error, ValueError) as error:
            raise AppearanceAnalysisError("The selected photo could not be decoded.") from error
        if len(raw) > 12 * 1024 * 1024:
            raise AppearanceAnalysisError("The photo is larger than the 12 MB limit.")
        try:
            return ImageOps.exif_transpose(Image.open(BytesIO(raw))).convert("RGB")
        except (UnidentifiedImageError, OSError) as error:
            raise AppearanceAnalysisError("Use a valid JPEG, PNG, or WebP photo.") from error

    @staticmethod
    def _prepare_image(image: Image.Image) -> np.ndarray:
        if image.width < 96 or image.height < 96:
            raise AppearanceAnalysisError("Choose a clearer portrait with more resolution.")
        scale = min(1.0, 512 / max(image.width, image.height))
        if scale < 1:
            image = image.resize(
                (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
                Image.Resampling.LANCZOS,
            )
        return np.asarray(image, dtype=np.float32)

    @staticmethod
    def _lighting_quality(image: np.ndarray) -> tuple[float, list[str]]:
        luminance = (
            image[:, :, 0] * 0.2126
            + image[:, :, 1] * 0.7152
            + image[:, :, 2] * 0.0722
        )
        mean_luminance = float(np.mean(luminance))
        dark_fraction = float(np.mean(luminance < 30))
        bright_fraction = float(np.mean(luminance > 245))

        if mean_luminance < 48:
            raise AppearanceAnalysisError(
                "The photo is too dark for reliable color analysis. Use bright, even "
                "indirect daylight and retake the photo without a filter."
            )
        if mean_luminance > 235 and bright_fraction > 0.78:
            raise AppearanceAnalysisError(
                "The photo is overexposed for reliable color analysis. Move away from "
                "harsh direct light and retake it without a filter."
            )

        exposure_score = max(0.0, 1 - abs(mean_luminance - 145) / 145)
        clipping_score = max(0.0, 1 - min(1.0, dark_fraction + bright_fraction))
        quality = float(np.clip(0.72 * exposure_score + 0.28 * clipping_score, 0, 1))
        warnings: list[str] = []
        if quality < 0.62:
            warnings.append(
                "Lighting may shift the sampled colors. Retake in bright, even indirect daylight."
            )
        if dark_fraction > 0.18:
            warnings.append("Reduce deep shadows across the face and visible skin.")
        if bright_fraction > 0.18:
            warnings.append("Avoid glare or washed-out highlights on the face.")
        if not warnings:
            warnings.append("Lighting passed the color-analysis exposure check.")
        return quality, warnings

    @staticmethod
    def _sample_visible_tone(image: np.ndarray) -> tuple[np.ndarray, float, float]:
        height, width, _ = image.shape
        region = image[
            round(height * 0.12) : round(height * 0.68),
            round(width * 0.20) : round(width * 0.80),
        ]
        red = region[:, :, 0]
        green = region[:, :, 1]
        blue = region[:, :, 2]

        # Broad YCbCr-style mask that works across a wide range of visible skin
        # colors. It is used only for color styling and not for face recognition.
        cb = 128 - 0.168736 * red - 0.331264 * green + 0.5 * blue
        cr = 128 + 0.5 * red - 0.418688 * green - 0.081312 * blue
        mask = (
            (red > 35)
            & (green > 20)
            & (blue > 12)
            & (cb > 72)
            & (cb < 142)
            & (cr > 126)
            & (cr < 184)
        )
        candidates = region[mask]
        coverage = float(candidates.shape[0] / max(region.shape[0] * region.shape[1], 1))
        minimum_candidates = max(120, round(region.shape[0] * region.shape[1] * 0.002))
        if candidates.shape[0] < minimum_candidates:
            raise AppearanceAnalysisError(
                "Not enough clear visible skin color was found. Face the camera in bright "
                "indirect daylight, remove color filters, and keep your face visible."
            )

        luminance = (
            0.2126 * candidates[:, 0]
            + 0.7152 * candidates[:, 1]
            + 0.0722 * candidates[:, 2]
        )
        lower, upper = np.percentile(luminance, (20, 80))
        balanced = candidates[(luminance >= lower) & (luminance <= upper)]
        sample = np.median(balanced if balanced.size else candidates, axis=0)
        contrast = float(np.clip(np.std(luminance) / 64, 0, 1))
        return sample, coverage, contrast
