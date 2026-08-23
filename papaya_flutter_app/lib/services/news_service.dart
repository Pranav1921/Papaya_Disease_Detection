import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, debugPrintStack;
import 'package:http/http.dart' as http;
import '../models/agri_news.dart';
import 'api_backend_service.dart';

class NewsService {
  static final List<AgriNews> _newsList = [
    const AgriNews(
      id: 'news_1',
      titleKannada: 'ಪಪ್ಪಾಯಿ ಬೀಜ ಹಾಗೂ ಜೈವಿಕ ಗೊಬ್ಬರಕ್ಕೆ 50% ಸರ್ಕಾರಿ ಸಬ್ಸಿಡಿ ಲಭ್ಯ!',
      titleEnglish: '50% Govt Subsidy on Papaya Seeds & Bio-fertilizers at RSK',
      titleHindi: 'पपीता बीज और जैविक खाद पर 50% सरकारी सब्सिडी उपलब्ध!',
      categoryKannada: '🌾 ಸರ್ಕಾರಿ ಯೋಜನೆ',
      categoryEnglish: '🌾 Govt Scheme',
      categoryHindi: '🌾 सरकारी योजना',
      summaryKannada: 'ನಿಮ್ಮ ತಾಲೂಕಿನ ರೈತ ಸಂಪರ್ಕ ಕೇಂದ್ರದಲ್ಲಿ (RSK) ಸುಡೋಮೊನಾಸ್ ಮತ್ತು ಟ್ರೈಕೋಡರ್ಮಾ ಜೈವಿಕ ಗೊಬ್ಬರಗಳಿಗೆ 50% ರಿಯಾಯಿತಿ ನೀಡಲಾಗುತ್ತಿದೆ.',
      summaryEnglish: 'Get a 50% discount on Pseudomonas and Trichoderma bio-fertilizers at your local Raitha Samparka Kendra (RSK).',
      summaryHindi: 'आपके तालुक के रायता संपर्क केंद्र (RSK) में स्यूडोमोनास और ट्राइकोडेर्मा जैविक खादों पर 50% की छूट दी जा रही है।',
      dateKannada: 'ಇಂದು, 23 ಜುಲೈ 2026',
      dateEnglish: 'Today, 23 July 2026',
      dateHindi: 'आज, 23 जुलाई 2026',
      iconEmoji: '🏛️',
      sourceKannada: 'ಕರ್ನಾಟಕ ಕೃಷಿ ಇಲಾಖೆ',
      sourceEnglish: 'Karnataka Agri Dept',
      sourceHindi: 'कर्नाटक कृषि विभाग',
      isFeatured: true,
    ),
    const AgriNews(
      id: 'news_2',
      titleKannada: 'ಕರಾವಳಿ ಮತ್ತು ಮಲೆನಾಡು ಭಾಗದಲ್ಲಿ ಪಪ್ಪಾಯಿ ಬೂದಿ ರೋಗದ ಮುನ್ನೆಚ್ಚರಿಕೆ!',
      titleEnglish: 'High Humidity Fungal Alert for Coastal & Malnad Papaya Farmers',
      titleHindi: 'तटीय और मलनाड क्षेत्रों में पपीते के पाउडर फफूंद रोग की चेतावनी!',
      categoryKannada: '🌦️ ಹವಾಮಾನ ರೋಗ ಎಚ್ಚರಿಕೆ',
      categoryEnglish: '🌦️ Weather Alert',
      categoryHindi: '🌦️ मौसम रोग चेतावनी',
      summaryKannada: 'ಮಂಗಳೂರು, ಉಡುಪಿ, ಪುತ್ತೂರು ಭಾಗಗಳಲ್ಲಿ ತೇವಾಂಶ 85% ಕ್ಕಿಂತ ಹೆಚ್ಚಿದ್ದು ಬೂದಿ ರೋಗ ಹರಡುವ ಸಾಧ್ಯತೆ ಇದೆ. ಕಾಂಟಾಫ್ 1ml ಸಿಂಪಡಿಸಿ.',
      summaryEnglish: 'Humidity is above 85% in Mangaluru, Udupi, and Puttur, leading to high Powdery Mildew risk. Spray 1ml Contaf.',
      summaryHindi: 'मंगलूरु, उडुपी, पुत्तूर क्षेत्रों में आर्द्रता 85% से अधिक होने के कारण रोग फैलने की संभावना है। 1ml कोंटाफ का छिड़काव करें।',
      dateKannada: 'ನಿನ್ನೆ',
      dateEnglish: 'Yesterday',
      dateHindi: 'कल',
      iconEmoji: '⚠️',
      sourceKannada: 'ಕೃಷಿ ಹವಾಮಾನ ಕೇಂದ್ರ, ಮಂಡ್ಯ',
      sourceEnglish: 'Agri Weather Center, Mandya',
      sourceHindi: 'कृषि मौसम केंद्र, मांड्या',
      isFeatured: true,
    ),
    const AgriNews(
      id: 'news_3',
      titleKannada: 'ಮಾರುಕಟ್ಟೆಯಲ್ಲಿ ಉತ್ತಮ ದರ್ಜೆಯ ಪಪ್ಪಾಯಿ ಹಣ್ಣಿಗೆ ಕೆ.ಜಿ ಗೆ ₹28 - ₹34 ಬೆಲೆ',
      titleEnglish: 'Papaya Market Price Update: ₹28 - ₹34 per kg in APMC',
      titleHindi: 'बाजार में अच्छी गुणवत्ता वाले पपीते की कीमत ₹28 - ₹34 प्रति किलोग्राम',
      categoryKannada: '💰 ಮಾರುಕಟ್ಟೆ ದರ',
      categoryEnglish: '💰 Market Price',
      categoryHindi: '💰 बाजार भाव',
      summaryKannada: 'ಬೆಂಗಳೂರು, ಮೈಸೂರು ಮತ್ತು ಪುತ್ತೂರು APMC ಮಾರುಕಟ್ಟೆಯಲ್ಲಿ ರೆಡ್ ಲೇಡಿ (Red Lady) ತಳಿಯ ಪಪ್ಪಾಯಿಗೆ ಭಾರಿ ಬೇಡಿಕೆ ಬಂದಿದೆ.',
      summaryEnglish: 'Red Lady papaya breed has high demand in Bengaluru, Mysuru, and Puttur APMC markets.',
      summaryHindi: 'बेंगलुरु, मैसूर और पुत्तूर APMC बाजार में रेड लेडी (Red Lady) पपीते की किस्म की भारी मांग है।',
      dateKannada: '22 ಜುಲೈ 2026',
      dateEnglish: '22 July 2026',
      dateHindi: '22 जुलाई 2026',
      iconEmoji: '📈',
      sourceKannada: 'APMC ಮಾರುಕಟ್ಟೆ ವರದಿ',
      sourceEnglish: 'APMC Market Watch',
      sourceHindi: 'APMC मार्केट वॉच',
      isFeatured: false,
    ),
    const AgriNews(
      id: 'news_4',
      titleKannada: 'ಹೇನು ಮತ್ತು ಬಿಳಿ ನೊಣ ನಿಯಂತ್ರಣಕ್ಕೆ ಹಳದಿ ಅಂಟಿನ ಬಲೆಗಳನ್ನು ಬಳಸಿ',
      titleEnglish: 'Use Yellow Sticky Traps to Stop Ringspot & Leaf Curl Vectors',
      titleHindi: 'रिंगस्पॉट और पत्ता मरोड़ वाहकों को रोकने के लिए पीले कार्ड का उपयोग करें',
      categoryKannada: '💡 ಕೃಷಿ ಸಲಹೆ',
      categoryEnglish: '💡 Agri Advisory',
      categoryHindi: '💡 कृषि सलाह',
      summaryKannada: 'ವೈರಸ್ ರೋಗಗಳು ಹರಡದಂತೆ ತಡೆಯಲು ಎಕರೆಗೆ 10 ಹಳದಿ ಅಂಟಿನ ಬಲೆಗಳನ್ನು ಕಟ್ಟುವುದರಿಂದ ಕೀಟನಾಶಕ ಸಿಂಪರಣೆ ವೆಚ್ಚ ಶೇ 40% ಕಡಿಮೆಯಾಗುತ್ತದೆ.',
      summaryEnglish: 'Installing 10 yellow sticky traps per acre reduces pesticide spraying costs by 40% while stopping virus spread.',
      summaryHindi: 'प्रति एकड़ 10 पीले चिपचिपे कार्ड लगाने से virus के फैलाव को रोकने के साथ-साथ कीटनाशक छिड़काव की लागत 40% तक कम हो जाती है।',
      dateKannada: '20 ಜುಲೈ 2026',
      dateEnglish: '20 July 2026',
      dateHindi: '20 जुलाई 2026',
      iconEmoji: '🌿',
      sourceKannada: 'ಕೃಷಿ ವಿಜ್ಞಾನ ಕೇಂದ್ರ (KVK)',
      sourceEnglish: 'Agri Science Center (KVK)',
      sourceHindi: 'कृषि विज्ञान केंद्र (KVK)',
      isFeatured: false,
    ),
  ];

