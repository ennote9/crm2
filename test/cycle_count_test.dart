// Unit tests for Cycle Count: workflow transitions, variance, post adjustment, reason guard.

import 'package:flutter_test/flutter_test.dart';

import 'package:crm2/ui_v1/demo_data/demo_data.dart';

void main() {
  setUp(() {
    demoRepository.seed();
  });

  group('Count task list', () {
    test('getCountTasks returns seeded count tasks', () {
      final list = demoRepository.getCountTasks();
      expect(list.length, greaterThanOrEqualTo(1));
      expect(list.any((t) => t.status == 'Draft'), isTrue);
      expect(list.any((t) => t.status == 'Posted'), isTrue);
    });

    test('getCountTaskById returns task', () {
      final list = demoRepository.getCountTasks();
      final first = list.first;
      final t = demoRepository.getCountTaskById(first.id);
      expect(t, isNotNull);
      expect(t!.id, first.id);
      expect(t.countNo, first.countNo);
    });

    test('filter open returns Draft and Released only', () {
      final open = demoRepository.getCountTasks(filter: 'open');
      for (final t in open) {
        expect(['Draft', 'Released'], contains(t.status));
      }
    });

    test('filter variance_only returns only tasks with variance != 0', () {
      final varianceOnly = demoRepository.getCountTasks(filter: 'variance_only');
      for (final t in varianceOnly) {
        expect(t.countedQty, isNotNull);
        expect(t.varianceQty, isNot(equals(0)));
      }
    });
  });

  group('Variance calculation', () {
    test('varianceQty = countedQty - expectedQty', () {
      final tasks = demoRepository.getCountTasks().where((t) => t.countedQty != null).toList();
      for (final t in tasks) {
        expect(t.varianceQty, t.countedQty! - t.expectedQty);
      }
    });
  });

  group('Count task workflow', () {
    test('Draft -> Released via release', () {
      final draft = demoRepository.getCountTasks().where((t) => t.status == 'Draft').first;
      final err = demoRepository.applyCountAction(draft.id, 'release', actor: 'Tester');
      expect(err, isNull);
      final updated = demoRepository.getCountTaskById(draft.id);
      expect(updated!.status, 'Released');
      expect(updated.releasedAt, isNotNull);
      final events = demoRepository.getCountTaskEvents(draft.id);
      expect(events.any((e) => e.code == 'count_released'), isTrue);
    });

    test('Released -> Counted via count (with countedQty)', () {
      final released = demoRepository.getCountTasks().where((t) => t.status == 'Released').first;
      final countedQty = released.expectedQty + 2;
      final err = demoRepository.applyCountAction(
        released.id,
        'count',
        countedQty: countedQty,
        reasonCode: 'ADJ',
        actor: 'Tester',
      );
      expect(err, isNull);
      final updated = demoRepository.getCountTaskById(released.id);
      expect(updated!.status, 'Counted');
      expect(updated.countedQty, countedQty);
      expect(updated.varianceQty, 2);
      expect(updated.reasonCode, 'ADJ');
    });

    test('Counted -> Posted updates stock by location', () {
      final counted = demoRepository.getCountTasks().where((t) => t.status == 'Counted').first;
      final sku = counted.sku;
      final wh = counted.warehouse;
      final loc = counted.location;
      final lot = counted.lot;
      final countedQty = counted.countedQty!;

      final err = demoRepository.applyCountAction(counted.id, 'post', actor: 'Tester');
      expect(err, isNull);

      final updated = demoRepository.getCountTaskById(counted.id);
      expect(updated!.status, 'Posted');

      final invAfter = demoRepository.getInventoryBySku(sku);
      final bucket = invAfter.where((r) =>
          r.warehouse == wh && r.location == loc && r.sku == sku && r.lot == lot).toList();
      expect(bucket, isNotEmpty);
      expect(bucket.first.onHandQty, countedQty);
      expect(bucket.first.availableQty, lessThanOrEqualTo(countedQty));
    });

    test('Draft/Released/Counted -> Cancelled', () {
      final draft = demoRepository.getCountTasks().where((t) => t.status == 'Draft').first;
      final err = demoRepository.applyCountAction(draft.id, 'cancel', actor: 'Tester');
      expect(err, isNull);
      final c = demoRepository.getCountTaskById(draft.id);
      expect(c!.status, 'Cancelled');
      expect(demoRepository.getCountTaskEvents(draft.id).any((e) => e.code == 'count_cancelled'), isTrue);
    });
  });

  group('Count task guards', () {
    test('count fails when not Released', () {
      final draft = demoRepository.getCountTasks().where((t) => t.status == 'Draft').first;
      final err = demoRepository.applyCountAction(draft.id, 'count', countedQty: draft.expectedQty, actor: 'Tester');
      expect(err, isNotNull);
      expect(err!.toLowerCase(), contains('released'));
    });

    test('count fails when countedQty is negative', () {
      final released = demoRepository.getCountTasks().where((t) => t.status == 'Released').first;
      final err = demoRepository.applyCountAction(released.id, 'count', countedQty: -1, actor: 'Tester');
      expect(err, isNotNull);
      expect(err!.toLowerCase(), contains('negative'));
    });

    test('count fails when variance != 0 and reasonCode empty', () {
      final released = demoRepository.getCountTasks().where((t) => t.status == 'Released').first;
      final err = demoRepository.applyCountAction(
        released.id,
        'count',
        countedQty: released.expectedQty + 5,
        actor: 'Tester',
      );
      expect(err, isNotNull);
      expect(err!.toLowerCase(), contains('reason'));
    });

    test('post fails when not Counted', () {
      final released = demoRepository.getCountTasks().where((t) => t.status == 'Released').first;
      final err = demoRepository.applyCountAction(released.id, 'post', actor: 'Tester');
      expect(err, isNotNull);
      expect(err!.toLowerCase(), contains('counted'));
    });

    test('release fails when not Draft', () {
      final released = demoRepository.getCountTasks().where((t) => t.status == 'Released').first;
      final err = demoRepository.applyCountAction(released.id, 'release', actor: 'Tester');
      expect(err, isNotNull);
      expect(err!.toLowerCase(), contains('draft'));
    });
  });
}
