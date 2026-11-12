import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netscan/l10n/catalog.dart';
import 'package:netscan/ui/official_match.dart';

void main() {
  testWidgets(
    'changing confirmed firmware invalidates its advisory result and acknowledgement',
    (tester) async {
      final model = TextEditingController(text: 'ASUS RT-AX55');
      final firmware = TextEditingController(text: '3.0.0.4.386_50460');
      addTearDown(model.dispose);
      addTearDown(firmware.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OfficialMatch(
                model: model,
                firmware: firmware,
                open: (_) {},
                onMatch: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text(english['match.title']!));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.text(english['match.run']!));
      await tester.tap(find.text(english['match.run']!));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(english['match.affected']!),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(english['match.affected']!), findsOneWidget);
      firmware.text = '3.0.0.4.386_51948';
      await tester.pumpAndSettle();
      expect(find.text(english['match.affected']!), findsNothing);
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
    },
  );
}
