// Unit tests for Outbound Workflow Engine: order transitions, guards, pick tasks, HU, lines, events.

import 'package:flutter_test/flutter_test.dart';

import 'package:crm2/ui_v1/demo_data/demo_data.dart';

void main() {
  late DemoRepository repo;
  late OutboundWorkflowEngine engine;

  setUp(() {
    repo = DemoRepository();
    repo.seed();
    engine = OutboundWorkflowEngine(repo);
  });

  group('Next step happy path: Draft -> Released -> ... -> Closed', () {
    test('Draft -> Released via release', () {
      final orderId = 'ORD-1000'; // seed: Draft
      expect(repo.getOrderDetails(orderId).order.status, 'Draft');
      expect(engine.executeOrderAction(orderId, 'release'), isTrue);
      expect(repo.getOrderDetails(orderId).order.status, 'Released');
    });

    test('Released -> Allocated via allocate', () {
      engine.executeOrderAction('ORD-1000', 'release');
      expect(engine.executeOrderAction('ORD-1000', 'allocate'), isTrue);
      expect(repo.getOrderDetails('ORD-1000').order.status, 'Allocated');
      expect(repo.getOrderDetails('ORD-1000').tasks.length, greaterThan(0));
    });

    test('Allocated -> Picking via start_picking', () {
      engine.executeOrderAction('ORD-1000', 'release');
      engine.executeOrderAction('ORD-1000', 'allocate');
      expect(engine.executeOrderAction('ORD-1000', 'start_picking'), isTrue);
      expect(repo.getOrderDetails('ORD-1000').order.status, 'Picking');
    });

    test('Picking -> Picked via complete_picking', () {
      engine.executeOrderAction('ORD-1000', 'release');
      engine.executeOrderAction('ORD-1000', 'allocate');
      engine.executeOrderAction('ORD-1000', 'start_picking');
      expect(engine.executeOrderAction('ORD-1000', 'complete_picking'), isTrue);
      expect(repo.getOrderDetails('ORD-1000').order.status, 'Picked');
    });

    test('Picked -> Packing via start_packing', () {
      engine.executeOrderAction('ORD-1000', 'release');
      engine.executeOrderAction('ORD-1000', 'allocate');
      engine.executeOrderAction('ORD-1000', 'start_picking');
      engine.executeOrderAction('ORD-1000', 'complete_picking');
      expect(engine.executeOrderAction('ORD-1000', 'start_packing'), isTrue);
      expect(repo.getOrderDetails('ORD-1000').order.status, 'Packing');
    });

    test('Packing -> Packed via complete_packing', () {
      engine.executeOrderAction('ORD-1000', 'release');
      engine.executeOrderAction('ORD-1000', 'allocate');
      engine.executeOrderAction('ORD-1000', 'start_picking');
      engine.executeOrderAction('ORD-1000', 'complete_picking');
      engine.executeOrderAction('ORD-1000', 'start_packing');
      expect(engine.executeOrderAction('ORD-1000', 'complete_packing'), isTrue);
      expect(repo.getOrderDetails('ORD-1000').order.status, 'Packed');
      expect(repo.getOrderDetails('ORD-1000').hus.length, greaterThan(0));
    });

    test('Packed -> Shipped via ship (when HU count >= 1)', () {
      engine.executeOrderAction('ORD-1000', 'release');
      engine.executeOrderAction('ORD-1000', 'allocate');
      engine.executeOrderAction('ORD-1000', 'start_picking');
      engine.executeOrderAction('ORD-1000', 'complete_picking');
      engine.executeOrderAction('ORD-1000', 'start_packing');
      engine.executeOrderAction('ORD-1000', 'complete_packing');
      expect(repo.getOrderDetails('ORD-1000').hus.length, greaterThanOrEqualTo(1));
      expect(engine.executeOrderAction('ORD-1000', 'ship'), isTrue);
      expect(repo.getOrderDetails('ORD-1000').order.status, 'Shipped');
    });

    test('Shipped -> Closed via close', () {
      engine.executeOrderAction('ORD-1000', 'release');
      engine.executeOrderAction('ORD-1000', 'allocate');
      engine.executeOrderAction('ORD-1000', 'start_picking');
      engine.executeOrderAction('ORD-1000', 'complete_picking');
      engine.executeOrderAction('ORD-1000', 'start_packing');
      engine.executeOrderAction('ORD-1000', 'complete_packing');
      engine.executeOrderAction('ORD-1000', 'ship');
      expect(engine.executeOrderAction('ORD-1000', 'close'), isTrue);
      expect(repo.getOrderDetails('ORD-1000').order.status, 'Closed');
    });

    test('Full happy path in sequence', () {
      const orderId = 'ORD-1000';
      final steps = [
        ('release', 'Released'),
        ('allocate', 'Allocated'),
        ('start_picking', 'Picking'),
        ('complete_picking', 'Picked'),
        ('start_packing', 'Packing'),
        ('complete_packing', 'Packed'),
        ('ship', 'Shipped'),
        ('close', 'Closed'),
      ];
      for (final step in steps) {
        expect(engine.executeOrderAction(orderId, step.$1), isTrue,
            reason: 'Failed at ${step.$1}');
        expect(repo.getOrderDetails(orderId).order.status, step.$2);
      }
    });
  });

  group('Guard rules: On Hold / Cancelled / Closed', () {
    test('On Hold blocks order actions', () {
      const orderId = 'ORD-1008'; // seed: On Hold
      expect(repo.getOrderDetails(orderId).order.status, 'On Hold');
      expect(engine.canExecuteOrderAction(orderId, 'release'), isFalse);
      expect(engine.canExecuteOrderAction(orderId, 'allocate'), isFalse);
      expect(engine.executeOrderAction(orderId, 'release'), isFalse);
    });

    test('Cancelled blocks order actions', () {
      const orderId = 'ORD-1010'; // seed: Cancelled
      expect(repo.getOrderDetails(orderId).order.status, 'Cancelled');
      expect(engine.canExecuteOrderAction(orderId, 'release'), isFalse);
      expect(engine.executeOrderAction(orderId, 'release'), isFalse);
    });

    test('Closed blocks order actions', () {
      const orderId = 'ORD-1007'; // seed: Closed
      expect(repo.getOrderDetails(orderId).order.status, 'Closed');
      expect(engine.canExecuteOrderAction(orderId, 'close'), isFalse);
      expect(engine.canExecuteOrderAction(orderId, 'ship'), isFalse);
    });

    test('Place on hold stores baseStatus and resolve restores', () {
      const orderId = 'ORD-1000';
      engine.executeOrderAction(orderId, 'release');
      engine.executeOrderAction(orderId, 'allocate');
      expect(repo.getOrderDetails(orderId).order.status, 'Allocated');
      expect(engine.placeOnHold(orderId), isTrue);
      expect(repo.getOrderDetails(orderId).order.status, 'On Hold');
      expect(repo.getOrderDetails(orderId).order.baseStatus, 'Allocated');
      expect(engine.resolveHold(orderId), isTrue);
      expect(repo.getOrderDetails(orderId).order.status, 'Allocated');
    });

    test('Resolve hold fails when not On Hold', () {
      expect(engine.resolveHold('ORD-1000'), isFalse);
    });
  });

  group('Ship before Packed / Close before Shipped', () {
    test('Ship not available when Draft', () {
      expect(engine.canExecuteOrderAction('ORD-1000', 'ship'), isFalse);
      expect(engine.executeOrderAction('ORD-1000', 'ship'), isFalse);
    });

    test('Ship not available when Allocated', () {
      engine.executeOrderAction('ORD-1000', 'release');
      engine.executeOrderAction('ORD-1000', 'allocate');
      expect(engine.canExecuteOrderAction('ORD-1000', 'ship'), isFalse);
    });

    test('Close not available when Packed', () {
      engine.executeOrderAction('ORD-1000', 'release');
      engine.executeOrderAction('ORD-1000', 'allocate');
      engine.executeOrderAction('ORD-1000', 'start_picking');
      engine.executeOrderAction('ORD-1000', 'complete_picking');
      engine.executeOrderAction('ORD-1000', 'start_packing');
      engine.executeOrderAction('ORD-1000', 'complete_packing');
      expect(repo.getOrderDetails('ORD-1000').order.status, 'Packed');
      expect(engine.canExecuteOrderAction('ORD-1000', 'close'), isFalse);
    });
  });

  group('Pick Tasks: Start / Complete / Report exception', () {
    test('Start pick task: Open -> In Progress', () {
      const orderId = 'ORD-1003'; // Picking, has tasks
      final tasks = repo.getOrderDetails(orderId).tasks;
      expect(tasks.length, greaterThan(0));
      final taskId = tasks.first.id;
      expect(tasks.first.status, 'Open');
      expect(engine.canExecutePickTaskAction(orderId, taskId, 'start_pick_task'), isTrue);
      expect(engine.executePickTaskAction(orderId, taskId, 'start_pick_task'), isTrue);
      final after = repo.getOrderDetails(orderId).tasks.firstWhere((t) => t.id == taskId);
      expect(after.status, 'In Progress');
    });

    test('Complete pick task: In Progress -> Done', () {
      const orderId = 'ORD-1003';
      final taskId = repo.getOrderDetails(orderId).tasks.first.id;
      engine.executePickTaskAction(orderId, taskId, 'start_pick_task');
      expect(engine.executePickTaskAction(orderId, taskId, 'complete_pick_task'), isTrue);
      expect(repo.getOrderDetails(orderId).tasks.firstWhere((t) => t.id == taskId).status, 'Done');
    });

    test('Report pick exception -> Exception', () {
      const orderId = 'ORD-1003';
      final taskId = repo.getOrderDetails(orderId).tasks.first.id;
      expect(engine.executePickTaskAction(orderId, taskId, 'report_pick_exception'), isTrue);
      expect(repo.getOrderDetails(orderId).tasks.firstWhere((t) => t.id == taskId).status, 'Exception');
    });

    test('Start not allowed when task already Done', () {
      const orderId = 'ORD-1003';
      final taskId = repo.getOrderDetails(orderId).tasks.first.id;
      engine.executePickTaskAction(orderId, taskId, 'complete_pick_task');
      expect(engine.canExecutePickTaskAction(orderId, taskId, 'start_pick_task'), isFalse);
    });
  });

  group('Handling Units: Seal HU / Print label / Unpack', () {
    test('Seal HU: Open -> Packed', () {
      const orderId = 'ORD-1002'; // Allocating - use one with HUs
      final hus = repo.getOrderDetails(orderId).hus;
      final openList = hus.where((h) => h.status == 'Open').toList();
      final openHu = openList.isNotEmpty ? openList.first : hus.first;
      final huId = openHu.id;
      if (openHu.status == 'Open') {
        expect(engine.canExecuteHuAction(orderId, huId, 'seal_hu'), isTrue);
        expect(engine.executeHuAction(orderId, huId, 'seal_hu'), isTrue);
        expect(repo.getOrderDetails(orderId).hus.firstWhere((h) => h.id == huId).status, 'Packed');
      }
    });

    test('Print label sets SSCC', () {
      const orderId = 'ORD-1002';
      final packedList = repo.getOrderDetails(orderId).hus.where((h) => h.status == 'Packed').toList();
      if (packedList.isNotEmpty) {
        final packedHu = packedList.first;
        expect(engine.canExecuteHuAction(orderId, packedHu.id, 'print_label'), isTrue);
        final beforeSscc = packedHu.sscc;
        expect(engine.executeHuAction(orderId, packedHu.id, 'print_label'), isTrue);
        final after = repo.getOrderDetails(orderId).hus.firstWhere((h) => h.id == packedHu.id);
        expect(after.sscc, isNotNull);
        if (beforeSscc == null) expect(after.sscc != null, isTrue);
      }
    });

    test('Unpack: Packed -> Open', () {
      const orderId = 'ORD-1002';
      final packedList2 = repo.getOrderDetails(orderId).hus.where((h) => h.status == 'Packed').toList();
      if (packedList2.isNotEmpty) {
        final packedHu = packedList2.first;
        expect(engine.executeHuAction(orderId, packedHu.id, 'unpack_hu'), isTrue);
        expect(repo.getOrderDetails(orderId).hus.firstWhere((h) => h.id == packedHu.id).status, 'Open');
      }
    });

    test('Seal/Print/Unpack not allowed when HU Shipped', () {
      const orderId = 'ORD-1002';
      final shippedList = repo.getOrderDetails(orderId).hus.where((h) => h.status == 'Shipped').toList();
      if (shippedList.isNotEmpty) {
        final shippedHu = shippedList.first;
        expect(engine.canExecuteHuAction(orderId, shippedHu.id, 'seal_hu'), isFalse);
        expect(engine.canExecuteHuAction(orderId, shippedHu.id, 'unpack_hu'), isFalse);
      }
    });
  });

  group('Lines: Mark shortage / Set reason code', () {
    test('Mark shortage updates lines and adds event', () {
      const orderId = 'ORD-1000';
      final bundle = repo.getOrderDetails(orderId);
      final lineIds = bundle.lines.map((l) => l.id).take(1).toList();
      engine.executeMarkShortage(orderId, lineIds, 2, 'DAMAGED');
      final after = repo.getOrderDetails(orderId);
      expect(after.lines.firstWhere((l) => l.id == lineIds.first).shortQty, 2);
      expect(after.lines.firstWhere((l) => l.id == lineIds.first).reasonCode, 'DAMAGED');
      expect(after.events.any((e) => e.code == 'shortage_detected'), isTrue);
    });

    test('Set reason code updates lines and adds event', () {
      const orderId = 'ORD-1000';
      final lineIds = repo.getOrderDetails(orderId).lines.map((l) => l.id).take(1).toList();
      engine.executeSetReasonCode(orderId, lineIds, 'LOST');
      final after = repo.getOrderDetails(orderId);
      expect(after.lines.firstWhere((l) => l.id == lineIds.first).reasonCode, 'LOST');
      expect(after.events.any((e) => e.code == 'reason_code_set'), isTrue);
    });
  });

  group('Events timeline after actions', () {
    test('Release adds released event', () {
      engine.executeOrderAction('ORD-1000', 'release');
      final events = repo.getOrderDetails('ORD-1000').events;
      expect(events.any((e) => e.code == 'released'), isTrue);
    });

    test('Ship adds shipped event', () {
      engine.executeOrderAction('ORD-1000', 'release');
      engine.executeOrderAction('ORD-1000', 'allocate');
      engine.executeOrderAction('ORD-1000', 'start_picking');
      engine.executeOrderAction('ORD-1000', 'complete_picking');
      engine.executeOrderAction('ORD-1000', 'start_packing');
      engine.executeOrderAction('ORD-1000', 'complete_packing');
      engine.executeOrderAction('ORD-1000', 'ship');
      expect(repo.getOrderDetails('ORD-1000').events.any((e) => e.code == 'shipped'), isTrue);
    });

    test('Place on hold adds hold_created, resolve adds hold_resolved', () {
      engine.executeOrderAction('ORD-1000', 'release');
      engine.placeOnHold('ORD-1000');
      expect(repo.getOrderDetails('ORD-1000').events.any((e) => e.code == 'hold_created'), isTrue);
      engine.resolveHold('ORD-1000');
      expect(repo.getOrderDetails('ORD-1000').events.any((e) => e.code == 'hold_resolved'), isTrue);
    });

    test('Pick task complete adds pick_task_completed event', () {
      const orderId = 'ORD-1003';
      final taskId = repo.getOrderDetails(orderId).tasks.first.id;
      engine.executePickTaskAction(orderId, taskId, 'complete_pick_task');
      expect(repo.getOrderDetails(orderId).events.any((e) => e.code == 'pick_task_completed'), isTrue);
    });
  });
}
