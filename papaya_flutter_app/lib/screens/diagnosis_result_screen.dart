import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/localized_text.dart';
import '../widgets/language_dropdown.dart';
import '../services/ml_prediction_service.dart';
import '../services/shop_location_service.dart';
import '../services/pdf_prescription_service.dart';
import '../services/kannada_tts_service.dart';
import '../services/offline_cache_service.dart';
import '../models/disease_info.dart';
import '../models/agri_shop.dart';
import 'package:url_launcher/url_launcher.dart';

class DiagnosisResultScreen extends StatefulWidget {
  final MLPredictionResult result;
  final String language;

  const DiagnosisResultScreen({
    super.key,
    required this.result,
    this.language = 'kn',
  });

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

enum TtsState { playing, paused, stopped }

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> with SingleTickerProviderStateMixin {
  bool _showHeatmap = false;
  TtsState _ttsState = TtsState.stopped;
  late List<AgriShop> _nearestShops;
  late TabController _tabController;
  late String _activeLanguage;

  @override
  void initState() {
    super.initState();
    _activeLanguage = widget.language;
    _tabController = TabController(length: 4, vsync: this);
    _nearestShops = ShopLocationService.getShopsWithinRadius(maxDistanceKm: 100.0);
    OfflineCacheService.saveScanResultOffline(widget.result);
  }

  @override
  void dispose() {
    _tabController.dispose();
    KannadaTtsService.stopSpeech();
    super.dispose();
  }

  void _playTts() async {
    setState(() => _ttsState = TtsState.playing);
    await KannadaTtsService.speakDiagnosisReport(widget.result, language: _activeLanguage);
    if (mounted) setState(() => _ttsState = TtsState.stopped);
  }

  void _pauseTts() async {
    await KannadaTtsService.pauseSpeech();
    setState(() => _ttsState = TtsState.paused);
  }

  void _stopTts() async {
    await KannadaTtsService.stopSpeech();
    setState(() => _ttsState = TtsState.stopped);
  }

  void _exportPdfPrescription() async {
    final topShop = _nearestShops.isNotEmpty ? _nearestShops.first : null;
    await PdfPrescriptionService.printOrSharePdf(
      result: widget.result,
      shopName: topShop != null ? topShop.getName(_activeLanguage) : 'Agricultural Information Center',
      shopPhone: topShop != null ? topShop.phone : '+91 8251 230455',
    );
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchCaller(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isKn = _activeLanguage == 'kn';
    bool isHi = _activeLanguage == 'hi';
    DiseaseInfo disease = widget.result.diseaseInfo;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            pickLocalized(_activeLanguage, kn: 'ಪಪ್ಪಾಯಿ ರೋಗ ವಿಶ್ಲೇಷಣೆ', hi: 'पपीता रोग विश्लेषण', en: 'Papaya Disease Analysis'),
            style: GoogleFonts.notoSansKannada(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          LanguageDropdown(
            value: _activeLanguage,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            onChanged: (val) {
              if (val != null) {
                setState(() => _activeLanguage = val);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildLeafImageSection(isKn, isHi),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSeverityPercentCard(disease, _activeLanguage),
                  const SizedBox(height: 16),
                  _buildTtsControlPanel(isKn, isHi),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _exportPdfPrescription,
                      icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                      label: Text(
                        pickLocalized(_activeLanguage, kn: '📄 PDF ವರದಿ ಪಡೆಯಿರಿ', hi: '📄 PDF रिपोर्ट प्राप्त करें', en: '📄 Get PDF Report'),
                        style: GoogleFonts.notoSansKannada(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTreatmentPlanTabs(disease, _activeLanguage),
                  const SizedBox(height: 20),
                  _buildMedicinesAndPriceCard(disease, _activeLanguage),
                  const SizedBox(height: 24),
                  _buildNearestShopsSection(_activeLanguage),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTtsControlPanel(bool isKn, bool isHi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.forestGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pickLocalized(_activeLanguage, kn: 'ಧ್ವನಿ ಮಾರ್ಗದರ್ಶಿ', hi: 'ऑडियो गाइड', en: 'Voice Guide'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTtsCircleButton(
                icon: Icons.play_arrow,
                onPressed: _ttsState == TtsState.playing ? null : _playTts,
                label: pickLocalized(_activeLanguage, kn: 'ಪ್ಲೇ', hi: 'PLAY', en: 'PLAY'),
                isActive: _ttsState == TtsState.playing,
              ),
              _buildTtsCircleButton(
                icon: Icons.pause,
                onPressed: _ttsState == TtsState.playing ? _pauseTts : null,
                label: pickLocalized(_activeLanguage, kn: 'ಪಾಸ್', hi: 'PAUSE', en: 'PAUSE'),
                isActive: _ttsState == TtsState.paused,
              ),
              _buildTtsCircleButton(
                icon: Icons.stop,
                onPressed: _ttsState == TtsState.stopped ? null : _stopTts,
                label: pickLocalized(_activeLanguage, kn: 'ನಿಲ್ಲಿಸಿ', hi: 'STOP', en: 'STOP'),
                isActive: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTtsCircleButton({required IconData icon, required VoidCallback? onPressed, required String label, required bool isActive}) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: isActive ? AppTheme.leafGold : Colors.white24,
          radius: 24,
          child: IconButton(
            icon: Icon(icon, color: isActive ? AppTheme.darkMoss : Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLeafImageSection(bool isKn, bool isHi) {
    final String? path = widget.result.imagePath;
    final bool hasRealImage = path != null && File(path).existsSync();
    final bool isHealthy = widget.result.diseaseInfo.id == 'healthy';

    return Container(
      width: double.infinity,
      height: 240,
      color: AppTheme.darkMoss,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: hasRealImage && !_showHeatmap
                ? Image.file(File(path), fit: BoxFit.contain)
                : _buildLeafPlaceholder(isKn, isHi, isHealthy),
          ),
          if (_showHeatmap && !isHealthy)
            Positioned.fill(
              child: CustomPaint(
                painter: HeatmapPainter(coordinates: widget.result.heatmapCoordinates),
              ),
            ),
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  _buildToggleButton(pickLocalized(_activeLanguage, kn: 'ಫೋಟೋ', hi: 'PHOTO', en: 'PHOTO'), !_showHeatmap, () => setState(() => _showHeatmap = false)),
                  _buildToggleButton(pickLocalized(_activeLanguage, kn: 'HEATMAP', hi: 'HEATMAP', en: 'HEATMAP'), _showHeatmap, () => setState(() => _showHeatmap = true)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.emeraldGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLeafPlaceholder(bool isKn, bool isHi, bool isHealthy) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.eco_rounded, size: 60, color: isHealthy ? AppTheme.emeraldGreen : AppTheme.leafGold),
        const SizedBox(height: 12),
        Text(pickLocalized(_activeLanguage, kn: '🖼️ ವಿಶ್ಲೇಷಣೆ', hi: '🖼️ Analysis', en: '🖼️ Analysis'), style: const TextStyle(color: Colors.white60, fontSize: 13)),
      ],
    );
  }

  Widget _buildSeverityPercentCard(DiseaseInfo disease, String lang) {
    bool isHealthy = disease.id == 'healthy';
    Color themeColor = isHealthy ? AppTheme.emeraldGreen : AppTheme.amberWarning;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickLocalized(lang, kn: 'ಸಂಭವನೀಯ ರೋಗ:', hi: 'संभावित बीमारी:', en: 'Possible Diagnosis:'),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        disease.getTitle(lang),
                        style: GoogleFonts.notoSansKannada(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.forestGreen),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pickLocalized(lang, kn: 'ತೀವ್ರತೆ ಮಟ್ಟ: ${disease.getSeverityLevel(lang)}', hi: 'Severity: ${disease.getSeverityLevel(lang)}', en: 'Severity: ${disease.getSeverityLevel(lang)}'),
                        style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(width: 64, height: 64, child: CircularProgressIndicator(value: widget.result.severityPercentage / 100.0, strokeWidth: 8, backgroundColor: AppTheme.softGrey, color: themeColor)),
                    Text('${widget.result.severityPercentage.toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: themeColor)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              pickLocalized(lang, kn: 'ಸೂಚನೆ: ಈ ಕೆಳಗಿನ ಲಕ್ಷಣಗಳು ನಿಮ್ಮ ಬೆಳೆಯಲ್ಲಿ ಇರಬಹುದು:', hi: 'System Suggestion: These patterns might be present:', en: 'System Suggestion: These patterns might be present:'),
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            Text(disease.getDescription(lang), style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentPlanTabs(DiseaseInfo disease, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📋 Suggested Treatment Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.forestGreen)),
        const SizedBox(height: 10),
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.forestGreen,
          indicatorColor: AppTheme.emeraldGreen,
          tabs: const [Tab(text: '🧪 Chemical'), Tab(text: '🌿 Organic'), Tab(text: '🌱 Fertilizer'), Tab(text: '⏳ Safety')],
        ),
        SizedBox(
          height: 160,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTabCard(disease.getChemicalTreatment(lang), Icons.science),
              _buildTabCard(disease.getOrganicTreatment(lang), Icons.eco),
              _buildTabCard(disease.getFertilizerSchedule(lang), Icons.grass),
              _buildTabCard(disease.getSafetyInterval(lang), Icons.timer),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabCard(String content, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.emeraldGreen, size: 24),
            const SizedBox(width: 12),
            Expanded(child: SingleChildScrollView(child: Text(content, style: const TextStyle(fontSize: 13, height: 1.4)))),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinesAndPriceCard(DiseaseInfo disease, String lang) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.emeraldGreen, width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🛒 Prescribed Medicines', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.forestGreen)),
            const Divider(height: 20),
            ...disease.prescribedMedicines.map((med) => ListTile(
              leading: const Icon(Icons.medication_liquid_rounded, color: AppTheme.emeraldGreen),
              title: Text(med.getName(lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(med.getDosage(lang), style: const TextStyle(fontSize: 11)),
              trailing: Text('₹${med.price.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.forestGreen)),
            )),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.forestGreen, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Cost (Approx)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('₹${disease.totalPrice.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.leafGold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearestShopsSection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📍 Nearest Agri Shops', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.forestGreen)),
        const SizedBox(height: 12),
        ..._nearestShops.map((shop) => Card(
          child: ListTile(
            onTap: () => _launchMaps(shop.latitude, shop.longitude),
            leading: CircleAvatar(backgroundColor: AppTheme.emeraldGreen, child: const Icon(Icons.shop, color: Colors.white)),
            title: Text(shop.getName(lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${shop.distanceKm.toStringAsFixed(1)} KM away', style: const TextStyle(fontSize: 11)),
            trailing: IconButton(icon: const Icon(Icons.phone, color: AppTheme.forestGreen), onPressed: () => _launchCaller(shop.phone)),
          ),
        )),
      ],
    );
  }
}

class HeatmapPainter extends CustomPainter {
  final List<String> coordinates;
  HeatmapPainter({required this.coordinates});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    final innerPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    for (var coord in coordinates) {
      // Parse "X: 42%, Y: 35% [Infection Focus]"
      try {
        final xMatch = RegExp(r'X: (\d+)%').firstMatch(coord);
        final yMatch = RegExp(r'Y: (\d+)%').firstMatch(coord);

        if (xMatch != null && yMatch != null) {
          double xPct = double.parse(xMatch.group(1)!) / 100.0;
          double yPct = double.parse(yMatch.group(1)!) / 100.0;

          Offset center = Offset(size.width * xPct, size.height * yPct);
          canvas.drawCircle(center, 30, paint);
          canvas.drawCircle(center, 10, innerPaint);
        }
      } catch (e) {
        debugPrint("Heatmap parse error: $e");
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
