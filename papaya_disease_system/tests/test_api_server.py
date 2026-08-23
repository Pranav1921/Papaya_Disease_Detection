import io
import json
import urllib.request
from unittest.mock import patch

import pytest
from PIL import Image
from fastapi.testclient import TestClient


def image_bytes(color, image_format="JPEG"):
    image = Image.new("RGB", (40, 40), color)
    buffer = io.BytesIO()
    image.save(buffer, format=image_format)
    return buffer.getvalue()


class FakeResponse:
    def __init__(self, payload):
        self.payload = payload

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        return False

    def read(self):
        return json.dumps(self.payload).encode("utf-8")


def test_calculate_haversine_zero_symmetry_and_known_distance(api_server):
    assert api_server.calculate_haversine(12.0, 75.0, 12.0, 75.0) == pytest.approx(0)

    forward = api_server.calculate_haversine(0, 0, 0, 1)
    reverse = api_server.calculate_haversine(0, 1, 0, 0)
    assert forward == pytest.approx(111.195, abs=0.1)
    assert forward == pytest.approx(reverse)


def test_is_leaf_image_heuristic_green_and_non_green_images(api_server):
    assert api_server.is_leaf_image_heuristic(image_bytes((128, 200, 20)))
    assert not api_server.is_leaf_image_heuristic(image_bytes((220, 20, 20)))
    assert not api_server.is_leaf_image_heuristic(image_bytes((20, 20, 220)))


def test_is_leaf_image_heuristic_fails_open_for_malformed_bytes(api_server):
    assert api_server.is_leaf_image_heuristic(b"not an image") is True


@pytest.mark.parametrize(
    ("answer", "expected"),
    [("YES", True), ("NO", False)],
)
def test_is_leaf_image_ai_uses_ai_answer(api_server, answer, expected, monkeypatch):
    monkeypatch.setattr(api_server, "_call_gemini_vision", lambda *args, **kwargs: answer)
    assert api_server.is_leaf_image_ai(b"image") is expected


def test_is_leaf_image_ai_calls_heuristic_when_ai_is_unavailable(api_server, monkeypatch):
    monkeypatch.setattr(api_server, "_call_gemini_vision", lambda *args, **kwargs: "")
    fallback = patch.object(api_server, "is_leaf_image_heuristic", return_value=True)
    with fallback as heuristic:
        assert api_server.is_leaf_image_ai(b"image") is True
    heuristic.assert_called_once_with(b"image")


@pytest.mark.parametrize(
    ("answer", "expected"),
    [("YES", "YES"), ("NO", "NO"), ("", "FAIL")],
)
def test_is_papaya_leaf_ai_statuses(api_server, answer, expected, monkeypatch):
    monkeypatch.setattr(api_server, "_call_gemini_vision", lambda *args, **kwargs: answer)
    assert api_server.is_papaya_leaf_ai(b"image") == expected


def test_call_gemini_vision_openrouter_branch(api_server, monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "sk-or-test-key")
    response = FakeResponse({"choices": [{"message": {"content": " yes "}}]})

    with patch.object(urllib.request, "urlopen", return_value=response) as urlopen:
        result = api_server._call_gemini_vision(b"image", "prompt", max_tokens=7)

    assert result == "YES"
    request = urlopen.call_args.args[0]
    assert request.full_url == "https://openrouter.ai/api/v1/chat/completions"
    assert request.get_header("Authorization") == "Bearer sk-or-test-key"


def test_call_gemini_vision_direct_gemini_branch(api_server, monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "google-test-key")
    response = FakeResponse(
        {"candidates": [{"content": {"parts": [{"text": " no "}]}}]}
    )

    with patch.object(urllib.request, "urlopen", return_value=response) as urlopen:
        result = api_server._call_gemini_vision(b"image", "prompt")

    assert result == "NO"
    request = urlopen.call_args.args[0]
    assert request.full_url.startswith(
        "https://generativelanguage.googleapis.com/v1beta/models/"
    )
    assert "key=google-test-key" in request.full_url


def test_call_gemini_vision_returns_empty_string_on_exception(api_server, monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "google-test-key")
    with patch.object(urllib.request, "urlopen", side_effect=RuntimeError("offline")):
        assert api_server._call_gemini_vision(b"image", "prompt") == ""


def test_remove_background_disabled_returns_original_bytes(api_server, monkeypatch):
    original = b"original"
    monkeypatch.setattr(api_server, "ENABLE_BG_REMOVAL", False)
    assert api_server.remove_background(original) == original


