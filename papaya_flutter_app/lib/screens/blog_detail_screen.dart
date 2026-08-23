import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/agri_news.dart';
import '../theme/app_theme.dart';
import '../services/kannada_tts_service.dart';

class BlogDetailScreen extends StatefulWidget {
  final AgriNews news;
  final String language;

  const BlogDetailScreen({
    super.key,
    required this.news,
    required this.language,
  });

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

enum TtsState { playing, paused, stopped }

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  TtsState _ttsState = TtsState.stopped;

  @override
  void dispose() {
    KannadaTtsService.stopSpeech();
    super.dispose();
  }

  String _getFullBlogContent() {
    final isKn = widget.language == 'kn';
    final isHi = widget.language == 'hi';

    if (widget.news.id == 'news_1') {
      if (isKn) {
        return "ಪಪ್ಪಾಯಿ ಬೆಳೆಗಾರರನ್ನು ಪ್ರೋತ್ಸಾಹಿಸಲು ಹೊಸ ಯೋಜನೆಯನ್ನು ಜಾರಿಗೆ ತಂದಿದೆ. ಇದರ ಅಡಿಯಲ್ಲಿ ಬೀಜಗಳು ಮತ್ತು ಪ್ರಮುಖ ಜೈವಿಕ ಗೊಬ್ಬರಗಳಾದ ಸುಡೋಮೊನಾಸ್ (Pseudomonas) ಮತ್ತು ಟ್ರೈಕೋಡರ್ಮಾ (Trichoderma) ಗಳಿಗೆ ಶೇಕಡಾ ೫೦ ರಷ್ಟು ಸಹಾಯಧನ ನೀಡಲಾಗುತ್ತಿದೆ.\n\n"
            "ರೈತರು ತಮ್ಮ ಆಧಾರ್ ಕಾರ್ಡ್ ಮತ್ತು ಜಮೀನಿನ ದಾಖಲೆಗಳೊಂದಿಗೆ ಹತ್ತಿರದ ಮಾಹಿತಿ ಕೇಂದ್ರಕ್ಕೆ ಭೇಟಿ ನೀಡಿ ಈ ಸೌಲಭ್ಯವನ್ನು ಪಡೆಯಬಹುದು. ಇದರಿಂದ ಸಸ್ಯಗಳ ಬೆಳವಣಿಗೆ ಉತ್ತಮಗೊಳ್ಳುವುದಲ್ಲದೆ, ಬೇರು ಕೊಳೆ ರೋಗ ಮತ್ತು ಇತರ ಶಿಲೀಂಧ್ರ ರೋಗಗಳ ನಿಯಂತ್ರಣಕ್ಕೆ ಸಹಕಾರಿಯಾಗಲಿದೆ.";
      } else if (isHi) {
        return "पपीता उत्पादकों को प्रोत्साहित करने के लिए एक नई योजना शुरू की गई है। इसके तहत पपीते के बीज और प्रमुख जैव उर्वरकों जैसे स्यूडोमोनास और ट्राइकोडेर्मा पर 50% की सब्सिडी दी जा रही है।\n\n"
            "किसान अपने आधार कार्ड और भूमि दस्तावेजों के साथ नजदीकी केंद्र पर जाकर इस योजना का लाभ उठा सकते हैं। यह जैविक खाद पौधों के स्वास्थ्य में सुधार करने और जड़ सड़न तथा अन्य फंगल बीमारियों को रोकने में मदद करती है।";
      } else {
        return "A new subsidy scheme has been introduced to support papaya farmers. Under this initiative, a 50% direct subsidy is being provided on high-quality papaya seeds and essential bio-fertilizers, including Pseudomonas and Trichoderma.\n\n"
            "To apply, farmers need to present their Aadhaar Card along with land ownership records at their nearest information center. Bio-fertilizers are crucial for improving crop immunity, enhancing root development, and preventing destructive soil-borne fungal pathogens like root rot.";
      }
    } else if (widget.news.id == 'news_2') {
      if (isKn) {
        return "ಕರಾವಳಿ ಮತ್ತು ಮಲೆನಾಡು ಜಿಲ್ಲೆಗಳಾದ ದಕ್ಷಿಣ ಕನ್ನಡ, ಉಡುಪಿ ಮತ್ತು ಶಿವಮೊಗ್ಗ ಭಾಗಗಳಲ್ಲಿ ಕಳೆದ ಕೆಲವು ದಿನಗಳಿಂದ ತೇವಾಂಶವು ಶೇಕಡಾ ೮೫ ಕ್ಕಿಂತ ಹೆಚ್ಚಾಗಿದೆ. ಈ ಹವಾಮಾನವು ಪಪ್ಪಾಯಿ ಬೆಳೆಗಳಲ್ಲಿ ಬೂದಿ ರೋಗ (Powdery Mildew) ಹರಡಲು ಅತ್ಯಂತ ಪೂರಕವಾಗಿದೆ.\n\n"
            "ಶಿಫಾರಸು ಮಾಡಿದ ಕ್ರಮಗಳು:\n"
            "೧. ಸೋಂಕಿತ ಎಲೆಗಳನ್ನು ತೋಟದಿಂದ ತೆಗೆದು ನಾಶಪಡಿಸಿ.\n"
            "೨. ಪ್ರತಿ ಲೀಟರ್ ನೀರಿಗೆ ೧ ಮಿ.ಲೀ ಕಾಂಟಾಫ್ ಪ್ಲಸ್ (Contaf Plus) ಅಥವಾ ೨ ಗ್ರಾಂ ಕರಗುವ ಗಂಧಕವನ್ನು (Sulphur WP) ಬೆರೆಸಿ ಎಲೆಗಳ ಎರಡು ಬದಿಗಳಿಗೆ ಸಮನಾಗಿ ಸಿಂಪಡಿಸಿ.\n"
            "೩. ವಾರಕ್ಕೊಮ್ಮೆ ತೋಟವನ್ನು ಪರೀಕ್ಷಿಸಿ ಹರಡುವಿಕೆಯನ್ನು ತಡೆಯಿರಿ.";
      } else if (isHi) {
        return "तटीय और मलनाड क्षेत्रों जैसे दक्षिण कन्नड़, उडुपी और शिवमोगा में पिछले कुछ दिनों से हवा में आर्द्रता 85% से अधिक बनी हुई है। यह नमी पपीते की फसल में पाउडर फफूंद (Powdery Mildew) रोग के प्रसार के लिए अत्यधिक अनुकूल है।\n\n"
            "सुझाए गए उपाय:\n"
            "1. संक्रमित पत्तियों को हटाकर नष्ट कर दें।\n"
            "2. प्रति लीटर पानी में 1 मिलीलीटर कोंटाफ प्लस (Contaf Plus) या 2 ग्राम घुलनशील गंधक (Sulphur WP) मिलाकर पत्तियों के दोनों ओर अच्छी तरह छिड़काव करें।\n"
            "3. बीमारी को बढ़ने से रोकने के लिए सप्ताह में एक बार खेत का निरीक्षण करें।";
      } else {
        return "Due to continuous rainfall and cloudy weather, humidity levels in coastal and Malnad regions (including Mangaluru, Udupi, and Puttur) have surged past 85%. This micro-climate creates a highly favorable environment for the rapid outbreak of Powdery Mildew, a severe fungal disease that affects papaya foliage and reduces yield.\n\n"
            "Action Plan for Farmers:\n"
            "1. Physically remove and burn highly infected lower leaves to restrict spore flight.\n"
            "2. Spray Contaf Plus fungicide (Hexaconazole 5% EC) at a dosage of 1 ml per liter of water, ensuring thorough coverage on both the upper and lower surfaces of the leaves.\n"
            "3. Alternatively, you can use Soluble Sulphur (Sulphur 80% WP) at 2 g/L. Repeat the application after 10-12 days if humidity persists.";
      }
    } else {
      return "Current market reports from APMC centers across Karnataka indicate stable and highly profitable prices for premium-grade papaya, ranging between ₹28 to ₹34 per kilogram. The popular Red Lady (786) variety continues to command a premium due to its sweet taste, longer shelf life, and high transport tolerance.";
    }
  }

