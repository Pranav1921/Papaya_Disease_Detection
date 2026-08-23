import 'package:flutter/foundation.dart' show debugPrint, debugPrintStack;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/ml_prediction_service.dart';

class KannadaTtsService {
  static final FlutterTts _flutterTts = FlutterTts();

  /// Configures the TTS engine. Returns false when the engine could not be
  /// configured (e.g. the language pack is missing), so callers can tell the
  /// user instead of silently playing nothing.
  static Future<bool> _initTts(String lang) async {
    try {
      if (lang == 'kn') {
        await _flutterTts.setLanguage("kn-IN");
      } else if (lang == 'hi') {
        await _flutterTts.setLanguage("hi-IN");
      } else {
        await _flutterTts.setLanguage("en-US");
      }
      await _flutterTts.setSpeechRate(0.45); // Slower speech for farmers clarity
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      return true;
    } catch (e, stackTrace) {
      debugPrint('Text-to-speech initialisation failed for "$lang": $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Speaks full diagnosis report in Kannada, English, or Hindi aloud
  /// Returns false when the report could not be spoken.
  static Future<bool> speakDiagnosisReport(MLPredictionResult result, {String language = 'kn'}) async {
    if (!await _initTts(language)) return false;

    final disease = result.diseaseInfo;
    final speechText = StringBuffer();

    if (language == 'kn') {
      speechText.write('ನಮಸ್ಕಾರ ರೈತರೇ. ');
      speechText.write('ನಿಮ್ಮ ಪಪ್ಪಾಯಿ ಎಲೆಯ ವಿಶ್ಲೇಷಣೆ ಹೀಗಿದೆ. ');
      speechText.write('ಈ ಎಲೆಯಲ್ಲಿ ${disease.titleKannada} ಕಂಡುಬಂದಿರುವ ಸಾಧ್ಯತೆ ಇದೆ. ');
      speechText.write('ಇದರ ತೀವ್ರತೆ ಸುಮಾರು ${result.severityPercentage} ಪ್ರತಿಶತ ಇರಬಹುದು. ');

      if (disease.id != 'healthy') {
        speechText.write('ನಾವು ಸೂಚಿಸುವ ಚಿಕಿತ್ಸೆ: ${disease.chemicalTreatmentKannada}. ');
        speechText.write('ಅಂದಾಜು ಬೆಲೆ ರೂಪಾಯಿ ${disease.totalPrice.toStringAsFixed(0)}. ');
        speechText.write('ಹೆಚ್ಚಿನ ಮಾಹಿತಿಗಾಗಿ ಹತ್ತಿರದ ರೈತ ಸಂಪರ್ಕ ಕೇಂದ್ರಕ್ಕೆ ಭೇಟಿ ನೀಡಿ.');
      } else {
        speechText.write('ನಿಮ್ಮ ಪಪ್ಪಾಯಿ ಗಿಡ ಆರೋಗ್ಯವಾಗಿದೆ ಎಂದು ತೋರುತ್ತಿದೆ. ಧನ್ಯವಾದಗಳು.');
      }
    } else if (language == 'hi') {
      speechText.write('नमस्ते किसान भाइयों। ');
      speechText.write('पपीते की पत्ती का विश्लेषण पूरा हो गया है। ');
      speechText.write('संभावना है कि यह ${disease.titleHindi} है। ');
      speechText.write('इसका स्तर ${result.severityPercentage} प्रतिशत हो सकता है। ');

      if (disease.id != 'healthy') {
        speechText.write('अनुशंसित उपचार: ${disease.chemicalTreatmentHindi}. ');
        speechText.write('अनुमानित लागत ${disease.totalPrice.toStringAsFixed(0)} रुपये है। ');
      } else {
        speechText.write('आपकी फसल स्वस्थ लग रही है।');
      }
    } else {
      speechText.write('Hello farmer. ');
      speechText.write('Analysis complete. ');
      speechText.write('This might be ${disease.titleEnglish}. ');
      speechText.write('Severity is estimated at ${result.severityPercentage} percent. ');

      if (disease.id != 'healthy') {
        speechText.write('Suggested treatment: ${disease.chemicalTreatmentEnglish}. ');
        speechText.write('Estimated cost is ${disease.totalPrice.toStringAsFixed(0)} Rupees. ');
      } else {
        speechText.write('The crop appears to be healthy.');
      }
    }

    return _speak(speechText.toString());
  }

  /// Returns false when the text could not be spoken.
  static Future<bool> speakText(String text, String language) async {
    if (!await _initTts(language)) return false;
    return _speak(text);
  }

  static Future<bool> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
      return true;
    } catch (e, stackTrace) {
      debugPrint('Text-to-speech playback failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Future<void> pauseSpeech() async {
    await _flutterTts.pause();
  }

  static Future<void> resumeSpeech() async {
    // Some engines handle resume differently, speak again or just pause/resume
    // For many engines, speak with the same text is needed if pause isn't natively supported well.
    // However, FlutterTts has pause/resume on some platforms.
  }

  static Future<void> stopSpeech() async {
    await _flutterTts.stop();
  }
}
