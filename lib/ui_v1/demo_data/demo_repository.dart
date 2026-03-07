// In-memory demo repository: orders, lines, HU, events, pick tasks.

import '../pages/order_details/order_actions_model.dart';
import 'demo_event.dart';
import 'demo_handling_unit.dart';
import 'demo_order.dart';
import 'demo_order_line.dart';
import 'demo_orders_filters.dart';
import 'demo_pick_task.dart';
import 'demo_packing_task.dart';
import 'demo_product.dart';

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
  }

  late Map<String, DemoOrder> _orders;
  late Map<String, List<DemoOrderLine>> _lines;
  late Map<String, List<DemoHandlingUnit>> _hus;
  late Map<String, List<DemoEvent>> _events;
  late Map<String, List<DemoPickTask>> _tasks;
  late Map<String, DemoProduct> _products;
  late Map<String, String> _productIdBySku;

  /// Populate with initial demo data.
  void seed() {
    _seedProducts();
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
    final zones = ['A', 'A', 'B', 'A', 'B'];
    final locations = ['A-01-02', 'A-02-01', 'B-01-01', 'A-01-03', 'B-02-02'];
    return List.generate(lines.length, (i) {
      final line = lines[i];
      final qty = line.reservedQty > 0 ? line.reservedQty : line.orderedQty;
      return DemoPickTask(
        id: 'PT-$seed-${i + 1}',
        taskNo: 'PT-${i + 1}',
        status: 'Open',
        zone: zones[i % zones.length],
        location: locations[i % locations.length],
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

  void _addEvent(String orderId, String code, [String? note]) {
    final list = List<DemoEvent>.from(_events[orderId] ?? []);
    final category = _eventCategory(code);
    list.add(DemoEvent(
      id: 'EV-$code-${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      occurredAt: DateTime.now().toUtc(),
      actor: 'system',
      category: category,
      payload: note,
    ));
    list.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    _events[orderId] = list;
  }

  DemoEventCategory _eventCategory(String code) {
    const workflow = ['released', 'allocated', 'pick_started', 'pick_completed', 'pack_started', 'pack_completed', 'shipped', 'closed'];
    const exception = ['hold_created', 'hold_resolved', 'shortage_detected'];
    const system = ['order_created', 'export_sent'];
    final c = code.toLowerCase();
    if (workflow.contains(c)) return DemoEventCategory.workflow;
    if (exception.contains(c)) return DemoEventCategory.exception;
    if (system.contains(c)) return DemoEventCategory.system;
    return DemoEventCategory.system;
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
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Allocated', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'allocated', 'Full allocation');
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
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Picked', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'pick_completed', 'Picking completed');
      lines = lines.map((l) {
        final qty = l.reservedQty > 0 ? l.reservedQty : l.orderedQty;
        return l.copyWith(pickedQty: qty);
      }).toList();
      _lines[orderId] = lines;
      return;
    }
    if (actionId == 'start_packing') {
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Packing', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'pack_started', 'Packing started');
      return;
    }
    if (actionId == 'complete_packing') {
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Packed', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'pack_completed', 'Packing completed');
      lines = lines.map((l) {
        final packedQty = l.shortQty > 0 ? l.pickedQty - l.shortQty : l.pickedQty;
        return l.copyWith(packedQty: packedQty >= 0 ? packedQty : l.pickedQty);
      }).toList();
      _lines[orderId] = lines;
      if (hus.isEmpty) {
        _hus[orderId] = _defaultHuFromLines(lines, orderId);
      }
      return;
    }
    if (actionId == 'ship') {
      _orders[orderId] = DemoOrder(id: order.id, orderNo: order.orderNo, status: 'Shipped', warehouse: order.warehouse, createdAt: order.createdAt, baseStatus: order.baseStatus);
      _addEvent(orderId, 'shipped', 'Shipment confirmed');
      _hus[orderId] = hus.map((h) => h.copyWith(status: 'Shipped')).toList();
      lines = lines.map((l) {
        final shippedQty = l.shortQty > 0 ? l.orderedQty - l.shortQty : l.packedQty;
        return l.copyWith(shippedQty: shippedQty);
      }).toList();
      _lines[orderId] = lines;
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
  }

  void setOrderLines(String orderId, List<DemoOrderLine> lines) {
    _lines[orderId] = List.from(lines);
    if (lines.any((l) => l.shortQty > 0)) {
      _addEvent(orderId, 'shortage_detected', 'Shortage on selected lines');
    }
  }
}

/// Global singleton for ui_v1 demo. Initialized and seeded in main.
DemoRepository get demoRepository => _demoRepository;
final DemoRepository _demoRepository = DemoRepository();
