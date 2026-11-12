import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netscan/main.dart';

void main() {
  for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
    testWidgets(
      'usable initial state at width $width without accidental requests',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const NetscanApp());
        expect(find.text('Conosci meglio la tua rete.'), findsOneWidget);
        final scanButton = tester.widget<FilledButton>(
          find.byType(FilledButton).first,
        );
        expect(scanButton.onPressed, isNull);
        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pump();
        expect(
          tester
              .widget<FilledButton>(find.byType(FilledButton).first)
              .onPressed,
          isNotNull,
        );
        await tester.ensureVisible(find.text('Controlla dispositivo'));
        await tester.tap(find.text('Controlla dispositivo'));
        await tester.pump();
        await tester.scrollUntilVisible(find.textContaining('Inserisci un IP privato'), 100);
        expect(find.textContaining('Inserisci un IP privato'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
