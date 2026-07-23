import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/shared/widgets/gradient_button.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('GradientButton', () {
    testWidgets('renders its label', (tester) async {
      await tester.pumpWidget(_wrap(
        GradientButton(label: 'Valider', onPressed: () {}),
      ));
      expect(find.text('Valider'), findsOneWidget);
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(
        GradientButton(label: 'Valider', onPressed: () => taps++),
      ));
      await tester.tap(find.text('Valider'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('does not invoke onPressed when disabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(
        GradientButton(
          label: 'Valider',
          onPressed: () => taps++,
          disabled: true,
        ),
      ));
      await tester.tap(find.text('Valider'));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('shows a progress indicator and blocks taps while loading',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(
        GradientButton(
          label: 'Valider',
          onPressed: () => taps++,
          isLoading: true,
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Valider'), findsNothing);
      await tester.tap(find.byType(GradientButton));
      await tester.pump();
      expect(taps, 0);
    });
  });
}
