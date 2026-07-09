import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Fond d'écran neutre (pass-through).
///
/// Utilisait auparavant un léger voile dégradé vert sur toute la page ; la
/// direction "Clean Emerald" veut des fonds plats et neutres partout, le vert
/// n'apparaissant que sur des éléments "hero" ciblés (carte météo, cartes
/// d'action, en-tête profil...). Les paramètres sont conservés pour ne pas
/// devoir modifier tous les appels existants, mais n'ont plus d'effet visuel.
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
  Widget build(BuildContext context) => child;
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

/// Carte à fond neutre (blanc/surface) avec bordure fine — direction "Clean
/// Emerald" : plus de teinte verte sur les cartes de contenu ordinaires, le
/// vert reste réservé aux éléments "hero". Le paramètre [opacity] est
/// conservé pour compatibilité mais n'est plus utilisé.
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
    final card = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDarkMode
              ? const Color.fromRGBO(66, 66, 66, 0.3)
              : const Color.fromRGBO(224, 224, 224, 0.6),
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

/// Section titrée à fond neutre — le titre reste en vert (accent), le fond
/// est blanc/surface avec bordure fine plutôt qu'un voile dégradé.
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
    final accent = isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDarkMode
              ? const Color.fromRGBO(66, 66, 66, 0.3)
              : const Color.fromRGBO(224, 224, 224, 0.6),
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
                color: accent,
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
