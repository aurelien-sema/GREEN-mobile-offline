import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.lightPrimary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        tertiary: AppColors.lightTertiary,
        surface: AppColors.lightSurface,
        error: AppColors.lightError,
        onPrimary: AppColors.lightOnPrimary,
        onSurface: AppColors.lightOnBackground,
      ),
      textTheme: _buildTextTheme(false),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnBackground,
        elevation: 2,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: AppConstants.fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.lightOnBackground,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightOnPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: AppConstants.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: AppConstants.fontSizeMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          side: const BorderSide(color: AppColors.lightPrimary, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: AppConstants.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightTertiary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppColors.lightError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppColors.lightError, width: 2),
        ),
        hintStyle: TextStyle(
          color: AppColors.lightHint,
          fontSize: AppConstants.fontSizeRegular,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.lightHint,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        tertiary: AppColors.darkTertiary,
        surface: AppColors.darkSurface,
        error: AppColors.darkError,
        onPrimary: AppColors.darkOnPrimary,
        onSurface: AppColors.darkOnBackground,
      ),
      textTheme: _buildTextTheme(true),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnBackground,
        elevation: 2,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: AppConstants.fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.darkOnBackground,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: AppConstants.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: AppConstants.fontSizeMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: const BorderSide(color: AppColors.darkPrimary, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: AppConstants.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color.fromRGBO(27, 94, 32, 0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppColors.darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppColors.darkError, width: 2),
        ),
        hintStyle: TextStyle(
          color: AppColors.darkHint,
          fontSize: AppConstants.fontSizeRegular,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkHint,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final textColor = isDark
        ? AppColors.darkOnBackground
        : AppColors.lightOnBackground;

    return TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeTitle,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeXLarge,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeLarge,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeLarge,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeMedium,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeMedium,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeRegular,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeSmall,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeMedium,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeRegular,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeSmall,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeMedium,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeRegular,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: AppConstants.fontSizeSmall,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }
}
