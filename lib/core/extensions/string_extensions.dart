extension StringExtensions on String {
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(this);
  }

  bool get isValidPassword {
    return length >= 8;
  }

  // Nommé isNotBlank (et non isNotEmpty) car Dart n'autorise pas qu'une
  // extension masque un membre déjà déclaré par le type étendu — une
  // méthode isNotEmpty ici ne serait jamais appelée, String.isNotEmpty natif
  // (sans trim) prenant systématiquement le dessus silencieusement.
  bool get isNotBlank {
    return trim().isNotEmpty;
  }

  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  String get capitalizeAll {
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  String get truncate {
    if (length > 50) {
      return '${substring(0, 47)}...';
    }
    return this;
  }
}
