import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'providers/theme_provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/font_size_provider.dart';
import 'services/storage/storage_service.dart';
import 'services/gemini/gemini_service.dart';
import 'services/rag_service.dart';
import 'services/notification_service.dart';

final StorageService storageService = StorageService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service de stockage
  await storageService.init();

  // Charger les variables d'environnement (si .env absent, continuer sans planter)
  // Try loading a packaged asset first (works when the .env is added to pubspec assets)
  var loaded = false;
  try {
    await dotenv.load(fileName: 'assets/.env');
    debugPrint('Variables d\'environnement chargées depuis assets/.env');
    loaded = true;
  } catch (_) {
    // ignore and try fallback
  }

  // Fallback: try loading from project root (useful during `flutter run` in some setups)
  if (!loaded) {
    try {
      await dotenv.load(fileName: '.env');
      debugPrint(
        'Variables d\'environnement chargées depuis .env à la racine du projet',
      );
      loaded = true;
    } catch (e) {
      debugPrint(
        'Avertissement: fichier .env introuvable ou erreur de chargement. Continuer sans variables d\'environnement. ($e)',
      );
    }
  }
  String? geminiKey;
  try {
    geminiKey = dotenv.env['GEMINI_API_KEY'];
  } catch (_) {
    geminiKey = null;
  }
  // If not found in .env, allow passing via --dart-define at runtime/build time.
  if (geminiKey == null || geminiKey.isEmpty) {
    const fromDartDefine = String.fromEnvironment('GEMINI_API_KEY');
    if (fromDartDefine.isNotEmpty) {
      geminiKey = fromDartDefine;
      debugPrint('GEMINI_API_KEY récupérée depuis --dart-define');
    }
  }
  if (geminiKey == null || geminiKey.isEmpty) {
    debugPrint(
      'Aucune clé GEMINI_API_KEY trouvée dans les variables d\'environnement. Gemini ne sera pas initialisé.',
    );
  } else {
    try {
      geminiService.initialize(geminiKey);
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de Gemini: $e');
    }
  }

  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize RAG assets in background before running the app (safe to continue if it fails)
  try {
    await RagService.instance.initFromAssets();
    debugPrint('RAG assets loaded into memory');
  } catch (e) {
    debugPrint('RAG initialization failed: $e');
  }

  // Initialize localization provider
  final localeProvider = LocaleProvider();
  await localeProvider.initialize();
  debugPrint('Locale provider initialized: ${localeProvider.locale}');

  // Initialize font size provider
  final fontSizeProvider = FontSizeProvider();
  await fontSizeProvider.initialize();
  debugPrint('Font size provider initialized: ${fontSizeProvider.fontSize.name}');

  // Restore user session from cache if available
  final authProvider = AuthProvider();
  await authProvider.restoreFromCache();
  debugPrint('Auth session restored: ${authProvider.isAuthenticated}');

  runApp(GreenApp(
    authProvider: authProvider,
    localeProvider: localeProvider,
    fontSizeProvider: fontSizeProvider,
  ));
}

class GreenApp extends StatelessWidget {
  final AuthProvider? authProvider;
  final LocaleProvider? localeProvider;
  final FontSizeProvider? fontSizeProvider;
  const GreenApp({
    this.authProvider,
    this.localeProvider,
    this.fontSizeProvider,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => authProvider ?? AuthProvider()),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => localeProvider ?? LocaleProvider()),
        ChangeNotifierProvider<FontSizeProvider>(create: (_) => fontSizeProvider ?? FontSizeProvider()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Green',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
