extension StringExtensions on String {
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(this);
  }

  bool get isValidPassword {
    return length >= 8;
  }

  bool get isNotEmpty {
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
