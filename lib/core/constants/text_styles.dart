import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Styles de texte pour l'application
class AppTextStyles {
  // Tailles de police
  static const double displayLarge = 32.0;
  static const double displayMedium = 28.0;
  static const double displaySmall = 24.0;
  static const double headlineLarge = 22.0;
  static const double headlineMedium = 20.0;
  static const double headlineSmall = 18.0;
  static const double bodyLarge = 18.0;
  static const double bodyMedium = 16.0;
  static const double bodySmall = 14.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;

  /// Obtenir le TextTheme pour le thème clair
  static TextTheme getLightTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: displayLarge,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF212121),
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: displayMedium,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF212121),
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: displaySmall,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF212121),
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: headlineLarge,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF212121),
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: headlineMedium,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF212121),
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: headlineSmall,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF212121),
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: bodyLarge,
        fontWeight: FontWeight.normal,
        color: const Color(0xFF212121),
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: bodyMedium,
        fontWeight: FontWeight.normal,
        color: const Color(0xFF212121),
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: bodySmall,
        fontWeight: FontWeight.normal,
        color: const Color(0xFF757575),
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: labelLarge,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF212121),
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: labelMedium,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF757575),
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: labelSmall,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF757575),
      ),
    );
  }

  /// Obtenir le TextTheme pour le thème sombre
  static TextTheme getDarkTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: displayLarge,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFFFFF),
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: displayMedium,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFFFFF),
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: displaySmall,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFFFFF),
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: headlineLarge,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: headlineMedium,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: headlineSmall,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: bodyLarge,
        fontWeight: FontWeight.normal,
        color: const Color(0xFFFFFFFF),
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: bodyMedium,
        fontWeight: FontWeight.normal,
        color: const Color(0xFFFFFFFF),
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: bodySmall,
        fontWeight: FontWeight.normal,
        color: const Color(0xFFE0E0E0),
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: labelLarge,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFFFFFFF),
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: labelMedium,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFE0E0E0),
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: labelSmall,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFE0E0E0),
      ),
    );
  }
}
