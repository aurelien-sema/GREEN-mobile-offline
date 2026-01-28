/// Localization constants for the Green app.
/// Supports: Français (FR), English (EN), Pidgin (PID)
class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    'fr': {
      // General
      'appTitle': 'Green',
      'ok': 'OK',
      'cancel': 'Annuler',
      'back': 'Retour',
      'next': 'Suivant',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'confirm': 'Confirmer',
      'error': 'Erreur',
      'success': 'Succès',
      'loading': 'Chargement...',

      // Auth
      'login': 'Connexion',
      'register': 'Inscription',
      'email': 'Email',
      'phone': 'Téléphone',
      'password': 'Mot de passe',
      'confirmPassword': 'Confirmer le mot de passe',
      'forgotPassword': 'Mot de passe oublié?',
      'noAccount': 'Pas de compte?',
      'haveAccount': 'Déjà inscrit?',
      'loginSuccess': 'Connexion réussie',
      'registerSuccess': 'Inscription réussie',
      'invalidCredentials': 'Identifiants invalides',
      'userNotFound': 'Utilisateur non trouvé',
      'logout': 'Déconnexion',
      'deleteAccount': 'Supprimer le compte',
      'deleteAccountConfirm': 'Êtes-vous sûr de vouloir supprimer votre compte? Cette action est irréversible.',

      // Home
      'home': 'Accueil',
      'scanner': 'Scanner',
      'greenBot': 'Green Bot',
      'recentScans': 'Scans récents',
      'noScans': 'Aucun scan',

      // Chat
      'chat': 'Chat',
      'message': 'Message',
      'send': 'Envoyer',
      'newChat': 'Nouveau chat',
      'chatHistory': 'Historique du chat',
      'noChatHistory': 'Aucun historique',
      'deleteChat': 'Supprimer ce chat',
      'deleteChatConfirm': 'Êtes-vous sûr de vouloir supprimer ce chat?',

      // Profile
      'profile': 'Profil',
      'preferences': 'Préférences',
      'language': 'Langue',
      'fontSize': 'Taille de police',
      'notifications': 'Notifications',
      'frequencyOfAdvice': 'Fréquence des conseils',
      'pushNotifications': 'Notifications push',
      'emailNotifications': 'Notifications email',
      'small': 'Petit',
      'medium': 'Moyen',
      'large': 'Grand',
      'daily': 'Quotidien',
      'weekly': 'Hebdomadaire',
      'monthly': 'Mensuel',
      'never': 'Jamais',

      // Errors & Messages
      'somethingWentWrong': 'Une erreur s\'est produite',
      'tryAgain': 'Réessayer',
      'connectionError': 'Erreur de connexion',
      'invalidInput': 'Entrée invalide',
      'userNotFoundError': 'Erreur: compte non trouvé',
      'errorAnalyzing': 'Erreur lors de l\'analyse',
      'analysisCompleted': 'Analyse terminée, aucun résultat disponible.',

      // History
      'history': 'Historique',
      'sortBy': 'Trier par :',
      'dateDescending': 'Date (desc)',
      'dateAscending': 'Date (asc)',
      'nameAZ': 'Nom (A-Z)',
      'nameZA': 'Nom (Z-A)',
      'scanDate': 'Date du scan',
      'affectedPlants': 'plantes',

      // Diseases
      'diseases': 'Maladies des plantes',
      'diseaseName': 'Maladie',
      'severity': 'Sévérité',
      'recommendation': 'Recommandation',
      'scanResults': 'Résultats du scan',

      // Scanner/Camera
      'camera': 'Caméra',
      'takePicture': 'Prendre une photo',
      'uploadImage': 'Charger une image',
      'scanning': 'Analyse en cours...',

      // About/Settings
      'about': 'À propos',
      'aboutGreen': 'À propos de Green',
      'menu': 'Menu',
      'darkTheme': 'Thème sombre',
      'lightTheme': 'Thème clair',
      'version': 'Version',

