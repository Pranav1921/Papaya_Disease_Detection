import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ml_prediction_service.dart';

class OfflineCacheService {
  static const String _keyScanHistory = 'cached_scan_history';
  static const String _keyLastDistrict = 'cached_user_district';

  /// Saves a scan result to local offline storage
  static Future<void> saveScanResultOffline(MLPredictionResult result) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_keyScanHistory) ?? [];

    Map<String, dynamic> scanData = {
      'disease_id': result.diseaseInfo.id,
      'title_kannada': result.diseaseInfo.titleKannada,
      'severity_percent': result.severityPercentage,
      'total_price': result.diseaseInfo.totalPrice,
      'date': result.diagnosedAt,
    };

    history.insert(0, jsonEncode(scanData));
    // Keep last 10 scans offline
    if (history.length > 10) history = history.sublist(0, 10);

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
