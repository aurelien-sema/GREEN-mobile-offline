import 'package:flutter/material.dart';

/// Safely return a color with the given opacity using explicit channel values.
Color colorWithOpacity(Color color, double opacity) {
  // Use component accessors (.r, .g, .b) which are the modern API.
  final int r = (color.r * 255).round().clamp(0, 255);
  final int g = (color.g * 255).round().clamp(0, 255);
  final int b = (color.b * 255).round().clamp(0, 255);
  return Color.fromRGBO(r, g, b, opacity);
}
