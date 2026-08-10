import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../theme/app_theme.dart';
import 'home_dashboard_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  String _selectedLanguage = 'kn'; // Kannada default

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Base gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
            ),
          ),
          // Saffron glow top-left
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF9933).withOpacity(0.22),
              ),
            ),
          ),
          // Green glow bottom-right
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF138808).withOpacity(0.22),
              ),
            ),
          ),
          // White glow center
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: MediaQuery.of(context).size.width * 0.15,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar: Language Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          dropdownColor: AppTheme.forestGreen,
                          icon: const Icon(Icons.language, color: Colors.white, size: 18),
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          items: const [
                            DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ (Kannada)')),
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
                          ],
                          selectedItemBuilder: (BuildContext context) {
                            return [
                              'KN',
                              'EN',
                              'HI',
                            ].map<Widget>((String item) {
                              return Center(
                                child: Text(
                                  item,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              );
                            }).toList();
                          },
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedLanguage = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Central Brand Hero
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      // App Title
                      Text(
                        _selectedLanguage == 'kn'
                            ? 'ಪಪ್ಪಾಯಿ ರೋಗ ಪತ್ತೆ'
                            : (_selectedLanguage == 'hi'
                                ? 'पपीता रोग पहचान'
                                : 'Papaya Disease Detection'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKannada(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subtitle / Animated Tagline
                      SizedBox(
                        height: 50,
                        child: AnimatedTextKit(
                          key: ValueKey(_selectedLanguage), // Rebuild when language changes
                          repeatForever: true,
                          animatedTexts: [
                            FadeAnimatedText(
                              _selectedLanguage == 'kn'
                                  ? '📸 ಎಲೆ ಫೋಟೋ ಹಾಕಿ ರೋಗ ಪತ್ತೆ ಮಾಡಿ'
                                  : (_selectedLanguage == 'hi'
                                      ? '📸 पत्ती की फोटो डालकर बीमारी का पता लगाएं'
                                      : '📸 Scan leaf to detect disease'),
                              textStyle: GoogleFonts.notoSansKannada(
                                fontSize: 15,
                                color: AppTheme.leafGold,
                                fontWeight: FontWeight.w600,
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                            FadeAnimatedText(
                              _selectedLanguage == 'kn'
                                  ? '💰 ಔಷಧ ಮತ್ತು ಹತ್ತಿರದ ಅಂಗಡಿ ಮಾಹಿತಿ'
                                  : (_selectedLanguage == 'hi'
                                      ? '💰 दवाओं और नजदीकी दुकान की जानकारी'
                                      : '💰 Get medicine & nearby shop info'),
                              textStyle: GoogleFonts.notoSansKannada(
                                fontSize: 15,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Start Button Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.leafGold.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeDashboardScreen(
                                language: _selectedLanguage,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.leafGold,
                          foregroundColor: AppTheme.darkMoss,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedLanguage == 'kn'
                                    ? '🚀 ಪ್ರಾರಂಭಿಸಿ'
                                    : (_selectedLanguage == 'hi' ? '🚀 शुरू करें' : '🚀 Get Started'),
                                style: GoogleFonts.notoSansKannada(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkMoss,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded, color: AppTheme.darkMoss, size: 26),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),
                const Text(
                  'v1.0 • AI-Powered Technology',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TriColorLogo extends StatelessWidget {
  final double size;
  const TriColorLogo({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Removed logo content
  }
}
