import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';
import '../utils/localized_text.dart';
import '../widgets/language_dropdown.dart';
import '../services/ml_prediction_service.dart';
import '../services/api_backend_service.dart';
import 'diagnosis_result_screen.dart';

class ScanScreen extends StatefulWidget {
  final String language;
  const ScanScreen({super.key, this.language = 'kn'});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  bool _isAnalyzing = false;
  final String _selectedDiseaseKey = 'powdery_mildew'; // Default sample
  String? _imagePath;
  late String _activeLanguage;
  final ImagePicker _picker = ImagePicker();

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _activeLanguage = widget.language;
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> _takeInAppPhoto() async {
    if (_cameraController == null || !_isCameraInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pickLocalized(
              _activeLanguage,
              kn: 'ℹ️ ಸಿಮ್ಯುಲೇಟರ್ ಮೋಡ್: ಮಾದರಿ ಎಲೆ ಬಳಸಲಾಗುತ್ತಿದೆ.',
              hi: 'सिम्युलेटर मोड: नमूना पत्ती का उपयोग किया जा रहा है।',
              en: 'Simulator Mode: Using selected sample leaf.',
            ),
          ),
          backgroundColor: AppTheme.forestGreen,
        ),
      );
      _startMLScan();
      return;
    }

    try {
      setState(() => _isAnalyzing = true);
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _imagePath = photo.path;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _startMLScan({bool force = false}) async {
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pickLocalized(
              _activeLanguage,
              kn:
                  '📸 ದಯವಿಟ್ಟು ಮೊದಲು ಪಪ್ಪಾಯಿ ಎಲೆಯ ಫೋಟೋ ತೆಗೆಯಿರಿ ಅಥವಾ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ.',
              hi: '📸 कृपया पहले पपीते की पत्ती की फोटो लें या अपलोड करें।',
              en: '📸 Please take or upload a papaya leaf photo first.',
            ),
          ),
          backgroundColor: const Color(0xFF1A5C3A),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final MLPredictionResult result =
          await ApiBackendService.fetchPredictionFromBackend(
            imagePath: _imagePath,
            diseaseKey: _selectedDiseaseKey,
            force: force,
          );

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => DiagnosisResultScreen(
                result: result,
                language: _activeLanguage,
              ),
        ),
      );
    } on LeafRejectionException catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });

      if (e.reason == 'unsure_papaya') {
        _showUnsureDialog(e);
      } else {
        setState(() {
          _imagePath = null;
        });
        _showRejectionDialog(e);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showUnsureDialog(LeafRejectionException e) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFF1A2332),
            icon: const Text('🤔', style: TextStyle(fontSize: 48)),
            title: Text(
              pickLocalized(
                _activeLanguage,
                kn: 'ಖಚಿತಪಡಿಸಿ',
                hi: 'पुष्टि करें',
                en: 'Confirm Leaf',
              ),
              style: GoogleFonts.notoSansKannada(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              e.getMessage(_activeLanguage),
              style: GoogleFonts.notoSansKannada(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _imagePath = null);
                },
                child: Text(
                  pickLocalized(
                    _activeLanguage,
                    kn: 'ಅಲ್ಲ (ನಿಲ್ಲಿಸಿ)',
                    hi: 'नहीं (रोकें)',
                    en: 'No (Stop)',
                  ),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _startMLScan(force: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.leafGold,
                ),
                child: Text(
                  pickLocalized(
                    _activeLanguage,
                    kn: 'ಹೌದು (ವಿಶ್ಲೇಷಿಸಿ)',
                    hi: 'हाँ (विश्लेषण करें)',
                    en: 'Yes (Analyze)',
                  ),
                  style: const TextStyle(color: AppTheme.darkMoss),
                ),
              ),
            ],
          ),
    );
  }

  void _showRejectionDialog(LeafRejectionException e) {
    final isNotLeaf = e.reason == 'not_a_leaf';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFF1A2332),
            icon: Text(
              isNotLeaf ? '🚫' : '🍃',
              style: const TextStyle(fontSize: 48),
            ),
            title: Text(
              isNotLeaf
                  ? pickLocalized(
                    _activeLanguage,
                    kn: 'ಎಲೆ ಕಂಡುಬಂದಿಲ್ಲ',
                    hi: 'पत्ती नहीं मिली',
                    en: 'No Leaf Detected',
                  )
                  : pickLocalized(
                    _activeLanguage,
                    kn: 'ಪಪ್ಪಾಯಿ ಎಲೆ ಅಲ್ಲ',
                    hi: 'पपीते की पत्ती नहीं',
                    en: 'Not a Papaya Leaf',
                  ),
              style: GoogleFonts.notoSansKannada(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              e.getMessage(_activeLanguage),
              style: GoogleFonts.notoSansKannada(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  pickLocalized(
                    _activeLanguage,
                    kn: 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
                    hi: 'फिर कोशिश करें',
                    en: 'Try Again',
                  ),
                  style: GoogleFonts.notoSansKannada(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.leafGold,
                  foregroundColor: AppTheme.darkMoss,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkMoss,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            pickLocalized(
              _activeLanguage,
              kn: '📸 ಪಪ್ಪಾಯಿ ಎಲೆ ಸ್ಕ್ಯಾನರ್',
              hi: '📸 पपीता पत्ता स्कैनर',
              en: '📸 Leaf Scanner',
            ),
            style: GoogleFonts.notoSansKannada(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          LanguageDropdown(
            value: _activeLanguage,
            items: const [
              DropdownMenuItem(value: 'kn', child: Text('KN')),
              DropdownMenuItem(value: 'en', child: Text('EN')),
              DropdownMenuItem(value: 'hi', child: Text('HI')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _activeLanguage = val);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  pickLocalized(
                    _activeLanguage,
                    kn: 'ಎಲೆಯನ್ನು ಚೌಕಟ್ಟಿನ ಮಧ್ಯದಲ್ಲಿರಿಸಿ',
                    hi: 'पत्ती को फ्रेम के बीच में रखें',
                    en: 'Place leaf inside camera frame',
                  ),
                  style: GoogleFonts.notoSansKannada(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                // Scanner Viewport
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.emeraldGreen,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.emeraldGreen.withOpacity(0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _imagePath != null
                                    ? Image.file(
                                      File(_imagePath!),
                                      fit: BoxFit.cover,
                                    )
                                    : (_isCameraInitialized &&
                                        _cameraController != null)
                                    ? CameraPreview(_cameraController!)
                                    : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.eco_rounded,
                                            size: 160,
                                            color:
                                                _selectedDiseaseKey == 'healthy'
                                                    ? AppTheme.emeraldGreen
                                                    : (_selectedDiseaseKey ==
                                                            'powdery_mildew'
                                                        ? Colors.white
                                                            .withOpacity(0.8)
                                                        : AppTheme
                                                            .amberWarning),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            pickLocalized(
                                              _activeLanguage,
                                              kn: 'ಕ್ಯಾಮರಾ ಸಿದ್ಧವಾಗುತ್ತಿದೆ...',
                                              hi: 'कैमरा शुरू हो रहा है...',
                                              en: 'Initializing camera...',
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                AnimatedBuilder(
                                  animation: _scanAnimation,
                                  builder: (context, child) {
                                    return Align(
                                      alignment: Alignment(
                                        0,
                                        _scanAnimation.value * 2 - 1,
                                      ),
                                      child: Container(
                                        height: 4,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppTheme.leafGold,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.leafGold
                                                  .withOpacity(0.9),
                                              blurRadius: 12,
                                              spreadRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Corner Brackets
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _buildCorner(top: true, left: true),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _buildCorner(top: true, left: false),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: _buildCorner(top: false, left: true),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: _buildCorner(top: false, left: false),
                        ),

                        if (_imagePath != null && !_isAnalyzing)
                          Positioned(
                            top: 24,
                            right: 24,
                            child: FloatingActionButton.small(
                              backgroundColor: Colors.redAccent,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              onPressed:
                                  () => setState(() => _imagePath = null),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isAnalyzing
                                  ? null
                                  : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                          ),
                          label: Text(
                            pickLocalized(
                              _activeLanguage,
                              kn: 'ಗ್ಯಾಲರಿ',
                              hi: 'ಗ್ಯಾಲರಿ',
                              en: 'Gallery',
                            ),
                            style: GoogleFonts.notoSansKannada(
                              color: Colors.white,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isAnalyzing
                                  ? null
                                  : (_imagePath == null
                                      ? _takeInAppPhoto
                                      : _startMLScan),
                          icon: Icon(
                            _imagePath == null
                                ? Icons.camera_alt
                                : Icons.center_focus_strong,
                            color: AppTheme.darkMoss,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _imagePath == null
                                  ? pickLocalized(
                                    _activeLanguage,
                                    kn: 'ಫೋಟೋ ತೆಗೆಯಿರಿ',
                                    hi: 'फोटो लें',
                                    en: 'Take Photo',
                                  )
                                  : pickLocalized(
                                    _activeLanguage,
                                    kn: 'ಪರೀಕ್ಷಿಸಿ',
                                    hi: 'जांचें',
                                    en: 'Analyze',
                                  ),
                              style: GoogleFonts.notoSansKannada(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkMoss,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.leafGold,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isAnalyzing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.85),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.leafGold),
                      const SizedBox(height: 20),
                      Text(
                        pickLocalized(
                          _activeLanguage,
                          kn: '🔬 ವಿಶ್ಲೇಷಣೆ ನಡೆಯುತ್ತಿದೆ...',
                          hi: '🔬 विश्लेषण हो रहा है...',
                          en: '🔬 Analyzing Leaf...',
                        ),
                        style: GoogleFonts.notoSansKannada(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top:
              top
                  ? const BorderSide(color: AppTheme.leafGold, width: 4)
                  : BorderSide.none,
          bottom:
              !top
                  ? const BorderSide(color: AppTheme.leafGold, width: 4)
                  : BorderSide.none,
          left:
              left
                  ? const BorderSide(color: AppTheme.leafGold, width: 4)
                  : BorderSide.none,
          right:
              !left
                  ? const BorderSide(color: AppTheme.leafGold, width: 4)
                  : BorderSide.none,
        ),
      ),
    );
  }
}
