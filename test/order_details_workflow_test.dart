// Widget tests for Order Details page: Next step, guards, tabs, SKU link.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crm2/ui_v1/demo_data/demo_data.dart';
import 'package:crm2/ui_v1/pages/order_details/order_details_page.dart';

void main() {
  setUp(() {
    demoRepository.seed();
  });

  group('Order Details page', () {
    testWidgets('shows order number and Draft status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailsPage(
            payload: const OrderDetailsPayload(
              orderNo: 'ORD-1000',
              status: 'Draft',
              warehouse: 'WH-A',
              created: '2025-01-10',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ORD-1000'), findsOneWidget);
      expect(find.text('Draft'), findsWidgets);
    });

    testWidgets('Next step button advances Draft -> Released', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailsPage(
            payload: const OrderDetailsPayload(
              orderNo: 'ORD-1000',
              status: 'Draft',
              warehouse: 'WH-A',
              created: '2025-01-10',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Draft'), findsWidgets);
      final nextStepButton = find.widgetWithText(FilledButton, 'Next step');
      expect(nextStepButton, findsOneWidget);

      await tester.tap(nextStepButton);
      await tester.pumpAndSettle();

      expect(find.text('Released'), findsWidgets);
    });

    testWidgets('Lines tab shows SKU link (product linkage target)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailsPage(
            payload: const OrderDetailsPayload(
              orderNo: 'ORD-1000',
              status: 'Draft',
              warehouse: 'WH-A',
              created: '2025-01-10',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ORD-1000'), findsOneWidget);
      final linesTab = find.text('Lines');
      expect(linesTab, findsOneWidget);
      await tester.tap(linesTab);
      await tester.pumpAndSettle();

      expect(find.text('SKU-001'), findsWidgets);
    });

    testWidgets('On Hold order shows On Hold and Next step disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailsPage(
            payload: const OrderDetailsPayload(
              orderNo: 'ORD-1008',
              status: 'On Hold',
              warehouse: 'WH-A',
              created: '2025-01-10',
              baseStatus: 'Allocated',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('On Hold'), findsWidgets);
      final nextStepButton = find.widgetWithText(FilledButton, 'Next step');
      expect(nextStepButton, findsOneWidget);
      final filledButton = tester.widget<FilledButton>(nextStepButton);
      expect(filledButton.onPressed, isNull);
    });

    testWidgets('Events tab shows timeline', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailsPage(
            payload: const OrderDetailsPayload(
              orderNo: 'ORD-1000',
              status: 'Draft',
              warehouse: 'WH-A',
              created: '2025-01-10',
              initialTabIndex: 3,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Events'), findsOneWidget);
      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();

      expect(find.text('Created'), findsOneWidget);
    });
  });
}
