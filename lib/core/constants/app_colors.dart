import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF2E8B57); // Green
  static const Color lightSecondary = Color(0xFF90EE90); // Light green
  static const Color lightTertiary = Color(0xFFE8F5E9); // Very light green
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF1A1A1A);
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightHint = Color(0xFF999999);

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

  // Gradients
  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFF2E8B57), Color(0xFF90EE90)], // Green -> Light Green
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
