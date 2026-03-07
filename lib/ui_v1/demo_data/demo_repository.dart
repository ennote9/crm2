// In-memory demo repository: orders, lines, HU, events, pick tasks.

import '../pages/order_details/order_actions_model.dart';
import 'demo_document_preview.dart';
import 'demo_event.dart';
import 'demo_handling_unit.dart';
import 'demo_inventory.dart';
import 'demo_order.dart';
import 'demo_order_line.dart';
import 'demo_orders_filters.dart';
import 'demo_movement.dart';
import 'demo_pick_task.dart';
import 'demo_packing_task.dart';
import 'demo_product.dart';
import 'demo_count_task.dart';
import 'demo_replenishment_rule.dart';

/// Bundle returned by [DemoRepository.getOrderDetails].
class DemoOrderDetailsBundle {
  const DemoOrderDetailsBundle({
    required this.order,
    required this.lines,
    required this.hus,
    required this.events,
    required this.tasks,
    required this.actionsUi,
  });
  final DemoOrder order;
  final List<DemoOrderLine> lines;
  final List<DemoHandlingUnit> hus;
  final List<DemoEvent> events;
  final List<DemoPickTask> tasks;
  final OrderActionsUi actionsUi;
}

/// In-memory repository for demo data. Mutations update stored state.
class DemoRepository {
  DemoRepository() {
    _orders = {};
    _lines = {};
    _hus = {};
    _events = {};
    _tasks = {};
    _products = {};
    _productIdBySku = {};
    _inventory = {};
    _orderReservations = {};
    _orderReservationBuckets = {};
    _movements = {};
    _movementEvents = {};
    _replenishmentRules = {};
    _countTasks = {};
    _countTaskEvents = {};
  }

  late Map<String, DemoOrder> _orders;
  late Map<String, List<DemoOrderLine>> _lines;
  late Map<String, List<DemoHandlingUnit>> _hus;
  late Map<String, List<DemoEvent>> _events;
  late Map<String, List<DemoPickTask>> _tasks;
  late Map<String, DemoProduct> _products;
  late Map<String, String> _productIdBySku;
  /// Key: '$warehouse|$location|${lot ?? ""}|$sku'. Location/lot-level buckets.
  late Map<String, DemoInventoryRecord> _inventory;
  /// orderId -> sku -> reserved qty (total).
  late Map<String, Map<String, int>> _orderReservations;
  /// orderId -> sku -> [(bucketKey, qty)] for pick/pack/ship to update same buckets.
  late Map<String, Map<String, List<(String, int)>>> _orderReservationBuckets;
  late Map<String, DemoMovement> _movements;
  late Map<String, List<DemoEvent>> _movementEvents;
  late Map<String, DemoReplenishmentRule> _replenishmentRules;
  late Map<String, DemoCountTask> _countTasks;
  late Map<String, List<DemoEvent>> _countTaskEvents;

  static String _invBucketKey(String warehouse, String location, String? lot, String sku) =>
      '$warehouse|$location|${lot ?? ""}|$sku';

  /// Populate with initial demo data.
  void seed() {
    _seedProducts();
    _seedInventory();
    _seedMovements();
    _seedReplenishmentRules();
    _seedCountTasks();
    final statuses = [
      'Draft', 'Released', 'Allocating', 'Picking', 'Packing', 'Packed',
      'Shipped', 'Closed', 'On Hold', 'Shortage', 'Cancelled', 'Allocated',
    ];
    final warehouses = ['WH-A', 'WH-B', 'WH-C'];
    for (var i = 0; i < 15; i++) {
      final id = 'ORD-${1000 + i}';
      final order = DemoOrder(
        id: id,
        orderNo: id,
        status: statuses[i % statuses.length],
        warehouse: warehouses[i % warehouses.length],
        createdAt: '2025-0${(i % 9) + 1}-${10 + (i % 20)}',
      );
      _orders[id] = order;
      _lines[id] = _seedLines();
      _hus[id] = id == 'ORD-1001' ? [] : _seedHus(id);
      _events[id] = _seedEvents(id);
      final s = order.status.toLowerCase();
      if (s == 'allocated' || s == 'picking' || s == 'picked' || s == 'packing' ||
          s == 'packed' || s == 'shipped' || s == 'closed') {
        _tasks[id] = _pickTasksFromLines(_lines[id]!, id);
      } else {
        _tasks[id] = [];
      }
    }
  }

  void _seedProducts() {
    final list = [
      DemoProduct(
        productId: 'prd-001',
        sku: 'SKU-001',
        productName: 'Product A',
        gtin14: '05012345678901',
        brand: 'Brand Alpha',
        category: 'Electronics',
        status: 'Active',
        baseUom: 'EA',
        sellingUom: 'EA',
        orderingUom: 'PCS',
        barcodePrimary: '5012345678901',
        barcodeSecondary: null,
        requiresLotTracking: false,
        requiresSerialTracking: false,
        requiresExpiryTracking: false,
        shelfLifeDays: null,
        bestBeforeDays: null,
        countryOfOrigin: 'DE',
        netWeight: 0.5,
        grossWeight: 0.6,
        length: 10,
        width: 8,
        height: 5,
        unitsPerCase: 12,
        casesPerLayer: 5,
        layersPerPallet: 4,
        storageCondition: 'Ambient',
        hazardousFlag: false,
        notes: null,
      ),
      DemoProduct(
        productId: 'prd-002',
        sku: 'SKU-002',
        productName: 'Product B',
        gtin14: '05012345678902',
        brand: 'Brand Beta',
        category: 'Consumables',
        status: 'Active',
        baseUom: 'EA',
        sellingUom: 'EA',
        orderingUom: 'EA',
        barcodePrimary: '5012345678902',
        barcodeSecondary: ['5012345678902-2'],
        requiresLotTracking: true,
        requiresSerialTracking: false,
        requiresExpiryTracking: true,
        shelfLifeDays: 365,
        bestBeforeDays: 180,
        countryOfOrigin: 'PL',
        netWeight: 1.2,
        grossWeight: 1.3,
        length: 15,
        width: 10,
        height: 6,
        unitsPerCase: 6,
        storageCondition: 'Chilled',
        hazardousFlag: false,
        notes: null,
      ),
      DemoProduct(
        productId: 'prd-003',
        sku: 'SKU-003',
        productName: 'Product C',
        gtin14: '05012345678903',
        brand: 'Brand Alpha',
        category: 'Electronics',
        status: 'Active',
        baseUom: 'PCS',
        sellingUom: 'PCS',
        orderingUom: 'PCS',
        barcodePrimary: '5012345678903',
        barcodeSecondary: null,
        requiresLotTracking: true,
        requiresSerialTracking: true,
        requiresExpiryTracking: false,
        shelfLifeDays: null,
        bestBeforeDays: null,
        netWeight: 2.0,
        grossWeight: 2.2,
        length: 20,
        width: 12,
        height: 8,
        unitsPerCase: 1,
        storageCondition: 'Ambient',
        hazardousFlag: false,
        notes: null,
      ),
      DemoProduct(
        productId: 'prd-004',
        sku: 'SKU-004',
        productName: 'Product D',
        gtin14: '05012345678904',
        brand: 'Brand Gamma',
        category: 'Food',
        status: 'Active',
        baseUom: 'EA',
        sellingUom: 'EA',
        orderingUom: 'EA',
        barcodePrimary: '5012345678904',
        barcodeSecondary: null,
        requiresLotTracking: true,
        requiresSerialTracking: false,
        requiresExpiryTracking: true,
        shelfLifeDays: 90,
        bestBeforeDays: 30,
        countryOfOrigin: 'FR',
        netWeight: 0.3,
        length: 12,
        width: 10,
        height: 4,
        unitsPerCase: 24,
        casesPerLayer: 8,
        layersPerPallet: 6,
        storageCondition: 'Frozen',
        hazardousFlag: false,
        notes: null,
      ),
      DemoProduct(
        productId: 'prd-005',
        sku: 'SKU-005',
        productName: 'Product E',
        gtin14: '05012345678905',
        brand: 'Brand Beta',
        category: 'Consumables',
        status: 'Inactive',
        baseUom: 'EA',
        sellingUom: 'EA',
        orderingUom: 'EA',
        barcodePrimary: '5012345678905',
        barcodeSecondary: null,
        requiresLotTracking: false,
        requiresSerialTracking: false,
        requiresExpiryTracking: true,
        shelfLifeDays: 60,
        bestBeforeDays: 14,
        netWeight: 0.4,
        length: 8,
        width: 6,
        height: 3,
        unitsPerCase: 12,
        storageCondition: 'Chilled',
        hazardousFlag: false,
        notes: 'Discontinued line',
      ),
    ];
    _products = { for (final p in list) p.productId : p };
    _productIdBySku = { for (final p in list) p.sku : p.productId };
  }

