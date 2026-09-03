from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, field_validator


class Measurements(BaseModel):
    height: float = Field(ge=120, le=230, description="Height in centimetres")
    neck: float | None = Field(default=None, ge=20, le=70)
    shoulder: float | None = Field(default=None, ge=25, le=75)
    chest: float = Field(ge=55, le=190)
    underbust: float | None = Field(default=None, ge=50, le=170)
    waist: float = Field(ge=45, le=190)
    high_hip: float | None = Field(default=None, ge=55, le=200)
    hip: float = Field(ge=60, le=210)
    sleeve: float | None = Field(default=None, ge=35, le=90)
    wrist: float | None = Field(default=None, ge=10, le=35)
    inseam: float | None = Field(default=None, ge=45, le=110)


class SizeRequest(BaseModel):
    measurements: Measurements
    fit_preference: Literal["close", "regular", "relaxed"] = "regular"


class SizeAlternative(BaseModel):
    label: str
    probability: float


class SizeResponse(BaseModel):
    recommended_size: str
    confidence: float
    alternatives: list[SizeAlternative]
    fit_notes: list[str]
    model_version: str
    disclaimer: str


class BodyScanRequest(BaseModel):
    image_base64: str = Field(min_length=32, max_length=18_000_000)
    reference_height_cm: float = Field(ge=120, le=230)
    consent_confirmed: bool

    @field_validator("consent_confirmed")
    @classmethod
    def require_consent(cls, value: bool) -> bool:
        if not value:
            raise ValueError("Photo analysis requires explicit consent")
        return value


class BodyScanResponse(BaseModel):
    measurements: Measurements
    scan_confidence: float = Field(ge=0, le=1)
    image_quality: float = Field(ge=0, le=1)
    measurement_confidence: dict[str, float]
    quality_warnings: list[str]
    model_version: str
    validation_status: str
    disclaimer: str


class ColorRequest(BaseModel):
    skin_hex: str
    hair_hex: str
    eye_hex: str

    @field_validator("skin_hex", "hair_hex", "eye_hex")
    @classmethod
    def validate_hex(cls, value: str) -> str:
        normalized = value.strip().lstrip("#").upper()
        if len(normalized) != 6 or any(c not in "0123456789ABCDEF" for c in normalized):
            raise ValueError("Use a six-character hexadecimal color such as C98F70")
        return f"#{normalized}"


class ColorResponse(BaseModel):
    season: str
    confidence: float
    description: str
    palette: list[str]
    neutrals: list[str]
    metals: list[str]
    guidance: list[str]
    model_version: str
    disclaimer: str


class StyleRequest(BaseModel):
    climate: Literal["tropical", "temperate", "cold", "arid"] = "tropical"
    hemisphere: Literal["northern", "southern"] = "northern"
    month: int = Field(ge=1, le=12)
    occasion: Literal["everyday", "work", "event", "travel"] = "everyday"
    style: Literal["minimal", "classic", "street", "romantic"] = "minimal"
    color_season: Literal["Spring", "Summer", "Autumn", "Winter"] = "Autumn"
    size_label: str | None = None


class StyleResponse(BaseModel):
    current_season: str
    title: str
    summary: str
    pieces: list[str]
    fabrics: list[str]
    palette: list[str]
    styling_notes: list[str]
    model_version: str
