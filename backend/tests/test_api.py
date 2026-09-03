import base64
from datetime import UTC, datetime
from io import BytesIO

from fastapi.testclient import TestClient
from PIL import Image, ImageDraw

from app.main import app, fashion_news_service, weather_style_service
from app.schemas import (
    FashionNewsPost,
    FashionNewsResponse,
    FashionWeatherTip,
    NewsSourceStatus,
    WeatherCurrent,
    WeatherDay,
    WeatherHomeResponse,
)


client = TestClient(app)


def test_health() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_fashion_news_feed_supports_style_categories(monkeypatch) -> None:
    async def fake_fetch(category: str, limit: int) -> FashionNewsResponse:
        return FashionNewsResponse(
            category=category,
            fetched_at=datetime.now(UTC),
            items=[
                FashionNewsPost(
                    id="story-1",
                    title="A Y2K fashion update",
                    summary="A category-specific story.",
                    url="https://example.com/story",
                    publisher="Example Fashion",
                    platform="Google News",
                    category=category,
                    published_at=datetime.now(UTC),
                    like_count=120,
                    comment_count=14,
                )
            ],
            sources=[
                NewsSourceStatus(
                    name="Google News",
                    connected=True,
                    note="Live RSS stories",
                )
            ],
        )

    monkeypatch.setattr(fashion_news_service, "fetch", fake_fetch)
    response = client.get("/v1/news/feed?category=y2k&limit=8")

    assert response.status_code == 200
    body = response.json()
    assert body["category"] == "y2k"
    assert body["items"][0]["category"] == "y2k"
    assert body["sources"][0]["connected"] is True


def test_fashion_news_feed_rejects_unknown_category() -> None:
    response = client.get("/v1/news/feed?category=unknown")
    assert response.status_code == 422


def test_home_weather_returns_current_tomorrow_and_fashion(monkeypatch) -> None:
    async def fake_weather(
        city: str,
        size_label: str | None = None,
        color_season: str | None = None,
    ) -> WeatherHomeResponse:
        return WeatherHomeResponse(
            location=city,
            region="Metro Manila",
            country="Philippines",
            timezone="Asia/Manila",
            updated_at=datetime.now(UTC),
            current=WeatherCurrent(
                temperature_c=30,
                apparent_temperature_c=35,
                humidity_percent=74,
                wind_kmh=12,
                weather_code=2,
                condition="Partly cloudy",
                is_day=True,
            ),
            tomorrow=WeatherDay(
                date="2026-09-04",
                temperature_max_c=31,
                temperature_min_c=25,
                apparent_temperature_max_c=36,
                precipitation_probability=58,
                uv_index_max=7.2,
                weather_code=80,
                condition="Rain showers",
            ),
            fashion=[
                FashionWeatherTip(
                    kind="outfit",
                    title="Airy warm-weather layers",
                    reason=f"Forecast matched for size {size_label} and {color_season}.",
                )
            ],
            source="Open-Meteo forecast",
        )

    monkeypatch.setattr(weather_style_service, "fetch", fake_weather)
    response = client.get(
        "/v1/weather/home?city=Manila&size_label=M&color_season=Autumn"
    )

    assert response.status_code == 200
    body = response.json()
    assert body["current"]["condition"] == "Partly cloudy"
    assert body["tomorrow"]["condition"] == "Rain showers"
    assert body["fashion"][0]["kind"] == "outfit"


def test_local_development_origin_is_allowed() -> None:
    response = client.options(
        "/v1/size/recommend",
        headers={
            "Origin": "http://127.0.0.1:8765",
            "Access-Control-Request-Method": "POST",
        },
    )
    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://127.0.0.1:8765"


