import 'package:flutter/widgets.dart';

/// Espacements de GREEN (grille de 4 dp). Depuis la v2.1, les écrans
/// respirent davantage : marges latérales de 20 dp, 16 à 24 dp entre les
/// blocs, cartes à 20 dp de marge intérieure.
class Spacing {
  Spacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Marge latérale des écrans.
  static const double gutter = 20;

  /// Écart vertical entre deux blocs (cartes, sections).
  static const double block = 16;

  /// Contenu d'un écran défilant : marges latérales, et espace en bas pour
  /// que le dernier élément ne colle pas à la barre de navigation.
  static const EdgeInsets page = EdgeInsets.fromLTRB(gutter, md, gutter, 40);

  /// Écrans de formulaire (connexion, inscription…).
  static const EdgeInsets form = EdgeInsets.fromLTRB(28, sm, 28, 40);

  /// Marge intérieure des cartes.
  static const EdgeInsets card = EdgeInsets.all(xl);

  static const SizedBox gapBlock = SizedBox(height: block);
  static const SizedBox gapSection = SizedBox(height: xxl);
}
