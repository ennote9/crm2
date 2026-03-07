// Demo internal movement / replenishment task for Movements module v1.

/// Movement type: replenishment, relocation, transfer.
enum DemoMovementType {
  replenishment,
  relocation,
  transfer,
}

extension DemoMovementTypeExt on DemoMovementType {
  String get label {
    switch (this) {
      case DemoMovementType.replenishment:
        return 'Replenishment';
      case DemoMovementType.relocation:
        return 'Relocation';
      case DemoMovementType.transfer:
        return 'Transfer';
    }
  }
}

/// Statuses: Draft, Released, In Progress, Completed, Cancelled.
const List<String> kMovementStatuses = [
  'Draft',
  'Released',
  'In Progress',
  'Completed',
  'Cancelled',
];

/// In-memory movement task. Updated by applyMovementAction; stock by location on Complete.
class DemoMovement {
  const DemoMovement({
    required this.id,
    required this.movementNo,
    required this.warehouse,
    required this.movementType,
    required this.sku,
    required this.productName,
    required this.fromLocation,
    required this.toLocation,
    required this.qty,
    this.movedQty = 0,
    required this.status,
    required this.createdAt,
    this.releasedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.actor,
    this.lot,
    this.expiryDate,
  });

  final String id;
  final String movementNo;
  final String warehouse;
  final DemoMovementType movementType;
  final String sku;
  final String productName;
  final String fromLocation;
  final String toLocation;
  final int qty;
  final int movedQty;
  final String status;
  final String createdAt;
  final String? releasedAt;
  final String? startedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? actor;
  final String? lot;
  final String? expiryDate;

  DemoMovement copyWith({
    String? status,
    int? movedQty,
    String? releasedAt,
    String? startedAt,
    String? completedAt,
    String? cancelledAt,
    String? actor,
    String? fromLocation,
    String? toLocation,
    int? qty,
  }) {
    return DemoMovement(
      id: id,
      movementNo: movementNo,
      warehouse: warehouse,
      movementType: movementType,
      sku: sku,
      productName: productName,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      qty: qty ?? this.qty,
      movedQty: movedQty ?? this.movedQty,
      status: status ?? this.status,
      createdAt: createdAt,
      releasedAt: releasedAt ?? this.releasedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      actor: actor ?? this.actor,
      lot: lot,
      expiryDate: expiryDate,
    );
  }
}
