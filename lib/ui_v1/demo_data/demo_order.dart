// Demo order model for worklist and details.

/// In-memory order for demo.
class DemoOrder {
  DemoOrder({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.warehouse,
    required this.createdAt,
    this.baseStatus,
    this.shipFromGln,
    this.shipToGln,
    this.warehouseGln,
  }) : isOnHold = status.toLowerCase() == 'on hold';

  final String id;
  final String orderNo;
  final String status;
  final bool isOnHold;
  final String warehouse;
  /// Display date string (e.g. '2025-01-15').
  final String createdAt;
  /// When status is On Hold, chip shows this (e.g. 'Allocated').
  final String? baseStatus;
  /// GS1: ship-from location GLN (optional).
  final String? shipFromGln;
  /// GS1: ship-to party GLN (optional).
  final String? shipToGln;
  /// GS1: warehouse GLN (optional).
  final String? warehouseGln;
}