  void _playTts() async {
    setState(() => _ttsState = TtsState.playing);
    final textToSpeak = widget.news.getTitle(widget.language) + ". " + _getFullBlogContent();
    final bool spoken = await KannadaTtsService.speakText(textToSpeak, widget.language);
    if (!mounted) return;
    setState(() => _ttsState = TtsState.stopped);
    if (!spoken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio playback is unavailable on this device.'),
        ),
      );
    }
  }

  void _pauseTts() async {
    await KannadaTtsService.pauseSpeech();
    setState(() => _ttsState = TtsState.paused);
  }

  void _stopTts() async {
    await KannadaTtsService.stopSpeech();
    setState(() => _ttsState = TtsState.stopped);
  }

  @override
  Widget build(BuildContext context) {
    final fullContent = _getFullBlogContent();
    final isKn = widget.language == 'kn';

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(widget.news.getCategory(widget.language)),
        ),
        backgroundColor: AppTheme.forestGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.news.getTitle(widget.language),
              style: GoogleFonts.notoSansKannada(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.forestGreen,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 30),
            _buildTtsControls(isKn),
            const SizedBox(height: 20),
            Text(
              fullContent,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTtsControls(bool isKn) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.leafGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.leafGold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTtsIconButton(
            icon: Icons.play_arrow,
            onPressed: _ttsState == TtsState.playing ? null : _playTts,
            label: isKn ? 'ಪ್ಲೇ' : 'Play',
            isActive: _ttsState == TtsState.playing,
          ),
          _buildTtsIconButton(
            icon: Icons.pause,
            onPressed: _ttsState == TtsState.playing ? _pauseTts : null,
            label: isKn ? 'ಪಾಸ್' : 'Pause',
            isActive: _ttsState == TtsState.paused,
          ),
          _buildTtsIconButton(
            icon: Icons.stop,
            onPressed: _ttsState == TtsState.stopped ? null : _stopTts,
            label: isKn ? 'ನಿಲ್ಲಿಸಿ' : 'Stop',
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTtsIconButton({required IconData icon, required VoidCallback? onPressed, required String label, required bool isActive}) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: isActive ? AppTheme.forestGreen : AppTheme.darkMoss),
          onPressed: onPressed,
        ),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
