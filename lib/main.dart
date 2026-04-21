import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/onboarding/splash_screen.dart';

void main() {
  runApp(const TrishApp());
}

class TrishApp extends StatelessWidget {
  const TrishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRISH Dating App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
