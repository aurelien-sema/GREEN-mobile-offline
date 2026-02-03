/// Format a DateTime to French format: "Jour-Mois(lettres)-Année à Heure:Minute"
/// Example: "3-février-2026 à 14:30"
String formatDateFrench(DateTime dateTime) {
  final dt = dateTime.toLocal();
  
  // Jours et mois en français
  final monthNames = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
  ];
  
  final day = dt.day;
  final month = monthNames[dt.month - 1];
  final year = dt.year;
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  
  return '$day-$month-$year à $hour:$minute';
}

/// Format only the date part: "Jour-Mois(lettres)-Année"
String formatDateOnlyFrench(DateTime dateTime) {
  final dt = dateTime.toLocal();
  
  final monthNames = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
  ];
  
  final day = dt.day;
  final month = monthNames[dt.month - 1];
  final year = dt.year;
  
  return '$day-$month-$year';
}

/// Format only the time part: "Heure:Minute"
String formatTimeOnlyFrench(DateTime dateTime) {
  final dt = dateTime.toLocal();
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  
  return '$hour:$minute';
}
