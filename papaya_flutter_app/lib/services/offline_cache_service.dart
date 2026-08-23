import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ml_prediction_service.dart';

class OfflineCacheService {
  static const String _keyScanHistory = 'cached_scan_history';
  static const String _keyLastDistrict = 'cached_user_district';

  /// Saves a scan result to local offline storage and copies the image to a permanent location
  static Future<void> saveScanResultOffline(MLPredictionResult result) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_keyScanHistory) ?? [];

    String? persistentPath;

    // Copy image to permanent storage if it exists
    if (result.imagePath != null && File(result.imagePath!).existsSync()) {
      try {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File localImage = await File(result.imagePath!).copy('${appDocDir.path}/$fileName');
        persistentPath = localImage.path;
      } catch (e) {
        print("Error saving image to permanent storage: $e");
        persistentPath = result.imagePath; // Fallback to original path
      }
    }

    Map<String, dynamic> scanData = {
      'disease_id': result.diseaseInfo.id,
      'title_kannada': result.diseaseInfo.titleKannada,
      'severity_percent': result.severityPercentage,
      'confidence': result.confidenceScore,
      'status': result.leafHealthStatus,
      'total_price': result.diseaseInfo.totalPrice,
      'date': result.diagnosedAt,
      'image_path': persistentPath,
      'heatmap_coords': result.heatmapCoordinates,
    };

    history.insert(0, jsonEncode(scanData));
    // Keep last 10 scans offline
    if (history.length > 10) {
      // Try to delete the image file of the removed item to save space
      try {
        final lastItem = jsonDecode(history.last);
        if (lastItem['image_path'] != null) {
          final oldFile = File(lastItem['image_path']);
          if (oldFile.existsSync()) await oldFile.delete();
        }
      } catch (_) {}
      history = history.sublist(0, 10);
    }

    await prefs.setStringList(_keyScanHistory, history);
  }

  /// Retrieves offline scan history
  static Future<List<Map<String, dynamic>>> getOfflineScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_keyScanHistory) ?? [];

    return history.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  /// Saves auto-detected user district
  static Future<void> saveUserDistrict(String district) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastDistrict, district);
  }
}
