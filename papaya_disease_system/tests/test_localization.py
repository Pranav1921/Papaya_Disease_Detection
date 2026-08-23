import io

import pytest

pytest.importorskip("gtts")

import localization


def test_get_string_translations_and_fallbacks():
    assert localization.get_string("en", "title").startswith("🌱 Papaya")
    assert localization.get_string("kn", "title").startswith("🌱 ಪಪ್ಪಾಯಿ")
    assert localization.get_string("unknown", "title") == localization.UI_TEXT["en"]["title"]
    assert localization.get_string("en", "unknown-key") == ""


def test_generate_audio_guide_returns_rewound_buffer_and_uses_kannada(monkeypatch):
    class FakeTTS:
        def __init__(self, **kwargs):
            self.kwargs = kwargs

        def write_to_fp(self, buffer):
            buffer.write(b"audio")

    instances = []

    def fake_tts(**kwargs):
        instance = FakeTTS(**kwargs)
        instances.append(instance)
        return instance

    monkeypatch.setattr(localization, "gTTS", fake_tts)
    audio = localization.generate_audio_guide("ಸಲಹೆ", lang="kn")

    assert isinstance(audio, io.BytesIO)
    assert audio.tell() == 0
    assert audio.read() == b"audio"
    assert instances[0].kwargs["lang"] == "kn"


def test_generate_audio_guide_returns_none_when_tts_raises(monkeypatch):
    def broken_tts(**kwargs):
        raise RuntimeError("tts unavailable")

    monkeypatch.setattr(localization, "gTTS", broken_tts)
    assert localization.generate_audio_guide("guide") is None
