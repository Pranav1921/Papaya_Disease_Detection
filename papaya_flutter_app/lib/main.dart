import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/start_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PapayaCropCareApp());
}

class PapayaCropCareApp extends StatelessWidget {
  const PapayaCropCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Papaya Disease Detection',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const StartScreen(),
    );
  }
}
