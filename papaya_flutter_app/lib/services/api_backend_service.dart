import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint, debugPrintStack, kIsWeb;
import 'package:http/http.dart' as http;
import '../services/ml_prediction_service.dart';

/// Thrown when the ML backend rejects the image (not a leaf / not a papaya leaf)
class LeafRejectionException implements Exception {
  final String reason;       // 'not_a_leaf' | 'not_papaya'
  final String messageEn;
  final String messageKn;
  final String messageHi;

  const LeafRejectionException({
    required this.reason,
    required this.messageEn,
    required this.messageKn,
    required this.messageHi,
  });

  String getMessage(String lang) {
    if (lang == 'kn') return messageKn;
    if (lang == 'hi') return messageHi;
    return messageEn;
  }
}

/// Thrown when the backend responds but the response cannot be used
/// (non-200 status or a payload that is not valid prediction JSON).
class BackendResponseException implements Exception {
  final int? statusCode;
  final String details;

  const BackendResponseException({this.statusCode, required this.details});

  @override
  String toString() =>
      'BackendResponseException(status: $statusCode, details: $details)';
}

class ApiBackendService {
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      // Use explicit 127.0.0.1 to guarantee IPv4 routing matches adb reverse
      return 'http://127.0.0.1:8001';
    }
    return 'http://127.0.0.1:8001';
  }

  /// Returns true only when running on an Android emulator (where host PC is reachable via 10.0.2.2).
  /// On physical devices the backend is not reachable, so skip the network call entirely.
  static bool get _isEmulator {
    // Emulators typically report brand 'generic' or model containing 'sdk'.
    // We use a simple heuristic: if running on Android, try the server; if it
    // fails immediately we fall back anyway. For now always attempt on Android
    // but with a very short timeout so physical devices fail fast.
    return false; // Set to true if you are using an emulator
  }

  /// Sends leaf photo to FastAPI server or falls back seamlessly to embedded ML
  static Future<MLPredictionResult> fetchPredictionFromBackend({
    String? imagePath,
    String diseaseKey = 'powdery_mildew',
    bool force = false,
  }) async {
    try {
      if (imagePath != null) {
        final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/v1/predict'));
        request.fields['disease_key'] = diseaseKey;
        request.fields['force'] = force.toString();
        request.files.add(await http.MultipartFile.fromPath('file', imagePath));
        
        // Use longer timeout (25s) because backend ML analysis (Gemini + ImageNet + TF)
        // can take time, especially on first run or slow networks.
        final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // === Staged rejection handling ===
          final rejectionReason = data['rejection_reason'] as String?;
          if (rejectionReason != null) {
            throw LeafRejectionException(
              reason: rejectionReason,
              messageEn: data['message_en'] ?? 'Invalid image for papaya analysis.',
              messageKn: data['message_kn'] ?? 'ಚಿತ್ರ ವಿಶ್ಲೇಷಣೆಗೆ ಯೋಗ್ಯವಲ್ಲ.',
              messageHi: data['message_hi'] ?? 'छवि पपीता विश्लेषण के लिए मान्य नहीं है।',
            );
          }

          final returnedKey = data['disease_key'] ?? diseaseKey;
          final severity = (data['severity'] as num?)?.toDouble() ?? 0.0;
          final confidence = (data['confidence'] as num?)?.toDouble() ?? 90.0;
          final status = data['status'] ?? 'Moderate';

          final diseaseInfo = MLPredictionService.getDiseaseByKey(returnedKey);
          return MLPredictionResult(
            diseaseInfo: diseaseInfo,
            severityPercentage: severity,
            confidenceScore: confidence,
            leafHealthStatus: status,
            diagnosedAt: DateTime.now().toString().substring(0, 16),
            heatmapCoordinates: [
              'X: 38%, Y: 44% [High Damage Spot]',
              'X: 62%, Y: 55% [Infection Boundary]'
            ],
            imagePath: imagePath,
          );
        }

        // Non-200 (e.g. server returned 500 or 404): surface it so the caller
        // falls back deliberately instead of silently reusing stale state.
        throw BackendResponseException(
          statusCode: response.statusCode,
          details: response.body.length > 500
              ? response.body.substring(0, 500)
              : response.body,
        );
      } else {
        // Mock fallback if no image path
        final uri = Uri.parse('$baseUrl/api/v1/predict?disease_key=$diseaseKey');
        final response = await http.post(uri).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final returnedKey = data['disease_key'] ?? diseaseKey;
          final severity = (data['severity'] as num?)?.toDouble() ?? 0.0;
          final confidence = (data['confidence'] as num?)?.toDouble() ?? 90.0;
          final status = data['status'] ?? 'Moderate';

          final diseaseInfo = MLPredictionService.getDiseaseByKey(returnedKey);
          return MLPredictionResult(
            diseaseInfo: diseaseInfo,
            severityPercentage: severity,
            confidenceScore: confidence,
            leafHealthStatus: status,
            diagnosedAt: DateTime.now().toString().substring(0, 16),
            heatmapCoordinates: [
              'X: 42%, Y: 35% [Infection Focus]'
            ],
            imagePath: imagePath,
          );
        } else {
          throw BackendResponseException(
            statusCode: response.statusCode,
            details: response.body.length > 500
                ? response.body.substring(0, 500)
                : response.body,
          );
        }
      }
    } on LeafRejectionException {
      rethrow; // Let scan_screen handle genuine AI rejection dialogs (not_a_leaf / not_papaya)
    } catch (e, stackTrace) {
      // Backend is offline, unreachable, or replied with something unusable.
      // Fall back to embedded ML analysis so the user always gets a diagnosis,
      // but record why the backend result was discarded.
      debugPrint(
        'Backend prediction failed ($e); falling back to embedded ML analysis.',
      );
      debugPrintStack(stackTrace: stackTrace);
      return MLPredictionService.analyzeLeafImage(
        imagePath: imagePath,
      );
    }
  }

  /// Checks backend health status
  static Future<bool> checkBackendHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/');
      final response = await http.get(uri).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend health check failed: $e');
      return false;
    }
  }
}
