import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF2E8B57); // Green
  static const Color lightSecondary = Color(0xFF90EE90); // Light green
  static const Color lightTertiary = Color(0xFFE8F5E9); // Very light green (fond des pastilles d'icône)
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF1A1A1A);
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightHint = Color(0xFF999999);
  // Accent chaud (prix, avertissements) — direction "Clean Emerald"
  static const Color lightPriceAccent = Color(0xFFE8912D);
  static const Color lightChipNeutralBg = Color(0xFFF2F2F2);
  static const Color lightChipAmberBg = Color(0xFFFFF3D6);
  static const Color lightChipAmberText = Color(0xFFAD6B0A);

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF4CAF50); // Lighter green
  static const Color darkSecondary = Color(0xFF66BB6A); // Medium green
  static const Color darkTertiary = Color(0xFF1B5E20); // Dark green
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkOnBackground = Color(0xFFFAFAFA);
  static const Color darkError = Color(0xFFCF6679);
  static const Color darkBorder = Color(0xFF424242);
  static const Color darkHint = Color(0xFF999999);
  static const Color darkPriceAccent = Color(0xFFF2A65A);
  static const Color darkChipNeutralBg = Color(0xFF2A2E2A);
  static const Color darkChipAmberBg = Color(0xFF3A2E12);
  static const Color darkChipAmberText = Color(0xFFE0B868);

  // Gradients
  // Vert riche et profond (pas pastel) : utilisé sur les éléments "hero"
  // (carte météo, cartes d'action Accueil, en-tête Profil...) d'après la
  // direction "Clean Emerald" — le reste de l'app reste clair/aéré.
  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFF2E8B57), Color(0xFF1B5E20)], // Green -> Deep green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)], // Dark Green -> Lighter Green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF2E8B57), Color(0xFF1B5E20)], // Green -> Dark Green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
