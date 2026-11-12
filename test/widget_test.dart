import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netscan/main.dart';

void main() {
  for (final language in ['en', 'it']) {
    for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
      testWidgets(
        'accessible scan form $language at $width without automatic requests',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            NetscanApp(
              locale: Locale(language),
              initialTab: 1,
              restoreInventory: false,
            ),
          );
          await tester.pumpAndSettle();
          final scan = find.byType(FilledButton).first;
          expect(tester.widget<FilledButton>(scan).onPressed, isNull);
          await tester.tap(find.byType(CheckboxListTile).first);
          await tester.pump();
          expect(tester.widget<FilledButton>(scan).onPressed, isNotNull);
          await tester.ensureVisible(scan);
          await tester.tap(scan);
          await tester.pump();
          final error = find.textContaining(
            language == 'en'
                ? 'Enter a private IPv4'
                : 'Inserisci un IP privato',
          );
          await tester.scrollUntilVisible(
            error,
            100,
            scrollable: find.byType(Scrollable).first,
          );
          expect(error, findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('language selection changes navigation labels', (tester) async {
    await tester.pumpWidget(
      const NetscanApp(locale: Locale('en'), restoreInventory: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('Devices'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Italiano'));
    await tester.pumpAndSettle();
    expect(find.text('Dispositivi'), findsOneWidget);
  });
}