def test_remove_background_returns_original_when_rembg_is_unavailable(
    api_server, monkeypatch
):
    original = b"original"
    monkeypatch.setattr(api_server, "ENABLE_BG_REMOVAL", True)
    real_import = __import__

    def import_without_rembg(name, *args, **kwargs):
        if name == "rembg":
            raise ImportError("rembg unavailable")
        return real_import(name, *args, **kwargs)

    monkeypatch.setattr("builtins.__import__", import_without_rembg)
    assert api_server.remove_background(original) == original


def test_remove_background_returns_original_when_rembg_raises(api_server, monkeypatch):
    original = b"original"

    class BrokenRembg:
        @staticmethod
        def new_session(name):
            raise RuntimeError("model unavailable")

        @staticmethod
        def remove(*args, **kwargs):
            raise AssertionError("remove should not be reached")

    monkeypatch.setattr(api_server, "ENABLE_BG_REMOVAL", True)
    monkeypatch.setitem(__import__("sys").modules, "rembg", BrokenRembg)
    assert api_server.remove_background(original) == original


def test_predict_image_rejects_non_leaf(api_server, monkeypatch):
    monkeypatch.setattr(api_server, "remove_background", lambda image: image)
    monkeypatch.setattr(api_server, "is_leaf_image_ai", lambda image: False)
    assert api_server.predict_image(b"image") == ("__not_a_leaf__", 0.0)


def test_predict_image_returns_none_without_tensorflow_model(api_server, monkeypatch):
    monkeypatch.setattr(api_server, "remove_background", lambda image: image)
    monkeypatch.setattr(api_server, "is_leaf_image_ai", lambda image: True)
    monkeypatch.setattr(api_server, "is_papaya_leaf_ai", lambda image: "YES")
    monkeypatch.setattr(api_server, "HAS_TF", False)
    monkeypatch.setattr(api_server, "model", None)
    assert api_server.predict_image(b"image") is None


@pytest.fixture
def api_client(api_server):
    return TestClient(api_server.app)


def test_health_endpoint_payload(api_client):
    response = api_client.get("/")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "online"
    assert payload["mode"] == "FastAPI Engine"
    assert payload["service"] == "Papaya Disease Detection API"
    assert payload["version"] == "1.0.0"
    assert payload["model_loaded"] is False
    assert payload["endpoints"] == [
        "/api/v1/predict",
        "/api/v1/shops",
        "/api/v1/news",
    ]


def test_shops_endpoint_sorts_and_filters_by_distance(api_client, api_server):
    response = api_client.get("/api/v1/shops")
    assert response.status_code == 200
    payload = response.json()
    assert payload["total_shops"] == len(payload["shops"])
    assert payload["total_shops"] > 0
    distances = [shop["distance_km"] for shop in payload["shops"]]
    assert distances == sorted(distances)
    assert all("distance_km" in shop for shop in payload["shops"])

    filtered = api_client.get("/api/v1/shops", params={"radius_km": 1})
    assert filtered.status_code == 200
    assert filtered.json()["total_shops"] < len(api_server.MASTER_SHOPS)


def test_news_endpoint_returns_all_five_news_entries(api_client):
    response = api_client.get("/api/v1/news")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "success"
    assert len(payload["news"]) == 5


@pytest.mark.parametrize(
    ("disease_key", "severity_range", "statuses"),
    [
        ("powdery_mildew", (72.4, 80.4), {"Moderate", "Severe"}),
        ("ringspot_virus", (84.5, 92.5), {"Critical"}),
        ("leaf_curl", (61.0, 69.0), {"Severe"}),
        ("healthy", (0.0, 0.0), {"Healthy"}),
    ],
)
def test_predict_endpoint_disease_mappings(
    api_client, disease_key, severity_range, statuses
):
    response = api_client.post("/api/v1/predict", data={"disease_key": disease_key})
    assert response.status_code == 200
    payload = response.json()
    assert payload["disease_key"] == disease_key
    assert severity_range[0] <= payload["severity"] <= severity_range[1]
    assert payload["status"] in statuses


def test_predict_endpoint_rejects_background(api_client):
    payload = api_client.post(
        "/api/v1/predict", data={"disease_key": "background"}
    ).json()
    assert payload["status"] == "Rejected"
    assert payload["rejection_reason"]


def test_predict_endpoint_reports_unknown_class(api_client):
    payload = api_client.post(
        "/api/v1/predict", data={"disease_key": "unknown"}
    ).json()
    assert payload["status"] == "Unknown"
    assert payload["rejection_reason"] == "unknown_class"
