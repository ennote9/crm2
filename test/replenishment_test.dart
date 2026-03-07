// Tests for Replenishment: suggested qty, create movement, button disabled when suggestion = 0.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crm2/ui_v1/demo_data/demo_data.dart';
import 'package:crm2/ui_v1/pages/replenishment/replenishment_rule_details_page.dart';

void main() {
  setUp(() {
    demoRepository.seed();
  });

  group('Suggested replenishment qty', () {
    test('returns 0 when current at pick face >= minQty', () {
      final rule = demoRepository.getReplenishmentRules().first;
      final current = demoRepository.getReplenishmentRuleCurrentQty(rule);
      final suggested = demoRepository.getSuggestedReplenishmentQty(rule);
      if (current >= rule.minQty) {
        expect(suggested, 0);
      }
    });

    test('returns target - current when current < minQty', () {
      final rules = demoRepository.getReplenishmentRules();
      for (final rule in rules) {
        final current = demoRepository.getReplenishmentRuleCurrentQty(rule);
        final suggested = demoRepository.getSuggestedReplenishmentQty(rule);
        if (current < rule.minQty) {
          expect(suggested, (rule.targetQty - current).clamp(0, rule.targetQty));
        }
      }
    });
  });

  group('Create movement from rule', () {
    test('returns null when suggested qty is 0', () {
      final rule = demoRepository.getReplenishmentRules().first;
      final suggested = demoRepository.getSuggestedReplenishmentQty(rule);
      if (suggested == 0) {
        final movement = demoRepository.createMovementFromReplenishmentRule(rule);
        expect(movement, isNull);
      }
    });

    test('creates Draft replenishment movement when suggested > 0', () {
      final rules = demoRepository.getReplenishmentRules(filter: 'needs_replenishment');
      if (rules.isEmpty) return;
      final rule = rules.first;
      final suggested = demoRepository.getSuggestedReplenishmentQty(rule);
      expect(suggested, greaterThan(0));
      final beforeCount = demoRepository.getMovements().length;
      final movement = demoRepository.createMovementFromReplenishmentRule(rule);
      expect(movement, isNotNull);
      expect(movement!.status, 'Draft');
      expect(movement.movementType, DemoMovementType.replenishment);
      expect(movement.sku, rule.sku);
      expect(movement.fromLocation, rule.sourceLocation);
      expect(movement.toLocation, rule.pickFaceLocation);
      expect(movement.qty, suggested);
      expect(demoRepository.getMovements().length, beforeCount + 1);
    });
  });

  group('Replenishment Rule Details page', () {
    testWidgets('Create movement button disabled when suggestion = 0', (WidgetTester tester) async {
      final rules = demoRepository.getReplenishmentRules();
      DemoReplenishmentRule? ruleWithZero;
      for (final r in rules) {
        if (demoRepository.getSuggestedReplenishmentQty(r) == 0) {
          ruleWithZero = r;
          break;
        }
      }
      if (ruleWithZero == null) return;
      await tester.pumpWidget(
        MaterialApp(
          home: ReplenishmentRuleDetailsPage(
            payload: ReplenishmentRuleDetailsPayload(ruleId: ruleWithZero.id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final createButton = find.widgetWithText(FilledButton, 'Create movement');
      expect(createButton, findsOneWidget);
      final filledButton = tester.widget<FilledButton>(createButton);
      expect(filledButton.onPressed, isNull);
    });
  });
}