def test_size_recommendation_is_bounded() -> None:
    response = client.post(
        "/v1/size/recommend",
        json={
            "measurements": {
                "height": 165,
                "neck": 35,
                "shoulder": 40,
                "chest": 94,
                "underbust": 85,
                "waist": 77,
                "high_hip": 96,
                "hip": 103,
                "sleeve": 59,
                "wrist": 16,
                "inseam": 76,
            },
            "fit_preference": "regular",
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["recommended_size"] in {"2XS", "XS", "S", "M", "L", "XL", "2XL", "3XL", "4XL"}
    assert 0 <= body["confidence"] <= 1
    assert len(body["alternatives"]) == 3


def test_invalid_measurement_is_rejected() -> None:
    response = client.post(
        "/v1/size/recommend",
        json={"measurements": {"height": 20, "chest": 94, "waist": 77, "hip": 103}},
    )
    assert response.status_code == 422


def _silhouette_photo() -> str:
    image = Image.new("RGB", (240, 480), "#EEE7DF")
    draw = ImageDraw.Draw(image)
    draw.ellipse((96, 35, 144, 83), fill="#2B2523")
    draw.rectangle((108, 75, 132, 100), fill="#2B2523")
    draw.polygon([(82, 90), (158, 90), (146, 285), (94, 285)], fill="#2B2523")
    draw.rectangle((87, 105, 102, 285), fill="#2B2523")
    draw.rectangle((138, 105, 153, 285), fill="#2B2523")
    draw.rectangle((97, 280, 116, 445), fill="#2B2523")
    draw.rectangle((124, 280, 143, 445), fill="#2B2523")
    buffer = BytesIO()
    image.save(buffer, format="JPEG", quality=90)
    return base64.b64encode(buffer.getvalue()).decode("ascii")


def test_body_scan_returns_all_measurement_labels() -> None:
    response = client.post(
        "/v1/body-scan/analyze",
        json={
            "image_base64": _silhouette_photo(),
            "reference_height_cm": 165,
            "consent_confirmed": True,
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert set(body["measurements"]) == {
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
    }
    assert body["measurements"]["height"] == 165
    assert body["person_detected"] is True
    assert 0 <= body["person_confidence"] <= 1
    assert "height" in body["displayable_measurements"]
    assert 0 <= body["scan_confidence"] <= 1
    assert "Unvalidated measurement preview" in body["validation_status"]


def test_body_scan_rejects_photo_without_person() -> None:
    image = Image.new("RGB", (240, 480), "#EEE7DF")
    buffer = BytesIO()
    image.save(buffer, format="JPEG", quality=90)
    response = client.post(
        "/v1/body-scan/analyze",
        json={
            "image_base64": base64.b64encode(buffer.getvalue()).decode("ascii"),
            "reference_height_cm": 165,
            "consent_confirmed": True,
        },
    )

    assert response.status_code == 422
    assert "No person was detected" in response.json()["detail"]


def test_body_scan_rejects_tall_non_human_object() -> None:
    image = Image.new("RGB", (240, 480), "#EEE7DF")
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((82, 35, 158, 445), radius=8, fill="#2B2523")
    buffer = BytesIO()
    image.save(buffer, format="JPEG", quality=90)
    response = client.post(
        "/v1/body-scan/analyze",
        json={
            "image_base64": base64.b64encode(buffer.getvalue()).decode("ascii"),
            "reference_height_cm": 165,
            "consent_confirmed": True,
        },
    )

    assert response.status_code == 422
    assert "full-body person" in response.json()["detail"]


def test_body_scan_measurements_are_deterministic() -> None:
    payload = {
        "image_base64": _silhouette_photo(),
        "reference_height_cm": 165,
        "consent_confirmed": True,
    }

    first = client.post("/v1/body-scan/analyze", json=payload)
    second = client.post("/v1/body-scan/analyze", json=payload)

    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json()["measurements"] == second.json()["measurements"]


def test_body_scan_requires_photo_consent() -> None:
    response = client.post(
        "/v1/body-scan/analyze",
        json={
            "image_base64": _silhouette_photo(),
            "reference_height_cm": 165,
            "consent_confirmed": False,
        },
    )
    assert response.status_code == 422


def test_profile_photo_returns_accessories_and_color_direction() -> None:
    response = client.post(
        "/v1/profile/analyze",
        json={
            "image_base64": _silhouette_photo(),
            "consent_confirmed": True,
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["color_season"] in {"Spring", "Summer", "Autumn", "Winter"}
    assert len(body["accessories"]) == 4
    assert len(body["palette"]) >= 4
    assert 0 <= body["confidence"] <= 1
    assert "not identity" in body["disclaimer"]


def test_profile_photo_requires_consent() -> None:
    response = client.post(
        "/v1/profile/analyze",
        json={
            "image_base64": _silhouette_photo(),
            "consent_confirmed": False,
        },
    )
    assert response.status_code == 422


def test_color_analysis_returns_palette() -> None:
    response = client.post(
        "/v1/color/analyze",
        json={"skin_hex": "#C98F70", "hair_hex": "#3D2A22", "eye_hex": "#65483A"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["season"] in {"Spring", "Summer", "Autumn", "Winter"}
    assert len(body["palette"]) >= 4


def test_tropical_season_uses_wet_dry_cycle() -> None:
    response = client.post(
        "/v1/style/recommend",
        json={
            "climate": "tropical",
            "hemisphere": "northern",
            "month": 8,
            "occasion": "work",
            "style": "classic",
            "color_season": "Autumn",
            "size_label": "M",
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["current_season"] == "Wet"
    assert body["pieces"]
    assert body["palette"]
