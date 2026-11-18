import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/diseases_provider.dart';
import 'providers/font_size_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/marketplace_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/weather_provider.dart';
import 'services/green_web/photo_sync_service.dart';
import 'services/storage/storage_service.dart';

final StorageService storageService = StorageService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Erreur Flutter : ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Erreur non gérée : $error\n$stack');
    return true;
  };

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Strict minimum avant le premier affichage ; le reste se fait pendant
  // l'écran de démarrage (AppBootstrap.run).
  await storageService.init();
  await AppBootstrap.loadEnv();
  final locale = LocaleProvider();
  final fontSize = FontSizeProvider();
  await Future.wait([locale.initialize(), fontSize.initialize()]);

  runApp(GreenApp(localeProvider: locale, fontSizeProvider: fontSize));
}

class GreenApp extends StatefulWidget {
  final LocaleProvider? localeProvider;
  final FontSizeProvider? fontSizeProvider;
  final AuthProvider? authProvider;

  const GreenApp({super.key, this.localeProvider, this.fontSizeProvider, this.authProvider});

  @override
  State<GreenApp> createState() => _GreenAppState();
}

class _GreenAppState extends State<GreenApp> {
  late final AuthProvider _auth = widget.authProvider ?? AuthProvider();
  late final GoRouter _router = createRouter(_auth);
  final PhotoSyncService _sync = PhotoSyncService();
  String? _attachedFor;

  @override
  void initState() {
    super.initState();
    // Envoi automatique vers GREEN Web : file commune au téléphone, démarrée
    // une fois ; à chaque connexion, les analyses jamais envoyées du compte
    // sont ajoutées à la file.
    _sync.start();
    _auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final id = _auth.currentUser?.id;
    if (id == _attachedFor) return;
    _attachedFor = id;
    _sync.onUserChanged(id);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _sync.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => widget.localeProvider ?? LocaleProvider()),
        ChangeNotifierProvider<FontSizeProvider>(create: (_) => widget.fontSizeProvider ?? FontSizeProvider()),
        ChangeNotifierProvider(create: (_) => DiseasesProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider<PhotoSyncService>.value(value: _sync),
        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer3<ThemeProvider, LocaleProvider, FontSizeProvider>(
        builder: (context, theme, locale, font, _) => MaterialApp.router(
          title: 'GREEN',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: theme.themeMode,
          locale: Locale(locale.materialLanguage),
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
          // Taille du texte choisie dans les Paramètres, appliquée partout et
          // combinée à celle du système (bornée pour garder des écrans lisibles).
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final system = mq.textScaler.scale(14) / 14;
            final factor = (system * font.scale).clamp(0.8, 2.0);
            return MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(factor)),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
