// Unit tests for Movements: workflow transitions, guards, stock-by-location on complete.

import 'package:flutter_test/flutter_test.dart';

import 'package:crm2/ui_v1/demo_data/demo_data.dart';

void main() {
  setUp(() {
    demoRepository.seed();
  });

  group('Movement workflow', () {
    test('getMovements returns seeded movements', () {
      final list = demoRepository.getMovements();
      expect(list.length, greaterThanOrEqualTo(1));
      expect(list.any((m) => m.status == 'Draft'), isTrue);
      expect(list.any((m) => m.status == 'Completed'), isTrue);
    });

    test('Draft -> Released via release', () {
      final draft = demoRepository.getMovements().where((m) => m.status == 'Draft').first;
      expect(draft.fromLocation, isNot(equals(draft.toLocation)));
      final err = demoRepository.applyMovementAction(draft.id, 'release', 'Tester');
      expect(err, isNull);
      final updated = demoRepository.getMovementById(draft.id);
      expect(updated!.status, 'Released');
      expect(updated.releasedAt, isNotNull);
      final events = demoRepository.getMovementEvents(draft.id);
      expect(events.any((e) => e.code == 'movement_released'), isTrue);
    });

    test('Released -> In Progress via start', () {
      final released = demoRepository.getMovements().where((m) => m.status == 'Released').first;
      final err = demoRepository.applyMovementAction(released.id, 'start', 'Tester');
      expect(err, isNull);
      final updated = demoRepository.getMovementById(released.id);
      expect(updated!.status, 'In Progress');
    });

    test('In Progress -> Completed updates stock by location', () {
      final inProgress = demoRepository.getMovements().where((m) => m.status == 'In Progress').first;
      final sku = inProgress.sku;
      final wh = inProgress.warehouse;
      final fromLoc = inProgress.fromLocation;
      final toLoc = inProgress.toLocation;
      final qty = inProgress.qty;

      final invBefore = demoRepository.getInventoryBySku(sku);
      final fromBefore = invBefore.where((r) => r.warehouse == wh && r.location == fromLoc).fold<int>(0, (s, r) => s + r.availableQty);
      final toBefore = invBefore.where((r) => r.warehouse == wh && r.location == toLoc).fold<int>(0, (s, r) => s + r.availableQty);

      final err = demoRepository.applyMovementAction(inProgress.id, 'complete', 'Tester');
      expect(err, isNull);

      final updated = demoRepository.getMovementById(inProgress.id);
      expect(updated!.status, 'Completed');
      expect(updated.movedQty, qty);

      final invAfter = demoRepository.getInventoryBySku(sku);
      final fromAfter = invAfter.where((r) => r.warehouse == wh && r.location == fromLoc).fold<int>(0, (s, r) => s + r.availableQty);
      final toAfter = invAfter.where((r) => r.warehouse == wh && r.location == toLoc).fold<int>(0, (s, r) => s + r.availableQty);

      expect(fromAfter, fromBefore - qty);
      expect(toAfter, toBefore + qty);
    });

    test('Draft/Released/In Progress -> Cancelled', () {
      final draft = demoRepository.getMovements().where((m) => m.status == 'Draft').first;
      demoRepository.applyMovementAction(draft.id, 'cancel', 'Tester');
      final c = demoRepository.getMovementById(draft.id);
      expect(c!.status, 'Cancelled');
    });
  });

  group('Movement guards', () {
    test('release fails when fromLocation == toLocation', () {
      final draft = demoRepository.getMovements().where((m) => m.status == 'Draft').first;
      demoRepository.updateMovement(draft.copyWith(fromLocation: draft.toLocation, toLocation: draft.toLocation));
      final err = demoRepository.applyMovementAction(draft.id, 'release', 'Tester');
      expect(err, isNotNull);
      expect(err!.toLowerCase(), contains('differ'));
    });

    test('start fails when not Released', () {
      final draft = demoRepository.getMovements().where((m) => m.status == 'Draft').first;
      final err = demoRepository.applyMovementAction(draft.id, 'start', 'Tester');
      expect(err, isNotNull);
      expect(err!.toLowerCase(), contains('released'));
    });

    test('complete fails when not In Progress', () {
      final released = demoRepository.getMovements().where((m) => m.status == 'Released').first;
      final err = demoRepository.applyMovementAction(released.id, 'complete', 'Tester');
      expect(err, isNotNull);
      expect(err!.toLowerCase(), contains('in progress'));
    });

    test('complete fails when insufficient source stock', () {
      final inProgress = demoRepository.getMovements().where((m) => m.status == 'In Progress').first;
      demoRepository.updateMovement(inProgress.copyWith(qty: 99999));
      final err = demoRepository.applyMovementAction(inProgress.id, 'complete', 'Tester');
      expect(err, isNotNull);
    });
  });
}
