import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/news_service.dart';
import '../models/agri_news.dart';
import 'scan_screen.dart';
import 'blog_detail_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final String language;
  const HomeDashboardScreen({super.key, this.language = 'kn'});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late List<AgriNews> _newsList;
  late String _activeLanguage;
  Timer? _newsTimer;

  @override
  void initState() {
    super.initState();
    _activeLanguage = widget.language;
    _newsList = NewsService.getOfflineNews();
    _loadDynamicNews();

    // Set up timer to refresh news every 60 seconds
    _newsTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _loadDynamicNews();
    });
  }

  @override
  void dispose() {
    _newsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDynamicNews() async {
    final news = await NewsService.fetchDynamicNews();
    if (mounted) {
      setState(() {
        _newsList = news;
      });
    }
  }

  void _showDatasetInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📊 AI Model & Dataset Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Training Dataset Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Global Data: 3,000+ images from PlantVillage Papaya subsets.'),
              Text('• Local Data: 1,500+ images collected from farms in South India (Karnataka/TN) for high accuracy in local lighting.'),
              Text('• Augmentation: 20,000+ synthetic samples created to handle shadows, blur, and low-quality cameras.'),
              SizedBox(height: 12),
              Text('Algorithm:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('MobileNetV2 CNN architecture with transfer learning, optimized for mobile deployment.'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
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
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showDatasetInfo(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeatherRiskCard(_activeLanguage),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.newspaper_rounded, color: AppTheme.forestGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isKn ? 'ಕೃಷಿ ಸುದ್ದಿಗಳು' : (isHi ? 'कृषि समाचार' : 'Agriculture News'),
                            style: GoogleFonts.notoSansKannada(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.forestGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sync, size: 12, color: AppTheme.emeraldGreen),
                        const SizedBox(width: 4),
                        Text(
                          isKn ? 'ನವೀಕರಣ' : (isHi ? 'अपडेट' : 'SYNC'),
                          style: const TextStyle(
                            color: AppTheme.emeraldGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _newsList.length,
                itemBuilder: (context, index) {
                  final news = _newsList[index];
                  return _buildNewsCard(news, _activeLanguage);
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ScanScreen(language: _activeLanguage)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.forestGreen,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: AppTheme.forestGreen.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: const BorderSide(color: AppTheme.leafGold, width: 2),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.leafGold,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppTheme.darkMoss, size: 24),
                ),
                const SizedBox(width: 14),
                Text(
                  isKn ? 'ಎಲೆ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ' : (isHi ? 'पत्ती स्कैन करें' : 'Scan Leaf Now'),
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
    );
  }

  Widget _buildWeatherRiskCard(String lang) {
    bool isKn = lang == 'kn';
    bool isHi = lang == 'hi';
    final weatherNews = _newsList.firstWhere((n) => n.id == 'news_2', orElse: () => _newsList[1]);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogDetailScreen(
              news: weatherNews,
              language: lang,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppTheme.warningGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.amberWarning.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isKn ? '🌦️ ಹವಾಮಾನ ಎಚ್ಚರಿಕೆ' : (isHi ? '🌦️ मौसम रोग चेतावनी' : '🌦️ Weather Disease Alert'),
                          style: GoogleFonts.notoSansKannada(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isKn ? 'ತೇವಾಂಶ 88%' : (isHi ? 'आर्द्रता 88%' : 'Humidity 88%'),
                          style: const TextStyle(
                            color: AppTheme.amberWarning,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isKn
                        ? 'ಕರಾವಳಿ ಭಾಗದಲ್ಲಿ ತೇವಾಂಶ ಹೆಚ್ಚಿರುವುದರಿಂದ ಬೂದಿ ರೋಗ ಹರಡುವ ಸಾಧ್ಯತೆ ಹೆಚ್ಚು. ಗಿಡಗಳಿಗೆ ಸೂಕ್ತ ಮುಂಜಾಗ್ರತೆ ವಹಿಸಿ.'
                        : (isHi
                            ? 'तटीय क्षेत्रों में उच्च आर्द्रता के कारण पाउडर फफूंद (बूदी रोग) फैलने की अधिक संभावना है। पौधों की उचित देखभाल करें।'
                            : 'High humidity detected in coastal areas. Increased risk of Powdery Mildew fungal infection. Take preventive actions.'),
                    style: GoogleFonts.notoSansKannada(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(AgriNews news, String lang) {
    bool isKn = lang == 'kn';
    bool isHi = lang == 'hi';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlogDetailScreen(
                news: news,
                language: lang,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    news.iconEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news.getCategory(lang),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.emeraldGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (news.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.leafGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isKn ? 'ಮುಖ್ಯ ಸುದ್ದಿ' : (isHi ? 'मुख्य समाचार' : 'HOT'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkMoss,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                news.getTitle(lang),
                style: GoogleFonts.notoSansKannada(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forestGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                news.getSummary(lang),
                style: GoogleFonts.notoSansKannada(
                  fontSize: 13,
                  color: AppTheme.textDark.withOpacity(0.85),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isKn
                        ? 'ಮೂಲ: ${news.getSource(lang)}'
                        : (isHi ? 'स्रोत: ${news.getSource(lang)}' : 'Source: ${news.getSource(lang)}'),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                  ),
                  Row(
                    children: [
                      Text(
                        isKn ? 'ಓದಿ' : (isHi ? 'पढ़ें' : 'Read'),
                        style: const TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.emeraldGreen, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGovtSubsidyBanner(String lang) {
    bool isKn = lang == 'kn';
    bool isHi = lang == 'hi';
    final subsidyNews = _newsList.firstWhere((n) => n.id == 'news_1', orElse: () => _newsList[0]);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogDetailScreen(
              news: subsidyNews,
              language: lang,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.lightSage,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.emeraldGreen, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance, color: AppTheme.forestGreen, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isKn ? '💡 ಸರ್ಕಾರಿ ಸಬ್ಸಿಡಿ ಮಾಹಿತಿ (RSK)' : (isHi ? '💡 सरकारी सब्सिडी जानकारी (RSK)' : '💡 Govt Subsidy Info (RSK)'),
                    style: GoogleFonts.notoSansKannada(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.forestGreen,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isKn
                        ? 'ನಿಮ್ಮ ತಾಲೂಕಿನ ರೈತ ಸಂಪರ್ಕ ಕೇಂದ್ರದಲ್ಲಿ (RSK) ಸುಡೋಮೊನಾಸ್ ಮತ್ತು ಜೈವಿಕ ಗೊಬ್ಬರಗಳಿಗೆ 50% ಸಬ್ಸಿಡಿ ಲಭ್ಯವಿದೆ.'
                        : (isHi
                            ? 'आपके तालुका के रायता संपर्क केंद्र (RSK) में स्यूडोमोनास और जैविक खादों पर 50% सब्सिडी उपलब्ध है।'
                            : 'Get 50% subsidy on bio-fertilizers & Pseudomonas at your Taluk Raitha Samparka Kendra (RSK).'),
                    style: GoogleFonts.notoSansKannada(fontSize: 12, color: AppTheme.textDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
