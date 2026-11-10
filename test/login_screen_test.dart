import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/features/auth/screens/login_screen.dart';
import 'package:green_app/providers/auth_provider.dart';
import 'package:green_app/providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'app_locale': 'fr'}));

  Future<void> pump(WidgetTester tester) async {
    final locale = LocaleProvider();
    await locale.initialize();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: locale),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MaterialApp(home: LoginScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('connexion : clavier téléphone par défaut, e-mail au basculement', (tester) async {
    await pump(tester);
    expect(find.text('Bienvenue'), findsOneWidget);

    final phone = tester.widget<TextField>(find.byType(TextField).first);
    expect(phone.keyboardType, TextInputType.phone);

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    final email = tester.widget<TextField>(find.byType(TextField).first);
    expect(email.keyboardType, TextInputType.emailAddress);
    expect(email.autofillHints, contains(AutofillHints.email));

    final password = tester.widget<TextField>(find.byType(TextField).last);
    expect(password.obscureText, isTrue);
    expect(password.autofillHints, contains(AutofillHints.password));
  });

  testWidgets('le champ téléphone n\'accepte que des chiffres', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).first, '69a9 11-22');
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, '6991122');
  });

  testWidgets('les identifiants sont groupés pour la saisie automatique', (tester) async {
    await pump(tester);
    expect(find.byType(AutofillGroup), findsOneWidget);
  });
}
