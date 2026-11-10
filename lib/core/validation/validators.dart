import '../constants/app_constants.dart';

/// Règles de validation des champs de saisie.
///
/// Chaque méthode renvoie null si la valeur est valide, sinon une CLÉ de
/// traduction (voir lib/l10n/app_strings.dart) à passer à `t()` : les
/// messages s'affichent ainsi dans la langue choisie (FR, EN, Pidgin) au lieu
/// d'être toujours en français.
class Validators {
  Validators._();

  /// Lettres (accents compris), espaces, apostrophe, tiret et point.
  static final RegExp nameReg = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ' .\-]{2,64}$");

  static final RegExp emailReg =
      RegExp(r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$");

  /// Numéro complet (indicatif compris) : 8 à 15 chiffres, « + » initial facultatif.
  static final RegExp phoneReg = RegExp(r'^\+?[0-9]{8,15}$');

  static String? name(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'errNameRequired';
    if (!nameReg.hasMatch(value)) return 'errNameInvalid';
    // Nom complet attendu : au moins deux mots (prénom et nom), car il sert
    // aussi à vérifier l'identité en cas d'oubli du mot de passe.
    if (value.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length < 2) {
      return 'errNameFull';
    }
    return null;
  }

  static String? email(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'errEmailRequired';
    if (!emailReg.hasMatch(value)) return 'errEmailInvalid';
    return null;
  }

  /// [v] : numéro complet tel que composé par IntlPhoneField (+237…).
  static String? phone(String? v) {
    final value = (v ?? '').replaceAll(RegExp(r'[\s().\-]'), '');
    if (value.isEmpty) return 'errPhoneRequired';
    if (!phoneReg.hasMatch(value)) return 'errPhoneInvalid';
    return null;
  }

  static String? password(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'errPasswordRequired';
    if (value.length < AppConstants.minPasswordLength) return 'errPasswordShort';
    if (value.length > AppConstants.maxPasswordLength) return 'errPasswordLong';
    return null;
  }

  /// Mot de passe d'un nouveau compte : 8 caractères dont au moins une
  /// lettre et un chiffre.
  static String? newPassword(String? v) {
    final base = password(v);
    if (base != null) return base;
    final value = v!;
    if (!RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(value) || !RegExp(r'[0-9]').hasMatch(value)) {
      return 'errPasswordWeak';
    }
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if ((v ?? '').isEmpty) return 'errConfirmRequired';
    if (v != original) return 'errPasswordMismatch';
    return null;
  }

  static String? securityAnswer(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'errAnswerRequired';
    if (value.length < 2) return 'errAnswerShort';
    if (value.length > 60) return 'errAnswerLong';
    return null;
  }
}
