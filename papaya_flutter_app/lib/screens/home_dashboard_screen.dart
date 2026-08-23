import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/offline_cache_service.dart';
import '../services/ml_prediction_service.dart';
import 'scan_screen.dart';
import 'diagnosis_result_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final String language;
  const HomeDashboardScreen({super.key, this.language = 'kn'});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late String _activeLanguage;
  List<Map<String, dynamic>> _scanHistory = [];

  @override
  void initState() {
    super.initState();
    _activeLanguage = widget.language;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await OfflineCacheService.getOfflineScanHistory();
    if (mounted) {
      setState(() {
        _scanHistory = history;
      });
    }
  }

  void _viewFullResult(Map<String, dynamic> item) {
    // Reconstruct the MLPredictionResult from history map
    final String diseaseId = item['disease_id'] ?? 'healthy';
    final diseaseInfo = MLPredictionService.getDiseaseByKey(diseaseId);

    final result = MLPredictionResult(
      diseaseInfo: diseaseInfo,
      severityPercentage: (item['severity_percent'] as num?)?.toDouble() ?? 0.0,
      confidenceScore: (item['confidence'] as num?)?.toDouble() ?? 90.0,
      leafHealthStatus: item['status'] ?? 'Moderate',
      diagnosedAt: item['date'] ?? '',
      heatmapCoordinates: List<String>.from(item['heatmap_coords'] ?? []),
      imagePath: item['image_path'],
      isOffline: true, // Mark as history/offline
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiagnosisResultScreen(
          result: result,
          language: _activeLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isKn = _activeLanguage == 'kn';
    bool isHi = _activeLanguage == 'hi';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isKn ? 'ಪಪ್ಪಾಯಿ ರೋಗ ಪತ್ತೆ' : (isHi ? 'पपीता रोग पहचान' : 'Papaya Disease Detection'),
          style: GoogleFonts.notoSansKannada(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          DropdownButton<String>(
            value: _activeLanguage,
            dropdownColor: AppTheme.forestGreen,
            icon: const Icon(Icons.language, color: Colors.white),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            items: const [
              DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _activeLanguage = val);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          // Large Scan Button in the center/top
          Center(
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScanScreen(language: _activeLanguage)),
                );
                _loadHistory(); // Refresh history when coming back
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.forestGreen.withOpacity(0.4),
                      blurRadius: 25,
                      spreadRadius: 5,
                    )
                  ],
                  border: Border.all(color: AppTheme.leafGold, width: 4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded, color: AppTheme.leafGold, size: 60),
                    const SizedBox(height: 10),
                    Text(
                      isKn ? 'ಎಲೆ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ' : (isHi ? 'पत्ती स्कैन करें' : 'Scan Leaf'),
                      style: GoogleFonts.notoSansKannada(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // History Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: AppTheme.forestGreen),
                const SizedBox(width: 8),
                Text(
                  isKn ? 'ಹಿಂದಿನ ತಪಾಸಣೆಗಳು' : (isHi ? 'पुराना इतिहास' : 'Recent History'),
                  style: GoogleFonts.notoSansKannada(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.forestGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // History List
          Expanded(
            child: _scanHistory.isEmpty
                ? Center(
                    child: Text(
                      isKn ? 'ಯಾವುದೇ ಇತಿಹಾಸವಿಲ್ಲ' : (isHi ? 'कोई इतिहास नहीं' : 'No history found'),
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _scanHistory.length,
                    itemBuilder: (context, index) {
                      final item = _scanHistory[index];
                      return _buildHistoryCard(item, _activeLanguage);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, String lang) {
    bool isKn = lang == 'kn';
    bool isHi = lang == 'hi';

    // Severity mapping
    double severity = (item['severity_percent'] as num?)?.toDouble() ?? 0.0;
    Color severityColor = severity > 80 ? Colors.red : (severity > 50 ? Colors.orange : AppTheme.emeraldGreen);

    final String? imagePath = item['image_path'];
    final bool hasImage = imagePath != null && File(imagePath).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => _viewFullResult(item),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 50,
            height: 50,
            color: severityColor.withOpacity(0.1),
            child: hasImage
              ? Image.file(File(imagePath), fit: BoxFit.cover)
              : Icon(Icons.eco_rounded, color: severityColor),
          ),
        ),
        title: Text(
          item['title_kannada'] ?? 'Disease Name',
          style: GoogleFonts.notoSansKannada(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['date'] ?? '', style: const TextStyle(fontSize: 11)),
            Text(
              '${isKn ? 'ತೀವ್ರತೆ' : (isHi ? 'तीव्रता' : 'Severity')}: ${severity.toInt()}%',
              style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }
}
