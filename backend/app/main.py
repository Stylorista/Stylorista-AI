from __future__ import annotations

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from .ai_engine import StyloristaEngine
from .body_scan import BodyScanError, BodyScanEstimator
from .schemas import (
    BodyScanRequest,
    BodyScanResponse,
    ColorRequest,
    ColorResponse,
    SizeRequest,
    SizeResponse,
    StyleRequest,
    StyleResponse,
)


app = FastAPI(
    title="Stylorista-AI API",
    description="Privacy-first fashion fit, personal color and seasonal styling MVP.",
    version="0.1.0",
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


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "stylorista-ai", "version": app.version}


@app.post("/v1/size/recommend", response_model=SizeResponse)
def recommend_size(request: SizeRequest) -> SizeResponse:
    return engine.recommend_size(request)


@app.post("/v1/body-scan/analyze", response_model=BodyScanResponse)
def analyze_body_scan(request: BodyScanRequest) -> BodyScanResponse:
    try:
        return body_scan_estimator.analyze(request)
    except BodyScanError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error


@app.post("/v1/color/analyze", response_model=ColorResponse)
def analyze_color(request: ColorRequest) -> ColorResponse:
    return engine.analyze_color(request)


@app.post("/v1/style/recommend", response_model=StyleResponse)
def recommend_style(request: StyleRequest) -> StyleResponse:
    return engine.recommend_style(request)
