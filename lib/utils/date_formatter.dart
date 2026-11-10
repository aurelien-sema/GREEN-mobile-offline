/// Dates lisibles sans dépendance (le pidgin reprend les mois anglais).
const Map<String, List<String>> _months = {
  'fr': ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'],
  'en': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
};

List<String> _monthsFor(String locale) => _months[locale] ?? _months['en']!;

String _two(int v) => v.toString().padLeft(2, '0');

/// « 7 novembre 2026 » / « 7 November 2026 ».
String formatDate(DateTime date, String locale) {
  final d = date.toLocal();
  final m = _monthsFor(locale == 'fr' ? 'fr' : 'en')[d.month - 1];
  return locale == 'fr' ? '${d.day} $m ${d.year}' : '$m ${d.day}, ${d.year}';
}

/// « 14:05 ».
String formatTime(DateTime date) {
  final d = date.toLocal();
  return '${_two(d.hour)}:${_two(d.minute)}';
}

/// « 7 novembre 2026 à 14:05 » / « November 7, 2026 at 14:05 ».
String formatDateTime(DateTime date, String locale) {
  final sep = switch (locale) { 'fr' => ' à ', 'pid' => ' for ', _ => ' at ' };
  return '${formatDate(date, locale)}$sep${formatTime(date)}';
}

/// Regroupement de l'historique : 'today', 'yesterday', ou la date.
String dayGroupLabel(DateTime date, String locale, String Function(String) t, {DateTime? now}) {
  final n = (now ?? DateTime.now()).toLocal();
  final d = date.toLocal();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return t('today');
  if (diff == 1) return t('yesterday');
  return formatDate(d, locale);
}

/// Compatibilité avec l'ancien nom.
String formatDateFrench(DateTime dateTime, [String locale = 'fr']) => formatDateTime(dateTime, locale);
