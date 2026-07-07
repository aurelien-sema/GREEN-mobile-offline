const Map<String, List<String>> _monthNamesByLocale = {
  'fr': [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ],
  // Le pidgin camerounais n'a pas de noms de mois distincts standardisés ;
  // on retombe sur l'anglais (langue de base du pidgin) plutôt que le français.
  'en': [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ],
  'pid': [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ],
};

const Map<String, String> _dateTimeSeparatorByLocale = {
  'fr': ' à ',
  'en': ' at ',
  'pid': ' for ',
};

List<String> _monthNamesFor(String locale) =>
    _monthNamesByLocale[locale] ?? _monthNamesByLocale['fr']!;

String _separatorFor(String locale) =>
    _dateTimeSeparatorByLocale[locale] ?? _dateTimeSeparatorByLocale['fr']!;

/// Format a DateTime as "Jour-Mois(lettres)-Année à/at Heure:Minute",
/// dans la langue [locale] ('fr', 'en' ou 'pid'). Par défaut 'fr' pour
/// rester compatible avec les appels existants qui ne précisent pas de locale.
/// Example (fr): "3-février-2026 à 14:30"
String formatDateFrench(DateTime dateTime, [String locale = 'fr']) {
  final dt = dateTime.toLocal();
  final month = _monthNamesFor(locale)[dt.month - 1];
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '${dt.day}-$month-${dt.year}${_separatorFor(locale)}$hour:$minute';
}

/// Format only the date part: "Jour-Mois(lettres)-Année"
String formatDateOnlyFrench(DateTime dateTime, [String locale = 'fr']) {
  final dt = dateTime.toLocal();
  final month = _monthNamesFor(locale)[dt.month - 1];
  return '${dt.day}-$month-${dt.year}';
}

/// Format only the time part: "Heure:Minute"
String formatTimeOnlyFrench(DateTime dateTime, [String locale = 'fr']) {
  final dt = dateTime.toLocal();
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
