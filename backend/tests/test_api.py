from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


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
