// Demo cycle count task for Cycle Count / Inventory Adjustments v1.

const List<String> kCountTaskStatuses = [
  'Draft',
  'Released',
  'Counted',
  'Posted',
  'Cancelled',
];

/// In-memory count task. Variance = countedQty - expectedQty. Post updates stock by location.
class DemoCountTask {
  const DemoCountTask({
    required this.id,
    required this.countNo,
    required this.warehouse,
    required this.location,
    required this.sku,
    required this.productName,
    required this.expectedQty,
    this.countedQty,
    required this.status,
    this.reasonCode,
    required this.createdAt,
    this.releasedAt,
    this.countedAt,
    this.postedAt,
    this.cancelledAt,
    this.actor,
    this.lot,
    this.expiryDate,
  });

  final String id;
  final String countNo;
  final String warehouse;
  final String location;
  final String sku;
  final String productName;
  final int expectedQty;
  final int? countedQty;
  final String status;
  final String? reasonCode;
  final String createdAt;
  final String? releasedAt;
  final String? countedAt;
  final String? postedAt;
  final String? cancelledAt;
  final String? actor;
  final String? lot;
  final String? expiryDate;

  /// varianceQty = countedQty - expectedQty (when countedQty is set).
  int get varianceQty {
    if (countedQty == null) return 0;
    return countedQty! - expectedQty;
  }

  DemoCountTask copyWith({
    int? countedQty,
    String? status,
    String? reasonCode,
    String? releasedAt,
    String? countedAt,
    String? postedAt,
    String? cancelledAt,
    String? actor,
  }) {
    return DemoCountTask(
      id: id,
      countNo: countNo,
      warehouse: warehouse,
      location: location,
      sku: sku,
      productName: productName,
      expectedQty: expectedQty,
      countedQty: countedQty ?? this.countedQty,
      status: status ?? this.status,
      reasonCode: reasonCode ?? this.reasonCode,
      createdAt: createdAt,
      releasedAt: releasedAt ?? this.releasedAt,
      countedAt: countedAt ?? this.countedAt,
      postedAt: postedAt ?? this.postedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      actor: actor ?? this.actor,
      lot: lot,
      expiryDate: expiryDate,
    );
  }
}