  static List<AgriNews> getOfflineNews() => List.unmodifiable(_newsList);

  static Future<List<AgriNews>> fetchDynamicNews() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiBackendService.baseUrl}/api/v1/news'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        // Decode as UTF-8 explicitly to prevent local Unicode distortion for Kannada/Hindi
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success' && data['news'] != null) {
          final List<dynamic> jsonList = data['news'];
          return jsonList.map((item) {
            return AgriNews(
              id: item['id'] ?? '',
              titleKannada: item['titleKannada'] ?? '',
              titleEnglish: item['titleEnglish'] ?? '',
              titleHindi: item['titleHindi'] ?? '',
              categoryKannada: item['categoryKannada'] ?? '',
              categoryEnglish: item['categoryEnglish'] ?? '',
              categoryHindi: item['categoryHindi'] ?? '',
              summaryKannada: item['summaryKannada'] ?? '',
              summaryEnglish: item['summaryEnglish'] ?? '',
              summaryHindi: item['summaryHindi'] ?? '',
              dateKannada: item['dateKannada'] ?? '',
              dateEnglish: item['dateEnglish'] ?? '',
              dateHindi: item['dateHindi'] ?? '',
              iconEmoji: item['iconEmoji'] ?? '📰',
              sourceKannada: item['sourceKannada'] ?? '',
              sourceEnglish: item['sourceEnglish'] ?? '',
              sourceHindi: item['sourceHindi'] ?? '',
              isFeatured: item['isFeatured'] ?? false,
            );
          }).toList();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching dynamic news ($e); serving bundled news.');
      debugPrintStack(stackTrace: stackTrace);
    }
    return _newsList; // Fallback to local offline cache
  }
}
