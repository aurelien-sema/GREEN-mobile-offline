import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isSmallScreen => screenWidth < 600;

  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;

  bool get isLargeScreen => screenWidth >= 1200;

  EdgeInsets get devicePadding => MediaQuery.of(this).padding;

  EdgeInsets get deviceViewInsets => MediaQuery.of(this).viewInsets;
}
