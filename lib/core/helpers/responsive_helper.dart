import 'package:flutter/material.dart';

/// Classe pour gérer les tailles responsives de l'application
class ResponsiveHelper {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isSmallScreen(BuildContext context) {
    return getScreenWidth(context) < 600;
  }

  static bool isMediumScreen(BuildContext context) {
    return getScreenWidth(context) >= 600 && getScreenWidth(context) < 900;
  }

  static bool isLargeScreen(BuildContext context) {
    return getScreenWidth(context) >= 900;
  }

  // Tailles dynamiques basées sur la largeur de l'écran
  static double dynamicWidth(BuildContext context, double percentage) {
    return getScreenWidth(context) * (percentage / 100);
  }

  static double dynamicHeight(BuildContext context, double percentage) {
    return getScreenHeight(context) * (percentage / 100);
  }

  // Tailles de police responsives
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = getScreenWidth(context);
    if (screenWidth < 600) {
      return baseSize * 0.9;
    } else if (screenWidth < 900) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }

  // Padding responsive
  static double getResponsivePadding(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (screenWidth < 600) return 16;
    if (screenWidth < 900) return 20;
    return 24;
  }

  // Rayon de bordure responsive
  static double getResponsiveBorderRadius(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (screenWidth < 600) return 12;
    if (screenWidth < 900) return 16;
    return 20;
  }

  // Hauteur de bouton responsive
  static double getButtonHeight(BuildContext context) {
    return isSmallScreen(context) ? 48 : 56;
  }

  // Largeur de bouton responsive
  static double getButtonWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    return isSmallScreen(context) ? screenWidth - 40 : screenWidth * 0.8;
  }

  // Taille de grille responsive
  static int getGridCrossAxisCount(BuildContext context) {
    if (isSmallScreen(context)) return 2;
    if (isMediumScreen(context)) return 3;
    return 4;
  }

  // Espacement responsive
  static double getHorizontalSpacing(BuildContext context) {
    return isSmallScreen(context) ? 16 : 24;
  }

  static double getVerticalSpacing(BuildContext context) {
    return isSmallScreen(context) ? 12 : 16;
  }

  // Taille d'image responsive
  static double getImageSize(
    BuildContext context, {
    double smallSize = 100,
    double mediumSize = 150,
    double largeSize = 200,
  }) {
    if (isSmallScreen(context)) return smallSize;
    if (isMediumScreen(context)) return mediumSize;
    return largeSize;
  }

  // Taille d'icône responsive
  static double getIconSize(
    BuildContext context, {
    double smallSize = 24,
    double mediumSize = 32,
    double largeSize = 40,
  }) {
    if (isSmallScreen(context)) return smallSize;
    if (isMediumScreen(context)) return mediumSize;
    return largeSize;
  }
}
