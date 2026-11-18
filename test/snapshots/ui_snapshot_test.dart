@Tags(['snapshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/core/theme/app_theme.dart';
import 'package:green_app/features/auth/screens/login_screen.dart';
import 'package:green_app/features/diseases/screens/diseases_screen.dart';
import 'package:green_app/features/profile/screens/about_screen.dart';
import 'package:green_app/features/profile/screens/settings_screen.dart';
import 'package:green_app/providers/auth_provider.dart';
import 'package:green_app/providers/diseases_provider.dart';
import 'package:green_app/providers/font_size_provider.dart';
import 'package:green_app/providers/locale_provider.dart';
import 'package:green_app/providers/theme_provider.dart';
import 'package:green_app/services/green_web/green_web_client.dart';
import 'package:green_app/services/green_web/photo_sync_service.dart';
import 'package:green_app/services/green_web/shared_web_account.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Captures d'écran (vraie police Roboto) pour relire le design sans
/// téléphone : GREEN_SNAPSHOTS=1 flutter test test/snapshots --tags snapshots
/// → build/snapshots/*.png. Ignoré par `flutter test`.
void main() {
  final enabled = Platform.environment['GREEN_SNAPSHOTS'] == '1';

  setUpAll(() async {
    if (!enabled) return;
    final fonts = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(Future.value(ByteData.sublistView(File('$fonts/$f').readAsBytesSync())));
      }
      await loader.load();
    }

    await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
    await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });

  Future<void> shoot(WidgetTester tester, String name, Widget screen, {bool dark = false, double height = 2340}) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'fr'});
    tester.view.physicalSize = Size(1080, height);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final locale = LocaleProvider();
    await locale.initialize();
    final catalog = DiseasesProvider()..loadFromJson(File('assets/data/diseases.json').readAsStringSync());
    catalog.setActiveModelLabels(File('assets/models/tflite/labels.txt').readAsLinesSync().where((l) => l.isNotEmpty).toList());
    final client = GreenWebClient(baseUrl: 'https://api-green.gitingeniering.com');
    final sync = PhotoSyncService(
      client: client,
      account: SharedWebAccount(
        client: client,
        credentials: () => const SharedAccountCredentials(identifier: 'x', password: 'y'),
      ),
      connectivity: () => const Stream.empty(),
    );
    final key = GlobalKey();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: locale),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontSizeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: catalog),
        ChangeNotifierProvider.value(value: sync),
      ],
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: screen,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('build/snapshots/$name.png')..createSync(recursive: true);
      out.writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  final skip = enabled ? null : 'GREEN_SNAPSHOTS=1 non défini';
  testWidgets('connexion', (t) => shoot(t, '01_connexion', const LoginScreen()), skip: skip != null);
  testWidgets('paramètres', (t) => shoot(t, '02_parametres', const SettingsScreen(), height: 5600), skip: skip != null);
  testWidgets('base de maladies', (t) => shoot(t, '03_maladies', const DiseasesScreen()), skip: skip != null);
  testWidgets('fiche maladie', (t) => shoot(t, '04_fiche_maladie', const DiseaseDetailScreen(diseaseId: 'cassava-brown-leaf-spot')),
      skip: skip != null);
  testWidgets('à propos (sombre)', (t) => shoot(t, '05_a_propos_sombre', const AboutScreen(), dark: true), skip: skip != null);
}