  void _seedInventory() {
    const warehouses = ['WH-A', 'WH-B', 'WH-C'];
    const skus = ['SKU-001', 'SKU-002', 'SKU-003', 'SKU-004', 'SKU-005'];
    // Buckets: (warehouse, location, lot?, sku, onHand, expiry?)
    final buckets = <({String wh, String loc, String? lot, String sku, int qty, String? expiry})>[];
    for (final wh in warehouses) {
      for (final sku in skus) {
        if (wh == 'WH-A') {
          buckets.add((wh: wh, loc: 'A-01-02', lot: 'LOT-001', sku: sku, qty: 40, expiry: sku == 'SKU-002' || sku == 'SKU-004' ? '2025-12-31' : null));
          buckets.add((wh: wh, loc: 'A-02-01', lot: 'LOT-002', sku: sku, qty: 60, expiry: sku == 'SKU-002' || sku == 'SKU-004' ? '2026-01-15' : null));
          buckets.add((wh: wh, loc: 'A-01-03', lot: null, sku: sku, qty: 100, expiry: null));
        } else if (wh == 'WH-B') {
          buckets.add((wh: wh, loc: 'B-01-01', lot: null, sku: sku, qty: 120, expiry: null));
          buckets.add((wh: wh, loc: 'B-02-02', lot: 'LOT-003', sku: sku, qty: 80, expiry: sku == 'SKU-004' ? '2025-11-30' : null));
        } else {
          buckets.add((wh: wh, loc: 'C-03-04', lot: 'LOT-003', sku: sku, qty: 100, expiry: sku == 'SKU-005' ? '2025-10-01' : null));
          buckets.add((wh: wh, loc: 'C-01-01', lot: null, sku: sku, qty: 100, expiry: null));
        }
      }
    }
    for (final b in buckets) {
      final productId = _productIdBySku[b.sku] ?? b.sku;
      final key = _invBucketKey(b.wh, b.loc, b.lot, b.sku);
      _inventory[key] = DemoInventoryRecord(
        productId: productId,
        sku: b.sku,
        warehouse: b.wh,
        location: b.loc,
        lot: b.lot,
        onHandQty: b.qty,
        availableQty: b.qty,
        reservedQty: 0,
        pickedQty: 0,
        packedQty: 0,
        shippedQty: 0,
        expiryDate: b.expiry,
      );
    }
  }

