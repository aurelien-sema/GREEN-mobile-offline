import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
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

final StorageService storageService = StorageService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Handle errors in async code
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  // Custom error widget for better user experience
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Une erreur est survenue',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exception.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  debugPrint('=== Green App Initialization Started ===');

  // Initialiser le service de stockage
  try {
    await storageService.init();
    debugPrint('✓ Storage service initialized');
  } catch (e) {
    debugPrint('✗ Storage service initialization failed: $e');
    // Continue anyway - app can work without storage
  }

  // Charger les variables d'environnement (si .env absent, continuer sans planter)
  // Try loading a packaged asset first (works when the .env is added to pubspec assets)
  var loaded = false;
  try {
    await dotenv.load(fileName: 'assets/.env');
    debugPrint('✓ Environment variables loaded from assets/.env');
    loaded = true;
  } catch (_) {
    // ignore and try fallback
  }

  // Fallback: try loading from project root (useful during `flutter run` in some setups)
  if (!loaded) {
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('✓ Environment variables loaded from .env at project root');
      loaded = true;
    } catch (e) {
      debugPrint('⚠ Warning: .env file not found or error loading. Continuing without environment variables. ($e)');
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
      debugPrint('✓ GEMINI_API_KEY retrieved from --dart-define');
    }
  }
  if (geminiKey == null || geminiKey.isEmpty) {
    debugPrint('⚠ No GEMINI_API_KEY found in environment variables. Gemini will not be initialized.');
  } else {
    try {
      geminiService.initialize(geminiKey);
      debugPrint('✓ Gemini service initialized');
    } catch (e) {
      debugPrint('✗ Error initializing Gemini: $e');
    }
  }

  // Configuration de la barre de statut
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    debugPrint('✓ System UI overlay configured');
  } catch (e) {
    debugPrint('✗ Error configuring system UI: $e');
  }

  // Portrait uniquement
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    debugPrint('✓ Orientation locked to portrait');
  } catch (e) {
    debugPrint('✗ Error setting orientation: $e');
  }

  // Initialize RAG assets in background before running the app (safe to continue if it fails)
  try {
    await RagService.instance.initFromAssets();
    if (RagService.instance.isInitialized) {
      debugPrint('✓ RAG assets loaded into memory');
    } else {
      debugPrint('⚠ RAG initialization completed but not fully initialized');
    }
  } catch (e) {
    debugPrint('✗ RAG initialization failed: $e');
  }

  // Initialize localization provider
  final localeProvider = LocaleProvider();
  try {
    await localeProvider.initialize();
    debugPrint('✓ Locale provider initialized: ${localeProvider.locale}');
  } catch (e) {
    debugPrint('✗ Locale provider initialization failed: $e');
  }

  // Initialize font size provider
  final fontSizeProvider = FontSizeProvider();
  try {
    await fontSizeProvider.initialize();
    debugPrint('✓ Font size provider initialized: ${fontSizeProvider.fontSize.name}');
  } catch (e) {
    debugPrint('✗ Font size provider initialization failed: $e');
  }

  // Restore user session from cache if available
  final authProvider = AuthProvider();
  try {
    await authProvider.restoreFromCache();
    debugPrint('✓ Auth session restored: ${authProvider.isAuthenticated}');
  } catch (e) {
    debugPrint('✗ Auth session restoration failed: $e');
  }

  debugPrint('=== Green App Initialization Completed ===');

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
