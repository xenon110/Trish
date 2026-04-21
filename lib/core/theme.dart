import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Colors based on TRISH UI
  static const Color primaryMaroon = Color(0xFF9D4C5E);
  static const Color backgroundPeach = Color(0xFFFCF6F6);
  static const Color textDark = Color(0xFF2C2C2C);
  static const Color textLight = Color(0xFF7A7A7A);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFB1586E), Color(0xFFE89A9A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF9D4C5E), Color(0xFFD67086)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Global Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: backgroundPeach,
      primaryColor: primaryMaroon,
      colorScheme: const ColorScheme.light(
        primary: primaryMaroon,
        secondary: Color(0xFFD67086),
        background: backgroundPeach,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textLight,
        ),
      ),
    );
  }
}
