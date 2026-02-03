import 'package:flutter/services.dart';

/// A formatter that auto-capitalizes the first letter of sentences.
/// It triggers capitalization:
/// 1. At the very start of the text.
/// 2. After a period followed by a space ". ".
class CapitalizeSentencesFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text;
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      // Capitalize first character
      if (i == 0) {
        buffer.write(char.toUpperCase());
        continue;
      }

      // Check if previous characters form ". " pattern
      if (i >= 2 && text[i - 2] == '.' && text[i - 1] == ' ') {
        buffer.write(char.toUpperCase());
        continue;
      }

      buffer.write(char);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: newValue.selection,
    );
  }
}

/// A formatter that allows standard text with accents/special chars but can enforce other rules if needed.
/// By default, Flutter text fields allow all unicode chars, so we mainly need this for Specific filtering
/// if we wanted to RESTRICT. The user asked to AUTHORIZE special chars, which is default behavior,
/// but combined with the formatting requirement.
class NameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Simply capitalize first letter for names
    if (newValue.text.isEmpty) return newValue;
    
    // Capitalize first letter of each word (optional, but good for names)
    // The user strictly asked for:
    // 1. Force start with Uppercase
    // 2. Uppercase after ". "
    // This logic is covered by CapitalizeSentencesFormatter, but names usually want 
    // Title Case (Uppercase after space).
    // Let's implement Title Case for names if appropriate, or stick to the user's specific rule.
    // User rule: "commencer par une lettre majuscule et que la prochaine lettre venant après un point (.) et un espace soit forcée en majuscule."
    // This sounds more like sentence case. I will stick to what was asked exactly.
    
    // Reuse the logic above or just use the class above.
    return CapitalizeSentencesFormatter().formatEditUpdate(oldValue, newValue);
  }
}
