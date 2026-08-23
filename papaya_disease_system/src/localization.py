# src/localization.py
import io
import logging

from gtts import gTTS

logger = logging.getLogger(__name__)

# Interface string translations
UI_TEXT = {
    "en": {
        "title": "🌱 Papaya Disease Detection & Treatment System",
        "upload": "Upload a Papaya Leaf Image...",
        "confidence": "Prediction Confidence",
        "treatment": "💊 Treatment / Control",
        "fertilizer": "🧪 Fertilizer Guidance",
        "prevention": "🛡️ Preventive Care",
        "audio_label": "🔊 Listen to Action Plan",
    },
    "kn": {
        "title": "🌱 ಪಪ್ಪಾಯಿ ರೋಗ ಪತ್ತೆ ಮತ್ತು ಚಿಕಿತ್ಸಾ ವ್ಯವಸ್ಥೆ",
        "upload": "ಪಪ್ಪಾಯಿ ಎಲೆಯ ಚಿತ್ರವನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಿ...",
        "confidence": "ಊಹೆಯ ವಿಶ್ವಾಸಾರ್ಹತೆ",
        "treatment": "💊 ಚಿಕಿತ್ಸೆ / ನಿಯಂತ್ರಣ",
        "fertilizer": "🧪 ರಸಗೊಬ್ಬರ ಮಾರ್ಗದರ್ಶನ",
        "prevention": "🛡️ ತಡೆಗಟ್ಟುವ ಕ್ರಮಗಳು",
        "audio_label": "🔊 ಚಿಕಿತ್ಸಾ ವಿವರಣೆಯನ್ನು ಕೇಳಿ",
    }
}

def get_string(lang, key):
    return UI_TEXT.get(lang, UI_TEXT["en"]).get(key, "")

def generate_audio_guide(text_to_speak, lang="en"):
    """
    Generates an in-memory MP3 audio stream using Google Text-to-Speech.
    Returns a bytes buffer ready for Streamlit audio playback.
    """
    try:
        # Use Kannada ('kn') voice if selected, otherwise default to English
        tts_lang = 'kn' if lang == 'kn' else 'en'
        tts = gTTS(text=text_to_speak, lang=tts_lang, slow=False)
        audio_buffer = io.BytesIO()
        tts.write_to_fp(audio_buffer)
        audio_buffer.seek(0)
        return audio_buffer
    except Exception:
        logger.warning("TTS generation failed; the audio guide will be unavailable.", exc_info=True)
        return None