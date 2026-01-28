import 'package:flutter/material.dart';
import '../../core/utils/color_utils.dart';
import '../../core/constants/app_colors.dart';

/// Widget conteneur avec dégradé de fond
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  final double opacity;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientBackground({
    super.key,
    required this.child,
    required this.isDarkMode,
    this.opacity = 0.15,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isDarkMode
        ? AppColors.darkGradient
        : AppColors.lightGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [
            colorWithOpacity(gradient.colors[0], opacity),
            colorWithOpacity(gradient.colors[1], opacity),
          ],
          stops: gradient.stops,
        ),
      ),
      child: child,
    );
  }
}

/// Widget pour écran complet avec dégradé
class FullGradientScreen extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;

  const FullGradientScreen({
    super.key,
    required this.child,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isDarkMode
        ? AppColors.darkGradient
        : AppColors.lightGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient.colors,
          stops: gradient.stops,
        ),
      ),
      child: child,
    );
  }
}

/// Widget conteneur avec bord arrondi et dégradé
class GradientCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool isDarkMode;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double opacity;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    required this.isDarkMode,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.opacity = 0.08,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isDarkMode
        ? AppColors.darkGradient
        : AppColors.lightGradient;

    final card = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorWithOpacity(gradient.colors[0], opacity),
            colorWithOpacity(gradient.colors[1], opacity),
          ],
        ),
        border: Border.all(
          color: colorWithOpacity(gradient.colors[0], 0.2),
          width: 1.0,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// Widget pour les sections avec titre et fond dégradé
class GradientSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDarkMode;
  final EdgeInsets padding;

  const GradientSection({
    super.key,
    required this.title,
    required this.child,
    required this.isDarkMode,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isDarkMode
        ? AppColors.darkGradient
        : AppColors.lightGradient;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorWithOpacity(gradient.colors[0], 0.05),
            colorWithOpacity(gradient.colors[1], 0.05),
          ],
        ),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: gradient.colors[0],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            child,
          ],
        ),
      ),
    );
  }
}
