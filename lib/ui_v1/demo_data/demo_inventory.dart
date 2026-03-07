// Demo inventory/stock record for workflow integration.
// v2: location/lot-level buckets; reserve/pick/pack/ship operate on these buckets.

/// In-memory inventory record per (warehouse, location, lot?, sku). Updated by reserve, pick, pack, ship.
class DemoInventoryRecord {
  const DemoInventoryRecord({
    required this.productId,
    required this.sku,
    required this.warehouse,
    required this.location,
    this.lot,
    required this.onHandQty,
    required this.availableQty,
    required this.reservedQty,
    required this.pickedQty,
    required this.packedQty,
    required this.shippedQty,
    this.expiryDate,
  });

  final String productId;
  final String sku;
  final String warehouse;
  final String location;
  final String? lot;
  final int onHandQty;
  final int availableQty;
  final int reservedQty;
  final int pickedQty;
  final int packedQty;
  final int shippedQty;
  /// Display date string (e.g. '2025-12-31') when product is expiry-tracked.
  final String? expiryDate;

  DemoInventoryRecord copyWith({
    int? onHandQty,
    int? availableQty,
    int? reservedQty,
    int? pickedQty,
    int? packedQty,
    int? shippedQty,
    String? location,
    String? lot,
    String? expiryDate,
  }) {
    return DemoInventoryRecord(
      productId: productId,
      sku: sku,
      warehouse: warehouse,
      location: location ?? this.location,
      lot: lot ?? this.lot,
      onHandQty: onHandQty ?? this.onHandQty,
      availableQty: availableQty ?? this.availableQty,
      reservedQty: reservedQty ?? this.reservedQty,
      pickedQty: pickedQty ?? this.pickedQty,
      packedQty: packedQty ?? this.packedQty,
      shippedQty: shippedQty ?? this.shippedQty,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}
