import 'package:flutter/services.dart';

/// Formateurs qui empêchent physiquement la saisie de caractères hors type :
/// un champ ne peut recevoir que des données de son type.

/// Nom de personne : lettres (accents compris), espaces, apostrophe, tiret,
/// point. Pas de chiffres ni d'emoji. Espaces multiples réduits à un seul.
class NameInputFormatter extends TextInputFormatter {
  static final RegExp _allowed = RegExp(r"[^A-Za-zÀ-ÖØ-öø-ÿ' .\-]");

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(_allowed, '');
    text = text.replaceAll(RegExp(r' {2,}'), ' ');
    if (text.startsWith(' ')) text = text.trimLeft();
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Adresse e-mail : pas d'espace, minuscules.
class EmailInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\s'), '').toLowerCase();
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Texte libre court (réponse de sécurité, titre…) : supprime les retours à
/// la ligne et les espaces en double.
class SingleLineTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[\r\n\t]'), ' ').replaceAll(RegExp(r' {2,}'), ' ');
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
