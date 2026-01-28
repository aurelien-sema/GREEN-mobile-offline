class Validators {
  // Names with accents and basic punctuation allowed
  // Accept letters including common accented ranges, spaces and basic punctuation
  static final RegExp nameReg = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ '\-\.]{1,64}$");

  // Simple email validation (RFC-compliant regex is long); this covers common cases
  static final RegExp emailReg = RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}");

  // Phone numbers: allows +, digits, spaces, dashes, parentheses
  static final RegExp phoneReg = RegExp(r"^[+]?([0-9 ()-]){6,20}");

  // Password: at least 8 chars, allow special and accented characters
  static final RegExp passwordReg = RegExp(r"^.{8,}$", unicode: true);

  static String? validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nom requis';
    if (!nameReg.hasMatch(v.trim())) return 'Nom invalide';
    return null;
  }

  static String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email requis';
    if (!emailReg.hasMatch(v.trim())) return 'Email invalide';
    return null;
  }

  static String? validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Téléphone requis';
    if (!phoneReg.hasMatch(v.trim())) return 'Numéro de téléphone invalide';
    return null;
  }

  static String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe requis';
    if (!passwordReg.hasMatch(v)) {
      return 'Mot de passe trop court (8+ caractères)';
    }
    return null;
  }
}
