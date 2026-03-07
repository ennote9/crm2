// Widget tests for Movement Details page: header, sections, next step.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crm2/ui_v1/demo_data/demo_data.dart';
import 'package:crm2/ui_v1/pages/movements/movement_details_page.dart';

void main() {
  setUp(() {
    demoRepository.seed();
  });

  group('Movement Details page', () {
    testWidgets('shows movement number and status', (WidgetTester tester) async {
      final draft = demoRepository.getMovements().where((m) => m.status == 'Draft').first;
      await tester.pumpWidget(
        MaterialApp(
          home: MovementDetailsPage(
            payload: MovementDetailsPayload(movementId: draft.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(draft.movementNo), findsWidgets);
      expect(find.text('Draft'), findsWidgets);
    });

    testWidgets('Next step (Release) advances Draft -> Released', (WidgetTester tester) async {
      final draft = demoRepository.getMovements().where((m) => m.status == 'Draft').first;
      await tester.pumpWidget(
        MaterialApp(
          home: MovementDetailsPage(
            payload: MovementDetailsPayload(movementId: draft.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Draft'), findsWidgets);
      final releaseButton = find.widgetWithText(FilledButton, 'Release');
      expect(releaseButton, findsOneWidget);

      await tester.tap(releaseButton);
      await tester.pumpAndSettle();

      expect(find.text('Released'), findsWidgets);
    });

    testWidgets('shows Summary and Events sections', (WidgetTester tester) async {
      final m = demoRepository.getMovements().first;
      await tester.pumpWidget(
        MaterialApp(
          home: MovementDetailsPage(
            payload: MovementDetailsPayload(movementId: m.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
    });
  });
}
