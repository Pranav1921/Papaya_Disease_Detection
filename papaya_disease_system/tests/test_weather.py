from unittest.mock import Mock

import weather


def test_get_coastal_weather_risk_simulates_without_api_key(monkeypatch):
    monkeypatch.setattr(weather.random, "randint", lambda low, high: 90)
    monkeypatch.setattr(weather.random, "uniform", lambda low, high: 28.0)

    result = weather.get_coastal_weather_risk(city="Puttur")

    assert set(result) == {"status", "advisory", "high_risk"}
    assert result["high_risk"] is True
    assert result["status"] == "HIGH FUNGAL RISK ⚠️"
    assert "Puttur" in result["advisory"]


def test_get_coastal_weather_risk_uses_api_response(monkeypatch):
    response = Mock()
    response.json.return_value = {"main": {"humidity": 50, "temp": 28}}
    get = Mock(return_value=response)
    monkeypatch.setattr(weather.requests, "get", get)

    result = weather.get_coastal_weather_risk(city="Udupi", api_key="key")

    assert result["high_risk"] is False
    assert result["status"] == "MODERATE RISK 🌤️"
    assert "Udupi" in result["advisory"]
    get.assert_called_once()


def test_get_coastal_weather_risk_falls_back_when_api_request_raises(monkeypatch):
    monkeypatch.setattr(
        weather.requests, "get", Mock(side_effect=RuntimeError("offline"))
    )

    result = weather.get_coastal_weather_risk(city="Mangaluru", api_key="key")

    assert result["high_risk"] is True
    assert result["status"] == "HIGH FUNGAL RISK ⚠️"
    assert "Mangaluru" in result["advisory"]
