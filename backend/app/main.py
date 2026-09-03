from __future__ import annotations

from typing import Literal

import httpx
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from .ai_engine import StyloristaEngine
from .appearance_analysis import AppearanceAnalysisError, AppearanceAnalyzer
from .body_scan import BodyScanError, BodyScanEstimator
from .news_feed import FashionNewsService
from .schemas import (
    BodyScanRequest,
    BodyScanResponse,
    AppearanceAnalysisRequest,
    AppearanceAnalysisResponse,
    ColorRequest,
    ColorResponse,
    FashionNewsResponse,
    SizeRequest,
    SizeResponse,
    StyleRequest,
    StyleResponse,
    WeatherHomeResponse,
)
from .weather_service import WeatherServiceError, WeatherStyleService


app = FastAPI(
    title="Stylorista-AI API",
    description="Privacy-first fashion fit, personal color and seasonal styling MVP.",
    version="1.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[],
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

engine = StyloristaEngine()
body_scan_estimator = BodyScanEstimator()
appearance_analyzer = AppearanceAnalyzer()
fashion_news_service = FashionNewsService()
weather_style_service = WeatherStyleService()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "stylorista-ai", "version": app.version}


@app.get("/v1/news/feed", response_model=FashionNewsResponse)
async def fashion_news_feed(
    category: Literal[
        "all",
        "y2k",
        "gothic",
        "alternative",
        "formal",
        "casual",
        "wedding",
        "streetwear",
        "vintage",
    ] = "all",
    limit: int = Query(default=16, ge=4, le=30),
) -> FashionNewsResponse:
    return await fashion_news_service.fetch(category=category, limit=limit)


@app.get("/v1/weather/home", response_model=WeatherHomeResponse)
async def home_weather(
    city: str = Query(default="Manila", min_length=2, max_length=100),
    size_label: str | None = Query(default=None, max_length=12),
    color_season: Literal["Spring", "Summer", "Autumn", "Winter"] | None = None,
) -> WeatherHomeResponse:
    try:
        return await weather_style_service.fetch(
            city=city,
            size_label=size_label,
            color_season=color_season,
        )
    except WeatherServiceError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
    except httpx.HTTPError as error:
        raise HTTPException(
            status_code=503,
            detail="Live weather is temporarily unavailable. Please try again.",
        ) from error


@app.post("/v1/size/recommend", response_model=SizeResponse)
def recommend_size(request: SizeRequest) -> SizeResponse:
    return engine.recommend_size(request)


@app.post("/v1/body-scan/analyze", response_model=BodyScanResponse)
def analyze_body_scan(request: BodyScanRequest) -> BodyScanResponse:
    try:
        return body_scan_estimator.analyze(request)
    except BodyScanError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error


@app.post("/v1/profile/analyze", response_model=AppearanceAnalysisResponse)
def analyze_profile_photo(
    request: AppearanceAnalysisRequest,
) -> AppearanceAnalysisResponse:
    try:
        return appearance_analyzer.analyze(request)
    except AppearanceAnalysisError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error


@app.post("/v1/color/analyze", response_model=ColorResponse)
def analyze_color(request: ColorRequest) -> ColorResponse:
    return engine.analyze_color(request)


@app.post("/v1/style/recommend", response_model=StyleResponse)
def recommend_style(request: StyleRequest) -> StyleResponse:
    return engine.recommend_style(request)