      // Dialog buttons
      'deleteConfirm': 'Supprimer',
      'closeDialog': 'Fermer',
    },
    'en': {
      // General
      'appTitle': 'Green',
      'ok': 'OK',
      'cancel': 'Cancel',
      'back': 'Back',
      'next': 'Next',
      'save': 'Save',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',

      // Auth
      'login': 'Login',
      'register': 'Sign Up',
      'email': 'Email',
      'phone': 'Phone',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'forgotPassword': 'Forgot password?',
      'noAccount': 'Don\'t have an account?',
      'haveAccount': 'Already have an account?',
      'loginSuccess': 'Login successful',
      'registerSuccess': 'Registration successful',
      'invalidCredentials': 'Invalid credentials',
      'userNotFound': 'User not found',
      'logout': 'Logout',
      'deleteAccount': 'Delete Account',
      'deleteAccountConfirm': 'Are you sure you want to delete your account? This action is irreversible.',

      // Home
      'home': 'Home',
      'scanner': 'Scanner',
      'greenBot': 'Green Bot',
      'recentScans': 'Recent Scans',
      'noScans': 'No scans',

      // Chat
      'chat': 'Chat',
      'message': 'Message',
      'send': 'Send',
      'newChat': 'New Chat',
      'chatHistory': 'Chat History',
      'noChatHistory': 'No history',
      'deleteChat': 'Delete this chat',
      'deleteChatConfirm': 'Are you sure you want to delete this chat?',

      // Profile
      'profile': 'Profile',
      'preferences': 'Preferences',
      'language': 'Language',
      'fontSize': 'Font Size',
      'notifications': 'Notifications',
      'frequencyOfAdvice': 'Frequency of Tips',
      'pushNotifications': 'Push Notifications',
      'emailNotifications': 'Email Notifications',
      'small': 'Small',
      'medium': 'Medium',
      'large': 'Large',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'never': 'Never',

      // Errors & Messages
      'somethingWentWrong': 'Something went wrong',
      'tryAgain': 'Try Again',
      'connectionError': 'Connection error',
      'invalidInput': 'Invalid input',
      'userNotFoundError': 'Error: user not found',
      'errorAnalyzing': 'Error during analysis',
      'analysisCompleted': 'Analysis complete, no results available.',

      // History
      'history': 'History',
      'sortBy': 'Sort by:',
      'dateDescending': 'Date (desc)',
      'dateAscending': 'Date (asc)',
      'nameAZ': 'Name (A-Z)',
      'nameZA': 'Name (Z-A)',
      'scanDate': 'Scan date',
      'affectedPlants': 'plants',

      // Diseases
      'diseases': 'Plant Diseases',
      'diseaseName': 'Disease',
      'severity': 'Severity',
      'recommendation': 'Recommendation',
      'scanResults': 'Scan Results',

      // Scanner/Camera
      'camera': 'Camera',
      'takePicture': 'Take Picture',
      'uploadImage': 'Upload Image',
      'scanning': 'Scanning...',

      // About/Settings
      'about': 'About',
      'aboutGreen': 'About Green',
      'menu': 'Menu',
      'darkTheme': 'Dark Theme',
      'lightTheme': 'Light Theme',
      'version': 'Version',

      // Dialog buttons
      'deleteConfirm': 'Delete',
      'closeDialog': 'Close',
    },
    'pid': {
      // General
      'appTitle': 'Green',
      'ok': 'Okay',
      'cancel': 'Cancel',
      'back': 'Go back',
      'next': 'Next one',
      'save': 'Save am',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'error': 'Error',
      'success': 'Well done',
      'loading': 'Loading now...',

      // Auth
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'phone': 'Phone',
      'password': 'Password',
      'confirmPassword': 'Confirm your password',
      'forgotPassword': 'Forget your password?',
      'noAccount': 'You get no account?',
      'haveAccount': 'You don get account before?',
      'loginSuccess': 'Login go well',
      'registerSuccess': 'Registration go well',
      'invalidCredentials': 'Your credentials no correct',
      'userNotFound': 'We no find that person',
      'logout': 'Leave',
      'deleteAccount': 'Wipe my account',
      'deleteAccountConfirm': 'You sure say you want delete your account? This one no go come back.',

      // Home
      'home': 'Home',
      'scanner': 'Scanner',
      'greenBot': 'Green Bot',
      'recentScans': 'Recent picture wey you scan',
      'noScans': 'No picture wey you scan',

      // Chat
      'chat': 'Chat',
      'message': 'Message',
      'send': 'Send',
      'newChat': 'New chat',
      'chatHistory': 'History of chat',
      'noChatHistory': 'No history',
      'deleteChat': 'Delete this chat',
      'deleteChatConfirm': 'You sure say you want delete this chat?',

      // Profile
      'profile': 'Profile',
      'preferences': 'Settings',
      'language': 'Language',
      'fontSize': 'Size of letter',
      'notifications': 'Messages wey come to you',
      'frequencyOfAdvice': 'How many time advice go come',
      'pushNotifications': 'Messages on your phone',
      'emailNotifications': 'Messages for your email',
      'small': 'Small',
      'medium': 'Medium',
      'large': 'Big',
      'daily': 'Every day',
      'weekly': 'Every week',
      'monthly': 'Every month',
      'never': 'Never',

      // Errors & Messages
      'somethingWentWrong': 'Something go wrong',
      'tryAgain': 'Try again',
      'connectionError': 'Connection no work',
      'invalidInput': 'What you enter no correct',
      'userNotFoundError': 'Error: person no dey',
      'errorAnalyzing': 'Error when we dey check your picture',
      'analysisCompleted': 'We finish check, but nothing no show.',

      // History
      'history': 'History wey you save',
      'sortBy': 'How you wan arrange:',
      'dateDescending': 'Date (new first)',
      'dateAscending': 'Date (old first)',
      'nameAZ': 'Name (A to Z)',
      'nameZA': 'Name (Z to A)',
      'scanDate': 'When you check am',
      'affectedPlants': 'plants wey get problem',

      // Diseases
      'diseases': 'Sickness for your plant them',
      'diseaseName': 'The sickness',
      'severity': 'How bad am be',
      'recommendation': 'What you go do',
      'scanResults': 'What we find out',

      // Scanner/Camera
      'camera': 'Camera',
      'takePicture': 'Snap picture',
      'uploadImage': 'Bring picture',
      'scanning': 'We dey check now...',

      // About/Settings
      'about': 'About',
      'aboutGreen': 'About Green',
      'menu': 'Menu',
      'darkTheme': 'Dark side',
      'lightTheme': 'Bright side',
      'version': 'Version',

      // Dialog buttons
      'deleteConfirm': 'Delete',
      'closeDialog': 'Close',
    },
  };

  /// Get string by key for given locale.
  /// Returns English if key not found in requested locale.
  static String get(String key, [String locale = 'fr']) {
    return _strings[locale]?[key] ??
        _strings['en']?[key] ??
        key; // Fallback to key name if not found
  }

  /// All available locales.
  static const List<String> availableLocales = ['fr', 'en', 'pid'];

  /// Locale display names.
  static const Map<String, String> localeNames = {
    'fr': 'Français',
    'en': 'English',
    'pid': 'Pidgin',
  };
}