  void _seedMovements() {
    final types = [DemoMovementType.replenishment, DemoMovementType.relocation, DemoMovementType.transfer];
    final statuses = ['Draft', 'Draft', 'Released', 'Released', 'In Progress', 'Completed', 'Completed', 'Cancelled'];
    final baseDate = DateTime.utc(2025, 2, 1);
    for (var i = 0; i < 12; i++) {
      final id = 'MOV-${100 + i}';
      final status = statuses[i % statuses.length];
      final sku = i < 5 ? 'SKU-00${i + 1}' : 'SKU-001';
      final productName = getProductBySku(sku)?.productName ?? 'Product';
      final wh = i % 3 == 0 ? 'WH-A' : (i % 3 == 1 ? 'WH-B' : 'WH-C');
      final fromLoc = wh == 'WH-A' ? 'A-01-02' : (wh == 'WH-B' ? 'B-01-01' : 'C-03-04');
      final toLoc = wh == 'WH-A' ? 'A-01-03' : (wh == 'WH-B' ? 'B-02-02' : 'C-01-01');
      final createdAt = baseDate.add(Duration(days: i));
      final m = DemoMovement(
        id: id,
        movementNo: id,
        warehouse: wh,
        movementType: types[i % types.length],
        sku: sku,
        productName: productName,
        fromLocation: fromLoc,
        toLocation: toLoc,
        qty: 10 + (i % 5) * 5,
        movedQty: status == 'Completed' ? 10 + (i % 5) * 5 : (status == 'In Progress' ? 5 : 0),
        status: status,
        createdAt: '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}',
        releasedAt: status != 'Draft' ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}' : null,
        startedAt: (status == 'In Progress' || status == 'Completed') ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}' : null,
        completedAt: status == 'Completed' ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}' : null,
        cancelledAt: status == 'Cancelled' ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}' : null,
        actor: status != 'Draft' ? 'Demo User' : null,
      );
      _movements[id] = m;
      _movementEvents[id] = _seedMovementEvents(id, m);
    }
  }

  List<DemoEvent> _seedMovementEvents(String movementId, DemoMovement m) {
    final base = DateTime.utc(2025, 2, 1, 8, 0);
    final list = <DemoEvent>[
      DemoEvent(id: 'ME-$movementId-0', code: 'movement_created', occurredAt: base, actor: 'system', category: DemoEventCategory.system, payload: 'Movement created'),
    ];
    if (m.status != 'Draft') {
      list.add(DemoEvent(id: 'ME-$movementId-1', code: 'movement_released', occurredAt: base.add(const Duration(hours: 1)), actor: m.actor ?? 'system', category: DemoEventCategory.workflow, payload: 'Released'));
    }
    if (m.status == 'In Progress' || m.status == 'Completed') {
      list.add(DemoEvent(id: 'ME-$movementId-2', code: 'movement_started', occurredAt: base.add(const Duration(hours: 2)), actor: m.actor ?? 'system', category: DemoEventCategory.workflow, payload: 'Started'));
    }
    if (m.status == 'Completed') {
      list.add(DemoEvent(id: 'ME-$movementId-3', code: 'movement_completed', occurredAt: base.add(const Duration(hours: 3)), actor: m.actor ?? 'system', category: DemoEventCategory.workflow, payload: 'Completed'));
    }
    if (m.status == 'Cancelled') {
      list.add(DemoEvent(id: 'ME-$movementId-4', code: 'movement_cancelled', occurredAt: base.add(const Duration(hours: 1)), actor: m.actor ?? 'system', category: DemoEventCategory.workflow, payload: 'Cancelled'));
    }
    list.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return list;
  }

  void _seedReplenishmentRules() {
    final baseDate = DateTime.utc(2025, 2, 1);
    // Rules: pick face <- source; use existing inventory locations
    final rules = [
      (pick: 'A-01-03', source: 'A-01-02', wh: 'WH-A', sku: 'SKU-001', min: 20, target: 50),
      (pick: 'A-01-03', source: 'A-02-01', wh: 'WH-A', sku: 'SKU-002', min: 10, target: 30),
      (pick: 'B-02-02', source: 'B-01-01', wh: 'WH-B', sku: 'SKU-001', min: 15, target: 40),
      (pick: 'B-02-02', source: 'B-01-01', wh: 'WH-B', sku: 'SKU-003', min: 5, target: 25),
      (pick: 'C-01-01', source: 'C-03-04', wh: 'WH-C', sku: 'SKU-004', min: 8, target: 20),
    ];
    for (var i = 0; i < rules.length; i++) {
      final r = rules[i];
      final productName = getProductBySku(r.sku)?.productName ?? 'Product';
      final id = 'RR-${100 + i}';
      final now = baseDate.add(Duration(days: i));
      final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _replenishmentRules[id] = DemoReplenishmentRule(
        id: id,
        ruleNo: id,
        sku: r.sku,
        productName: productName,
        warehouse: r.wh,
        pickFaceLocation: r.pick,
        sourceLocation: r.source,
        minQty: r.min,
        targetQty: r.target,
        isActive: i < 4,
        lotAware: false,
        expiryAware: false,
        createdAt: nowStr,
        updatedAt: nowStr,
      );
    }
  }

  void _seedCountTasks() {
    final baseDate = DateTime.utc(2025, 2, 10);
    final statuses = ['Draft', 'Draft', 'Released', 'Released', 'Counted', 'Counted', 'Posted', 'Cancelled'];
    final tasks = [
      (wh: 'WH-A', loc: 'A-01-02', sku: 'SKU-001'),
      (wh: 'WH-A', loc: 'A-01-03', sku: 'SKU-002'),
      (wh: 'WH-B', loc: 'B-01-01', sku: 'SKU-001'),
      (wh: 'WH-B', loc: 'B-02-02', sku: 'SKU-003'),
      (wh: 'WH-C', loc: 'C-03-04', sku: 'SKU-004'),
      (wh: 'WH-C', loc: 'C-01-01', sku: 'SKU-005'),
      (wh: 'WH-A', loc: 'A-02-01', sku: 'SKU-002'),
      (wh: 'WH-B', loc: 'B-01-01', sku: 'SKU-002'),
    ];
    for (var i = 0; i < tasks.length; i++) {
      final t = tasks[i];
      final productName = getProductBySku(t.sku)?.productName ?? 'Product';
      final inv = getInventoryBySku(t.sku).where((r) => r.warehouse == t.wh && r.location == t.loc).toList();
      final expected = inv.fold<int>(0, (sum, r) => sum + r.onHandQty);
      final status = statuses[i % statuses.length];
      int? counted;
      if (status == 'Counted' || status == 'Posted') counted = expected + (i % 3 == 0 ? -2 : (i % 3 == 1 ? 3 : 0));
      if (status == 'Posted' && counted == null) counted = expected;
      final id = 'CC-${100 + i}';
      final now = baseDate.add(Duration(days: i));
      final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _countTasks[id] = DemoCountTask(
        id: id,
        countNo: id,
        warehouse: t.wh,
        location: t.loc,
        sku: t.sku,
        productName: productName,
        expectedQty: expected,
        countedQty: counted,
        status: status,
        reasonCode: (counted != null && counted != expected) ? 'ADJ' : null,
        createdAt: nowStr,
        releasedAt: status != 'Draft' ? nowStr : null,
        countedAt: (status == 'Counted' || status == 'Posted') ? nowStr : null,
        postedAt: status == 'Posted' ? nowStr : null,
        cancelledAt: status == 'Cancelled' ? nowStr : null,
        actor: status != 'Draft' ? 'Demo User' : null,
      );
      _countTaskEvents[id] = _seedCountTaskEvents(id, _countTasks[id]!);
    }
  }

  List<DemoEvent> _seedCountTaskEvents(String taskId, DemoCountTask t) {
    final base = DateTime.utc(2025, 2, 10, 8, 0);
    final list = <DemoEvent>[
      DemoEvent(id: 'CE-$taskId-0', code: 'count_created', occurredAt: base, actor: 'system', category: DemoEventCategory.system, payload: 'Count task created'),
    ];
    if (t.status != 'Draft') {
      list.add(DemoEvent(id: 'CE-$taskId-1', code: 'count_released', occurredAt: base.add(const Duration(hours: 1)), actor: t.actor ?? 'system', category: DemoEventCategory.workflow, payload: 'Released'));
    }
    if (t.status == 'Counted' || t.status == 'Posted') {
      list.add(DemoEvent(id: 'CE-$taskId-2', code: 'count_counted', occurredAt: base.add(const Duration(hours: 2)), actor: t.actor ?? 'system', category: DemoEventCategory.workflow, payload: 'Counted: ${t.countedQty}'));
    }
    if (t.status == 'Posted') {
      list.add(DemoEvent(id: 'CE-$taskId-3', code: 'count_posted', occurredAt: base.add(const Duration(hours: 3)), actor: t.actor ?? 'system', category: DemoEventCategory.workflow, payload: 'Adjustment posted'));
    }
    if (t.status == 'Cancelled') {
      list.add(DemoEvent(id: 'CE-$taskId-4', code: 'count_cancelled', occurredAt: base.add(const Duration(hours: 1)), actor: t.actor ?? 'system', category: DemoEventCategory.workflow, payload: 'Cancelled'));
    }
    list.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return list;
  }

  static List<DemoOrderLine> _seedLines() {
    return [
      DemoOrderLine(id: 'L1', sku: 'SKU-001', name: 'Product A', orderedQty: 10, reservedQty: 10, pickedQty: 8, packedQty: 0, shippedQty: 0, shortQty: 0),
      DemoOrderLine(id: 'L2', sku: 'SKU-002', name: 'Product B', orderedQty: 5, reservedQty: 4, pickedQty: 4, packedQty: 4, shippedQty: 0, shortQty: 1, reasonCode: 'LOST'),
      DemoOrderLine(id: 'L3', sku: 'SKU-003', name: 'Product C', orderedQty: 20, reservedQty: 20, pickedQty: 18, packedQty: 18, shippedQty: 18, shortQty: 2, reasonCode: 'DAMAGED'),
      DemoOrderLine(id: 'L4', sku: 'SKU-004', name: 'Product D', orderedQty: 3, reservedQty: 3, pickedQty: 3, packedQty: 3, shippedQty: 3, shortQty: 0),
    ];
  }

  List<DemoHandlingUnit> _seedHus(String orderId) {
    final seed = (orderId.hashCode & 0x7FFF);
    final statuses = ['Open', 'Open', 'Packed', 'Packed', 'Shipped', 'Shipped', 'Open', 'Packed', 'Packed', 'Shipped'];
    final types = ['Pallet', 'Box', 'Box', 'Pallet', 'Box', 'Pallet', 'Box', 'Box', 'Pallet', 'Box'];
    final ssccs = [null, '380123456700000001', null, '380123456700000002', '380123456700000003', null, null, null, null, null];
    final totalQtys = [25, 10, 45, 20, 5, 30, 10, 15, 50, 8];
    return List.generate(10, (i) {
      final contents = [
        DemoHuContent(sku: 'SKU-00${i % 5 + 1}', name: 'Product ${i % 5 + 1}', packedQty: totalQtys[i] ~/ 2),
        if (totalQtys[i] > 5) DemoHuContent(sku: 'SKU-00${(i + 2) % 5 + 1}', name: 'Product ${(i + 2) % 5 + 1}', packedQty: totalQtys[i] - (totalQtys[i] ~/ 2)),
      ];
      final totalQty = contents.fold<int>(0, (s, c) => s + c.packedQty);
      return DemoHandlingUnit(
        id: 'HU-$seed-${i + 1}',
        huNo: 'HU-${i + 1}',
        type: types[i],
        status: statuses[i],
        sscc: ssccs[i],
        contents: contents,
        weight: totalQty * 0.5,
      );
    });
  }

  List<DemoEvent> _seedEvents(String orderId) {
    final seed = (orderId.hashCode & 0x7FFF);
    final base = DateTime.utc(2025, 2, 15, 8, 0);
    final codes = ['order_created', 'released', 'allocated', 'pick_started', 'hold_created', 'hold_resolved', 'pick_completed', 'pack_started', 'shortage_detected', 'pack_completed', 'shipped', 'export_sent', 'closed'];
    final actors = ['system', 'J.Doe', 'J.Doe', 'M.Smith', 'M.Smith', 'M.Smith', 'M.Smith', 'L.Pack', 'system', 'L.Pack', 'system', 'system', 'J.Doe'];
    final notes = ['Order created', 'Order released to warehouse', 'Full allocation', 'Picking started', 'Hold: quality check', 'Hold released', 'Picking completed', 'Packing started', 'Shortage on line 2', 'Packing completed', 'Shipment confirmed', 'EDI sent', 'Order closed'];
    final categories = [DemoEventCategory.system, DemoEventCategory.workflow, DemoEventCategory.workflow, DemoEventCategory.workflow, DemoEventCategory.exception, DemoEventCategory.exception, DemoEventCategory.workflow, DemoEventCategory.workflow, DemoEventCategory.exception, DemoEventCategory.workflow, DemoEventCategory.workflow, DemoEventCategory.system, DemoEventCategory.workflow];
    return List.generate(codes.length, (i) {
      final dt = base.add(Duration(hours: i + 1, minutes: (seed % 30) + i * 5));
      return DemoEvent(
        id: 'EV-$seed-$i',
        code: codes[i],
        occurredAt: dt,
        actor: actors[i % actors.length],
        category: categories[i],
        payload: i < notes.length ? notes[i] : null,
      );
    })..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  }

  List<DemoPickTask> _pickTasksFromLines(List<DemoOrderLine> lines, String orderId) {
    final seed = (orderId.hashCode & 0x7FFF);
    const fallbackLocations = ['A-01-02', 'A-02-01', 'B-01-01', 'A-01-03', 'B-02-02'];
    return List.generate(lines.length, (i) {
      final line = lines[i];
      final qty = line.reservedQty > 0 ? line.reservedQty : line.orderedQty;
      final location = line.reservedFromLocation ?? fallbackLocations[i % fallbackLocations.length];
      final zone = location.isNotEmpty ? location[0] : 'A';
      return DemoPickTask(
        id: 'PT-$seed-${i + 1}',
        taskNo: 'PT-${i + 1}',
        status: 'Open',
        zone: zone,
        location: location,
        sku: line.sku,
        qty: qty,
        pickedQty: 0,
      );
    });
  }

  List<DemoHandlingUnit> _defaultHuFromLines(List<DemoOrderLine> lines, String orderId) {
    if (lines.isEmpty) return [];
    final seed = (orderId.hashCode & 0x7FFF);
    final contents = lines.map((l) {
      int qty = l.pickedQty > 0 ? (l.pickedQty - (l.shortQty > 0 ? l.shortQty : 0)) : l.orderedQty;
      if (qty < 0) qty = 0;
      return DemoHuContent(sku: l.sku, name: l.name, packedQty: qty);
    }).toList();
    final totalQty = contents.fold<int>(0, (s, c) => s + c.packedQty);
    return [
      DemoHandlingUnit(
        id: 'HU-$seed-1',
        huNo: 'HU-1',
        type: 'Box',
        status: 'Packed',
        sscc: null,
        contents: contents,
        weight: totalQty * 0.5,
      ),
    ];
  }

  void _addEvent(String orderId, String code, [String? note, String actor = 'system']) {
    final list = List<DemoEvent>.from(_events[orderId] ?? []);
    final category = _eventCategory(code);
    final occurredAt = _nextEventTime(orderId, list);
    list.add(DemoEvent(
      id: 'EV-$code-${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      occurredAt: occurredAt,
      actor: actor,
      category: category,
      payload: note,
    ));
    list.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    _events[orderId] = list;
  }

  /// Next logical timestamp for this order so new events sit after existing ones.
  DateTime _nextEventTime(String orderId, List<DemoEvent> currentList) {
    if (currentList.isEmpty) return DateTime.now().toUtc();
    final last = currentList.reduce((a, b) => a.occurredAt.isAfter(b.occurredAt) ? a : b);
    return last.occurredAt.add(const Duration(minutes: 1));
  }

  /// Adds an event to the order timeline. Used by workflow engine (e.g. hold_created, hold_resolved).
  void addOrderEvent(String orderId, String code, [String? note]) {
    _addEvent(orderId, code, note);
  }

  DemoEventCategory _eventCategory(String code) {
    const workflow = ['released', 'allocated', 'pick_started', 'pick_completed', 'pack_started', 'pack_completed', 'shipped', 'closed', 'pick_task_started', 'pick_task_completed', 'hu_sealed', 'hu_label_printed', 'hu_unpacked', 'reservation_created', 'picking_applied', 'packing_applied', 'shipment_posted'];
    const exception = ['hold_created', 'hold_resolved', 'shortage_detected', 'pick_task_exception', 'reason_code_set'];
    const system = ['order_created', 'export_sent'];
    final c = code.toLowerCase();
    if (workflow.contains(c)) return DemoEventCategory.workflow;
    if (exception.contains(c)) return DemoEventCategory.exception;
    if (system.contains(c)) return DemoEventCategory.system;
    return DemoEventCategory.system;
  }

  /// Updates a pick task status and records an event. Used by workflow engine.
  void updatePickTaskStatus(String orderId, String taskId, String newStatus) {
    final tasks = _tasks[orderId];
    if (tasks == null) return;
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;
    final task = tasks[index];
    final updated = task.copyWith(status: newStatus);
    _tasks[orderId] = List.from(tasks)..[index] = updated;
    final code = newStatus == 'In Progress' ? 'pick_task_started' : (newStatus == 'Done' ? 'pick_task_completed' : (newStatus == 'Exception' ? 'pick_task_exception' : 'pick_task_updated'));
    final note = 'Task ${task.taskNo}: $newStatus';
    _addEvent(orderId, code, note);
  }

  /// Updates HU status and/or SSCC and records events. Used by workflow engine.
  void updateHu(String orderId, String huId, {String? status, String? sscc}) {
    final hus = _hus[orderId];
    if (hus == null) return;
    final index = hus.indexWhere((h) => h.id == huId);
    if (index < 0) return;
    final hu = hus[index];
    final newStatus = status ?? hu.status;
    final newSscc = sscc ?? hu.sscc;
    final updated = hu.copyWith(status: newStatus, sscc: newSscc);
    _hus[orderId] = List.from(hus)..[index] = updated;
    if (status != null && status != hu.status) {
      if (status == 'Packed') {
        _addEvent(orderId, 'hu_sealed', 'HU ${hu.huNo} sealed');
      } else if (status == 'Open') {
        _addEvent(orderId, 'hu_unpacked', 'HU ${hu.huNo} unpacked');
      }
    }
    if (sscc != null && sscc != hu.sscc) _addEvent(orderId, 'hu_label_printed', 'HU ${hu.huNo} label printed');
  }

  /// All inventory records.
  List<DemoInventoryRecord> getInventory() => _inventory.values.toList();

  /// All inventory records for this SKU (all warehouses). For Product Details.
  List<DemoInventoryRecord> getInventoryBySku(String sku) =>
      _inventory.values.where((r) => r.sku == sku).toList();

  /// Available qty for (warehouse, sku). Sum of all location/lot buckets for that warehouse+sku.
  int getAvailableQty(String warehouse, String sku) =>
      _inventory.values
          .where((r) => r.warehouse == warehouse && r.sku == sku)
          .fold<int>(0, (s, r) => s + r.availableQty);

  /// Reserve stock for order lines (allocate). Uses location/lot buckets: prefer earliest expiry for expiry-tracked, else by location.
  void reserveForOrder(String orderId) {
    final order = _orders[orderId];
    if (order == null) return;
    final lines = _lines[orderId]!;
    final wh = order.warehouse;
    _orderReservationBuckets[orderId] = {};
    final updatedLines = <DemoOrderLine>[];
    for (final line in lines) {
      final buckets = _inventory.values
          .where((r) => r.warehouse == wh && r.sku == line.sku && r.availableQty > 0)
          .toList();
      final product = getProductBySku(line.sku);
      buckets.sort((a, b) {
        if (product != null && (product.requiresExpiryTracking || product.requiresLotTracking)) {
          final expA = a.expiryDate ?? 'zzzz';
          final expB = b.expiryDate ?? 'zzzz';
          final c = expA.compareTo(expB);
          if (c != 0) return c;
        }
        final locC = a.location.compareTo(b.location);
        if (locC != 0) return locC;
        return (a.lot ?? '').compareTo(b.lot ?? '');
      });
      var remaining = line.orderedQty;
      final bucketQtys = <(String, int)>[];
      String? firstLocation;
      for (final inv in buckets) {
        if (remaining <= 0) break;
        final take = remaining < inv.availableQty ? remaining : inv.availableQty;
        if (take <= 0) continue;
        final key = _invBucketKey(inv.warehouse, inv.location, inv.lot, inv.sku);
        _inventory[key] = inv.copyWith(
          availableQty: inv.availableQty - take,
          reservedQty: inv.reservedQty + take,
        );
        bucketQtys.add((key, take));
        firstLocation ??= inv.location;
        remaining -= take;
      }
      final reserveQty = line.orderedQty - remaining;
      _orderReservationBuckets[orderId]![line.sku] = bucketQtys;
      _orderReservations[orderId] ??= {};
      _orderReservations[orderId]![line.sku] = reserveQty;
      updatedLines.add(line.copyWith(
        reservedQty: reserveQty,
        shortQty: remaining > 0 ? remaining : 0,
        reservedFromLocation: firstLocation,
      ));
    }
    _lines[orderId] = updatedLines;
    _addEvent(orderId, 'reservation_created', 'Reserved for order');
  }

  /// Release reservation (e.g. cancel). Restores available from same buckets.
  void releaseReservation(String orderId) {
    final bucketsBySku = _orderReservationBuckets.remove(orderId);
    _orderReservations.remove(orderId);
    if (bucketsBySku == null) return;
    for (final entry in bucketsBySku.entries) {
      for (final pair in entry.value) {
        final key = pair.$1;
        final qty = pair.$2;
        final inv = _inventory[key];
        if (inv != null) {
          _inventory[key] = inv.copyWith(
            availableQty: inv.availableQty + qty,
            reservedQty: inv.reservedQty - qty,
          );
        }
      }
    }
  }

  /// Move reserved -> picked in inventory (after complete_picking). Updates same location/lot buckets.
  void applyPicking(String orderId) {
    final bucketsBySku = _orderReservationBuckets[orderId];
    if (bucketsBySku == null) return;
    for (final entry in bucketsBySku.entries) {
      for (final pair in entry.value) {
        final key = pair.$1;
        final qty = pair.$2;
        final inv = _inventory[key];
        if (inv != null) {
          _inventory[key] = inv.copyWith(
            reservedQty: inv.reservedQty - qty,
            pickedQty: inv.pickedQty + qty,
          );
        }
      }
    }
    _addEvent(orderId, 'picking_applied', 'Stock moved to picked');
  }

  /// Move picked -> packed in inventory (after complete_packing). Updates same location/lot buckets.
  void applyPacking(String orderId) {
    final bucketsBySku = _orderReservationBuckets[orderId];
    if (bucketsBySku == null) return;
    for (final entry in bucketsBySku.entries) {
      for (final pair in entry.value) {
        final key = pair.$1;
        final qty = pair.$2;
        final inv = _inventory[key];
        if (inv != null) {
          _inventory[key] = inv.copyWith(
            pickedQty: inv.pickedQty - qty,
            packedQty: inv.packedQty + qty,
          );
        }
      }
    }
    _addEvent(orderId, 'packing_applied', 'Stock moved to packed');
  }

  /// Move packed -> shipped; decrease onHand (after ship). Updates same location/lot buckets.
  void applyShipment(String orderId) {
    final bucketsBySku = _orderReservationBuckets[orderId];
    if (bucketsBySku == null) return;
    for (final entry in bucketsBySku.entries) {
      for (final pair in entry.value) {
        final key = pair.$1;
        final qty = pair.$2;
        final inv = _inventory[key];
        if (inv != null) {
          _inventory[key] = inv.copyWith(
            onHandQty: inv.onHandQty - qty,
            packedQty: inv.packedQty - qty,
            shippedQty: inv.shippedQty + qty,
          );
        }
      }
    }
    _addEvent(orderId, 'shipment_posted', 'Shipment posted; stock reduced');
  }

  /// All pick tasks from all orders, each with [orderNo] set (for Picking Worklist).
  List<DemoPickTask> getAllPickTasks() {
    final result = <DemoPickTask>[];
    for (final entry in _tasks.entries) {
      final order = _orders[entry.key];
      if (order == null) continue;
      final orderNo = order.orderNo;
      for (final t in entry.value) {
        result.add(DemoPickTask(
          id: t.id,
          taskNo: t.taskNo,
          status: t.status,
          zone: t.zone,
          location: t.location,
          sku: t.sku,
          qty: t.qty,
          pickedQty: t.pickedQty,
          orderNo: orderNo,
        ));
      }
    }
    return result;
  }

  /// All packing tasks from all orders (one row per order line), for Packing Worklist.
  List<DemoPackingTask> getAllPackingTasks() {
    final result = <DemoPackingTask>[];
    for (final entry in _orders.entries) {
      final order = entry.value;
      final orderId = entry.key;
      final orderNo = order.orderNo;
      final lines = _lines[orderId] ?? [];
      final warehouse = order.warehouse;
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final status = _packingStatusFromLine(line);
        result.add(DemoPackingTask(
          id: '$orderId-${line.id}',
          taskNo: 'PK-${i + 1}',
          orderNo: orderNo,
          status: status,
          sku: line.sku,
          pickedQty: line.pickedQty,
          packedQty: line.packedQty,
          shortQty: line.shortQty,
          warehouse: warehouse,
        ));
      }
    }
    return result;
  }

  static String _packingStatusFromLine(DemoOrderLine line) {
    if (line.shortQty > 0) return 'Exception';
    if (line.pickedQty == 0) return line.packedQty > 0 ? 'In Progress' : 'Open';
    if (line.packedQty >= line.pickedQty) return 'Packed';
    if (line.packedQty > 0) return 'In Progress';
    return 'Open';
  }

  // --- Movements (internal movements / replenishment) ---

  List<DemoMovement> getMovements({String search = '', Set<String> statusFilter = const {}}) {
    var list = _movements.values.toList();
    list.sort((a, b) => b.movementNo.compareTo(a.movementNo));
    final query = search.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((m) =>
        m.movementNo.toLowerCase().contains(query) ||
        m.sku.toLowerCase().contains(query) ||
        m.productName.toLowerCase().contains(query) ||
        m.fromLocation.toLowerCase().contains(query) ||
        m.toLocation.toLowerCase().contains(query) ||
        m.warehouse.toLowerCase().contains(query),
      ).toList();
    }
    if (statusFilter.isNotEmpty) {
      list = list.where((m) => statusFilter.contains(m.status)).toList();
    }
    return list;
  }

  DemoMovement? getMovementById(String id) => _movements[id];

  DemoMovement? getMovementByMovementNo(String movementNo) {
    for (final m in _movements.values) {
      if (m.movementNo == movementNo) return m;
    }
    return null;
  }

  void updateMovement(DemoMovement movement) {
    _movements[movement.id] = movement;
  }

  List<DemoEvent> getMovementEvents(String movementId) =>
      List<DemoEvent>.from(_movementEvents[movementId] ?? []);

  void _addMovementEvent(String movementId, String code, [String? note, String actor = 'system']) {
    final list = List<DemoEvent>.from(_movementEvents[movementId] ?? []);
    final category = _movementEventCategory(code);
    final occurredAt = list.isEmpty ? DateTime.now().toUtc() : list.last.occurredAt.add(const Duration(minutes: 1));
    list.add(DemoEvent(
      id: 'ME-$code-${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      occurredAt: occurredAt,
      actor: actor,
      category: category,
      payload: note,
    ));
    list.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    _movementEvents[movementId] = list;
  }

  DemoEventCategory _movementEventCategory(String code) {
    const workflow = ['movement_released', 'movement_started', 'movement_completed', 'movement_cancelled'];
    const system = ['movement_created'];
    final c = code.toLowerCase();
    if (workflow.contains(c)) return DemoEventCategory.workflow;
    if (system.contains(c)) return DemoEventCategory.system;
    return DemoEventCategory.system;
  }

  /// Apply movement action with guards. Returns error message or null on success.
  String? applyMovementAction(String movementId, String actionId, [String actor = 'system']) {
    final m = _movements[movementId];
    if (m == null) return 'Movement not found';

    switch (actionId) {
      case 'release':
        if (m.status != 'Draft') return 'Only Draft can be released';
        if (m.fromLocation == m.toLocation) return 'From and To location must differ';
        if (m.qty <= 0) return 'Quantity must be positive';
        final now = DateTime.now().toUtc();
        final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        _movements[movementId] = m.copyWith(status: 'Released', releasedAt: nowStr, actor: actor);
        _addMovementEvent(movementId, 'movement_released', 'Released', actor);
        return null;
      case 'start':
        if (m.status != 'Released') return 'Only Released can be started';
        final now = DateTime.now().toUtc();
        final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        _movements[movementId] = m.copyWith(status: 'In Progress', startedAt: nowStr, actor: actor);
        _addMovementEvent(movementId, 'movement_started', 'Started', actor);
        return null;
      case 'complete':
        if (m.status != 'In Progress') return 'Only In Progress can be completed';
        if (m.qty <= 0) return 'Quantity must be positive';
        final err = _applyMovementStockUpdate(m);
        if (err != null) return err;
        final now = DateTime.now().toUtc();
        final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        _movements[movementId] = m.copyWith(status: 'Completed', movedQty: m.qty, completedAt: nowStr, actor: actor);
        _addMovementEvent(movementId, 'movement_completed', 'Completed', actor);
        return null;
      case 'cancel':
        if (!['Draft', 'Released', 'In Progress'].contains(m.status)) return 'Only Draft/Released/In Progress can be cancelled';
        final now = DateTime.now().toUtc();
        final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        _movements[movementId] = m.copyWith(status: 'Cancelled', cancelledAt: nowStr, actor: actor);
        _addMovementEvent(movementId, 'movement_cancelled', 'Cancelled', actor);
        return null;
      default:
        return 'Unknown action';
    }
  }

  /// On Complete: decrease source location, increase destination location. Returns error or null.
  String? _applyMovementStockUpdate(DemoMovement m) {
    final srcKey = _invBucketKey(m.warehouse, m.fromLocation, m.lot, m.sku);
    final src = _inventory[srcKey];
    if (src == null) return 'Source location has no stock for ${m.sku}';
    if (src.availableQty < m.qty) return 'Insufficient available qty at source (${src.availableQty} < ${m.qty})';

    _inventory[srcKey] = src.copyWith(
      onHandQty: src.onHandQty - m.qty,
      availableQty: src.availableQty - m.qty,
    );

    final destKey = _invBucketKey(m.warehouse, m.toLocation, m.lot, m.sku);
    var dest = _inventory[destKey];
    if (dest == null) {
      dest = DemoInventoryRecord(
        productId: src.productId,
        sku: m.sku,
        warehouse: m.warehouse,
        location: m.toLocation,
        lot: m.lot,
        onHandQty: m.qty,
        availableQty: m.qty,
        reservedQty: 0,
        pickedQty: 0,
        packedQty: 0,
        shippedQty: 0,
        expiryDate: m.expiryDate,
      );
      _inventory[destKey] = dest;
    } else {
      _inventory[destKey] = dest.copyWith(
        onHandQty: dest.onHandQty + m.qty,
        availableQty: dest.availableQty + m.qty,
      );
    }
    return null;
  }

  // --- Replenishment rules ---

  List<DemoReplenishmentRule> getReplenishmentRules({
    String search = '',
    String filter = 'all',
  }) {
    var list = _replenishmentRules.values.toList();
    list.sort((a, b) => b.ruleNo.compareTo(a.ruleNo));
    final query = search.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((r) =>
        r.ruleNo.toLowerCase().contains(query) ||
        r.sku.toLowerCase().contains(query) ||
        r.productName.toLowerCase().contains(query) ||
        r.pickFaceLocation.toLowerCase().contains(query) ||
        r.sourceLocation.toLowerCase().contains(query) ||
        r.warehouse.toLowerCase().contains(query),
      ).toList();
    }
    switch (filter) {
      case 'active':
        list = list.where((r) => r.isActive).toList();
        break;
      case 'inactive':
        list = list.where((r) => !r.isActive).toList();
        break;
      case 'needs_replenishment':
        list = list.where((r) => r.isActive && getSuggestedReplenishmentQty(r) > 0).toList();
        break;
      default:
        break;
    }
    return list;
  }

  DemoReplenishmentRule? getReplenishmentRuleById(String id) => _replenishmentRules[id];

  void updateReplenishmentRule(DemoReplenishmentRule rule) {
    _replenishmentRules[rule.id] = rule;
  }

  /// Suggested replenishment qty: if current available at pick face >= minQty then 0; else max(0, targetQty - current).
  int getSuggestedReplenishmentQty(DemoReplenishmentRule rule) {
    final inv = getInventoryBySku(rule.sku);
    final current = inv
        .where((r) => r.warehouse == rule.warehouse && r.location == rule.pickFaceLocation)
        .fold<int>(0, (sum, r) => sum + r.availableQty);
    if (current >= rule.minQty) return 0;
    return (rule.targetQty - current).clamp(0, rule.targetQty);
  }

  /// Current available qty at rule's pick face location (for display).
  int getReplenishmentRuleCurrentQty(DemoReplenishmentRule rule) {
    final inv = getInventoryBySku(rule.sku);
    return inv
        .where((r) => r.warehouse == rule.warehouse && r.location == rule.pickFaceLocation)
        .fold<int>(0, (sum, r) => sum + r.availableQty);
  }

  /// Create a new replenishment movement from rule. Returns the new movement or null if suggested qty is 0.
  DemoMovement? createMovementFromReplenishmentRule(DemoReplenishmentRule rule, [String actor = 'Demo User']) {
    final suggested = getSuggestedReplenishmentQty(rule);
    if (suggested <= 0) return null;
    final nextId = _nextMovementId();
    final now = DateTime.now().toUtc();
    final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final m = DemoMovement(
      id: nextId,
      movementNo: nextId,
      warehouse: rule.warehouse,
      movementType: DemoMovementType.replenishment,
      sku: rule.sku,
      productName: rule.productName,
      fromLocation: rule.sourceLocation,
      toLocation: rule.pickFaceLocation,
      qty: suggested,
      movedQty: 0,
      status: 'Draft',
      createdAt: nowStr,
      actor: actor,
    );
    _movements[nextId] = m;
    _movementEvents[nextId] = [
      DemoEvent(
        id: 'ME-$nextId-0',
        code: 'movement_created',
        occurredAt: now,
        actor: actor,
        category: DemoEventCategory.system,
        payload: 'Created from replenishment rule ${rule.ruleNo}',
      ),
    ];
    return m;
  }

  String _nextMovementId() {
    var max = 0;
    for (final key in _movements.keys) {
      final match = RegExp(r'^MOV-(\d+)$').firstMatch(key);
      if (match != null) {
        final n = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (n > max) max = n;
      }
    }
    return 'MOV-${max + 1}';
  }

  // --- Cycle count tasks ---

  List<DemoCountTask> getCountTasks({
    String search = '',
    String filter = 'all',
  }) {
    var list = _countTasks.values.toList();
    list.sort((a, b) => b.countNo.compareTo(a.countNo));
    final query = search.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) =>
        t.countNo.toLowerCase().contains(query) ||
        t.sku.toLowerCase().contains(query) ||
        t.productName.toLowerCase().contains(query) ||
        t.location.toLowerCase().contains(query) ||
        t.warehouse.toLowerCase().contains(query),
      ).toList();
    }
    switch (filter) {
      case 'open':
        list = list.where((t) => t.status == 'Draft' || t.status == 'Released').toList();
        break;
      case 'counted':
        list = list.where((t) => t.status == 'Counted').toList();
        break;
      case 'posted':
        list = list.where((t) => t.status == 'Posted').toList();
        break;
      case 'cancelled':
        list = list.where((t) => t.status == 'Cancelled').toList();
        break;
      case 'variance_only':
        list = list.where((t) => t.countedQty != null && t.varianceQty != 0).toList();
        break;
      default:
        break;
    }
    return list;
  }

  DemoCountTask? getCountTaskById(String id) => _countTasks[id];

  void updateCountTask(DemoCountTask task) {
    _countTasks[task.id] = task;
  }

  List<DemoEvent> getCountTaskEvents(String taskId) =>
      List<DemoEvent>.from(_countTaskEvents[taskId] ?? []);

  void _addCountTaskEvent(String taskId, String code, [String? note, String actor = 'system']) {
    final list = List<DemoEvent>.from(_countTaskEvents[taskId] ?? []);
    final category = _countEventCategory(code);
    final occurredAt = list.isEmpty ? DateTime.now().toUtc() : list.last.occurredAt.add(const Duration(minutes: 1));
    list.add(DemoEvent(
      id: 'CE-$code-${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      occurredAt: occurredAt,
      actor: actor,
      category: category,
      payload: note,
    ));
    list.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    _countTaskEvents[taskId] = list;
  }

  DemoEventCategory _countEventCategory(String code) {
    const workflow = ['count_released', 'count_counted', 'count_posted', 'count_cancelled'];
    const system = ['count_created'];
    final c = code.toLowerCase();
    if (workflow.contains(c)) return DemoEventCategory.workflow;
    if (system.contains(c)) return DemoEventCategory.system;
    return DemoEventCategory.system;
  }

  /// Apply count action. Returns error message or null on success.
  String? applyCountAction(String taskId, String actionId, {int? countedQty, String? reasonCode, String actor = 'Demo User'}) {
    final t = _countTasks[taskId];
    if (t == null) return 'Count task not found';

    switch (actionId) {
      case 'release':
        if (t.status != 'Draft') return 'Only Draft can be released';
        final now = DateTime.now().toUtc();
        final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        _countTasks[taskId] = t.copyWith(status: 'Released', releasedAt: nowStr, actor: actor);
        _addCountTaskEvent(taskId, 'count_released', 'Released', actor);
        return null;
      case 'count':
        if (t.status != 'Released') return 'Only Released can be marked counted';
        if (countedQty == null) return 'Counted qty required';
        if (countedQty < 0) return 'Counted qty cannot be negative';
        final variance = countedQty - t.expectedQty;
        if (variance != 0 && (reasonCode == null || reasonCode.trim().isEmpty)) return 'Reason code required when variance is not zero';
        final now = DateTime.now().toUtc();
        final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        _countTasks[taskId] = t.copyWith(countedQty: countedQty, status: 'Counted', reasonCode: reasonCode?.trim().isEmpty == true ? null : reasonCode, countedAt: nowStr, actor: actor);
        _addCountTaskEvent(taskId, 'count_counted', 'Counted: $countedQty', actor);
        return null;
      case 'post':
        if (t.status != 'Counted') return 'Only Counted can be posted';
        if (t.countedQty == null) return 'Counted qty missing';
        final err = _applyCountPostAdjustment(_countTasks[taskId]!);
        if (err != null) return err;
        final now = DateTime.now().toUtc();
        final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        _countTasks[taskId] = t.copyWith(status: 'Posted', postedAt: nowStr, actor: actor);
        _addCountTaskEvent(taskId, 'count_posted', 'Adjustment posted', actor);
        return null;
      case 'cancel':
        if (!['Draft', 'Released', 'Counted'].contains(t.status)) return 'Only Draft/Released/Counted can be cancelled';
        final now = DateTime.now().toUtc();
        final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        _countTasks[taskId] = t.copyWith(status: 'Cancelled', cancelledAt: nowStr, actor: actor);
        _addCountTaskEvent(taskId, 'count_cancelled', 'Cancelled', actor);
        return null;
      default:
        return 'Unknown action';
    }
  }

  /// On Post: set inventory bucket (warehouse, location, lot, sku) to countedQty.
  String? _applyCountPostAdjustment(DemoCountTask t) {
    final key = _invBucketKey(t.warehouse, t.location, t.lot, t.sku);
    final existing = _inventory[key];
    final productId = _productIdBySku[t.sku] ?? t.sku;
    if (existing != null) {
      _inventory[key] = existing.copyWith(
        onHandQty: t.countedQty!,
        availableQty: t.countedQty! - existing.reservedQty,
      );
    } else {
      _inventory[key] = DemoInventoryRecord(
        productId: productId,
        sku: t.sku,
        warehouse: t.warehouse,
        location: t.location,
        lot: t.lot,
        onHandQty: t.countedQty!,
        availableQty: t.countedQty!,
        reservedQty: 0,
        pickedQty: 0,
        packedQty: 0,
        shippedQty: 0,
        expiryDate: t.expiryDate,
      );
    }
    return null;
  }

  /// Products list. [statusFilter] empty = all; [lotTracked]/[expiryTracked] null = any.
  List<DemoProduct> getProducts({
    String search = '',
    Set<String> statusFilter = const {},
    bool? lotTracked,
    bool? expiryTracked,
  }) {
    var list = _products.values.toList();
    final query = search.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) =>
        p.sku.toLowerCase().contains(query) ||
        p.productName.toLowerCase().contains(query) ||
        p.gtin14.contains(query) ||
        p.brand.toLowerCase().contains(query),
      ).toList();
    }
    if (statusFilter.isNotEmpty) {
      list = list.where((p) => statusFilter.contains(p.status)).toList();
    }
    if (lotTracked == true) {
      list = list.where((p) => p.requiresLotTracking).toList();
    }
    if (expiryTracked == true) {
      list = list.where((p) => p.requiresExpiryTracking).toList();
    }
    return list;
  }

  DemoProduct? getProductById(String productId) => _products[productId];

  DemoProduct? getProductBySku(String sku) {
    final id = _productIdBySku[sku];
    return id != null ? _products[id] : null;
  }

  /// Orders that have at least one line with this product (by sku or productId).
  List<DemoOrder> getOrdersForProduct(String productIdOrSku) {
    final product = _products[productIdOrSku];
    final skuToUse = product?.sku ?? (_productIdBySku[productIdOrSku] != null
        ? _products[_productIdBySku[productIdOrSku]]!.sku
        : productIdOrSku);
    final orderIds = <String>{};
    for (final entry in _lines.entries) {
      if (entry.value.any((l) => l.sku == skuToUse)) orderIds.add(entry.key);
    }
    return orderIds.map((id) => _orders[id]!).whereType<DemoOrder>().toList();
  }

  /// HUs that contain this product (by sku or productId). Returns orderNo + HU for display.
  List<({String orderNo, DemoHandlingUnit hu})> getHuForProduct(String productIdOrSku) {
    final product = _products[productIdOrSku];
    final idBySku = _productIdBySku[productIdOrSku];
    final skuToUse = product?.sku ?? (idBySku != null ? _products[idBySku]!.sku : productIdOrSku);
    final result = <({String orderNo, DemoHandlingUnit hu})>[];
    for (final entry in _hus.entries) {
      final order = _orders[entry.key];
      if (order == null) continue;
      for (final hu in entry.value) {
        if (hu.contents.any((c) => c.sku == skuToUse)) {
          result.add((orderNo: order.orderNo, hu: hu));
        }
      }
    }
    return result;
  }

  List<DemoOrder> getOrders(DemoOrdersFilters filters) {
    var list = _orders.values.toList();
    final query = filters.search.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((o) =>
        o.orderNo.toLowerCase().contains(query) ||
        o.warehouse.toLowerCase().contains(query) ||
        o.status.toLowerCase().contains(query),
      ).toList();
    }
    if (filters.statusFilters.isNotEmpty) {
      list = list.where((o) => filters.statusFilters.contains(o.status)).toList();
    }
    if (filters.warehouse != null) {
      list = list.where((o) => o.warehouse == filters.warehouse).toList();
    }
    switch (filters.viewId) {
      case 'on_hold':
        list = list.where((o) => o.status == 'On Hold').toList();
        break;
      case 'shortage':
        list = list.where((o) => o.status == 'Shortage').toList();
        break;
      case 'today':
        list = list.where((o) => o.createdAt.startsWith('2025-01')).toList();
        break;
      case 'all':
      case 'custom':
      default:
        break;
    }
    return list;
  }

  DemoOrderDetailsBundle getOrderDetails(String orderId) {
    final order = _orders[orderId];
    if (order == null) {
      throw StateError('Order not found: $orderId');
    }
    final lines = List<DemoOrderLine>.from(_lines[orderId] ?? []);
    final hus = List<DemoHandlingUnit>.from(_hus[orderId] ?? []);
    final events = List<DemoEvent>.from(_events[orderId] ?? []);
    final tasks = List<DemoPickTask>.from(_tasks[orderId] ?? []);
    final hasShort = lines.any((l) => l.shortQty > 0);
    final actionsUi = createMockOrderActionsUiForStatus(
      order.status,
      hasShort: hasShort,
      huCount: hus.length,
    );
    return DemoOrderDetailsBundle(
      order: order,
      lines: lines,
      hus: hus,
      events: events,
      tasks: tasks,
      actionsUi: actionsUi,
    );
  }

  /// Build HU/SSCC label preview for Print label (Handling Units drawer).
  HuLabelPreview buildHuLabelPreview(String orderId, String huId) {
    final order = _orders[orderId];
    if (order == null) throw StateError('Order not found: $orderId');
    final hus = _hus[orderId] ?? [];
    DemoHandlingUnit? hu;
    for (final h in hus) {
      if (h.id == huId) { hu = h; break; }
    }
    if (hu == null) throw StateError('HU not found: $huId');
    final rows = hu.contents.map((c) {
      final name = getProductBySku(c.sku)?.productName ?? c.sku;
      return HuLabelContentRow(sku: c.sku, name: name, qty: c.packedQty);
    }).toList();
    return HuLabelPreview(
      orderNo: order.orderNo,
      warehouse: order.warehouse,
      huNo: hu.huNo,
      type: hu.type,
      status: hu.status,
      sscc: hu.sscc,
      contentsSummary: rows,
      totalQty: hu.totalQty,
      generatedAt: DateTime.now(),
    );
  }

  /// Build packing slip preview (Order Details — Documents).
  PackingSlipPreview buildPackingSlipPreview(String orderId) {
    final order = _orders[orderId];
    if (order == null) throw StateError('Order not found: $orderId');
    final lines = _lines[orderId] ?? [];
    final hus = _hus[orderId] ?? [];
    final lineRows = lines.map((l) {
      final name = getProductBySku(l.sku)?.productName ?? l.sku;
      return PackingSlipLineRow(
        sku: l.sku,
        name: name,
        orderedQty: l.orderedQty,
        packedQty: l.packedQty,
        shippedQty: l.shippedQty,
        shortQty: l.shortQty,
      );
    }).toList();
    return PackingSlipPreview(
      orderNo: order.orderNo,
      warehouse: order.warehouse,
      status: order.status,
      createdAt: order.createdAt,
      lines: lineRows,
      huCount: hus.length,
      generatedAt: DateTime.now(),
    );
  }

  /// Build shipment summary preview (Order Details — Documents).
  ShipmentPreview buildShipmentPreview(String orderId) {
    final order = _orders[orderId];
    if (order == null) throw StateError('Order not found: $orderId');
    final lines = _lines[orderId] ?? [];
    final hus = _hus[orderId] ?? [];
    final lineRows = lines.map((l) {
      final name = getProductBySku(l.sku)?.productName ?? l.sku;
      return PackingSlipLineRow(
        sku: l.sku,
        name: name,
        orderedQty: l.orderedQty,
        packedQty: l.packedQty,
        shippedQty: l.shippedQty,
        shortQty: l.shortQty,
      );
    }).toList();
    final totalShipped = lineRows.fold<int>(0, (s, r) => s + r.shippedQty);
    return ShipmentPreview(
      orderNo: order.orderNo,
      warehouse: order.warehouse,
      status: order.status,
      createdAt: order.createdAt,
      lines: lineRows,
      huCount: hus.length,
      totalShipped: totalShipped,
      generatedAt: DateTime.now(),
    );
  }

  void applyAction(String orderId, String actionId) {
    final order = _orders[orderId];
    if (order == null) return;
    var lines = _lines[orderId]!;
    var hus = _hus[orderId]!;
    var tasks = _tasks[orderId]!;

    if (actionId == 'release') {
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Released', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'released', 'Order released to warehouse');
      return;
    }
    if (actionId == 'allocate') {
      reserveForOrder(orderId);
      lines = _lines[orderId]!;
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Allocated', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'allocated', 'Allocation applied');
      if (tasks.isEmpty) {
        _tasks[orderId] = _pickTasksFromLines(lines, orderId);
      }
      return;
    }
    if (actionId == 'start_picking') {
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Picking', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'pick_started', 'Picking started');
      return;
    }
    if (actionId == 'complete_picking') {
      lines = lines.map((l) {
        final qty = l.reservedQty > 0 ? l.reservedQty : l.orderedQty;
        return l.copyWith(pickedQty: qty);
      }).toList();
      _lines[orderId] = lines;
      applyPicking(orderId);
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Picked', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'pick_completed', 'Picking completed');
      return;
    }
    if (actionId == 'start_packing') {
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Packing', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'pack_started', 'Packing started');
      return;
    }
    if (actionId == 'complete_packing') {
      lines = lines.map((l) {
        final packedQty = l.shortQty > 0 ? l.pickedQty - l.shortQty : l.pickedQty;
        return l.copyWith(packedQty: packedQty >= 0 ? packedQty : l.pickedQty);
      }).toList();
      _lines[orderId] = lines;
      applyPacking(orderId);
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Packed', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'pack_completed', 'Packing completed');
      if (hus.isEmpty) {
        _hus[orderId] = _defaultHuFromLines(lines, orderId);
      }
      return;
    }
    if (actionId == 'ship') {
      lines = lines.map((l) {
        final shippedQty = l.shortQty > 0 ? l.orderedQty - l.shortQty : l.packedQty;
        return l.copyWith(shippedQty: shippedQty);
      }).toList();
      _lines[orderId] = lines;
      applyShipment(orderId);
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Shipped', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'shipped', 'Shipment confirmed');
      _hus[orderId] = hus.map((h) => h.copyWith(status: 'Shipped')).toList();
      return;
    }
    if (actionId == 'close') {
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Closed', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'closed', 'Order closed');
      return;
    }
  }

  void updateLinesShortage(String orderId, List<String> selectedLineIds, int shortQty, String reasonCode) {
    var lines = _lines[orderId];
    if (lines == null) return;
    _lines[orderId] = lines.map((l) {
      if (!selectedLineIds.contains(l.id)) return l;
      return l.copyWith(shortQty: shortQty, reasonCode: reasonCode);
    }).toList();
    _addEvent(orderId, 'shortage_detected', 'Shortage on selected lines');
  }

  void updateLinesReasonCode(String orderId, List<String> selectedLineIds, String reasonCode) {
    var lines = _lines[orderId];
    if (lines == null) return;
    _lines[orderId] = lines.map((l) {
      if (!selectedLineIds.contains(l.id)) return l;
      return l.copyWith(reasonCode: reasonCode);
    }).toList();
    _addEvent(orderId, 'reason_code_set', 'Reason code set on ${selectedLineIds.length} line(s)');
  }

  void setOrderLines(String orderId, List<DemoOrderLine> lines) {
    _lines[orderId] = List.from(lines);
    if (lines.any((l) => l.shortQty > 0)) {
      _addEvent(orderId, 'shortage_detected', 'Shortage on selected lines');
    }
  }

  /// Sets order status (and optional baseStatus for On Hold). Used by workflow engine for hold/resolve.
  void setOrderStatus(String orderId, String status, {String? baseStatus}) {
    final order = _orders[orderId];
    if (order == null) return;
    _orders[orderId] = DemoOrder(
      id: order.id,
      orderNo: order.orderNo,
      status: status,
      warehouse: order.warehouse,
      createdAt: order.createdAt,
      baseStatus: baseStatus ?? order.baseStatus,
      shipFromGln: order.shipFromGln,
      shipToGln: order.shipToGln,
      warehouseGln: order.warehouseGln,
    );
  }
}

/// Global singleton for ui_v1 demo. Initialized and seeded in main.
DemoRepository get demoRepository => _demoRepository;
final DemoRepository _demoRepository = DemoRepository();
