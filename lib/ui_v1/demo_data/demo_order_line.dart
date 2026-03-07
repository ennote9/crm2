// Demo order line for Lines tab.

/// In-memory order line for demo.
class DemoOrderLine {
  DemoOrderLine({
    required this.id,
    required this.sku,
    required this.name,
    required this.orderedQty,
    required this.reservedQty,
    required this.pickedQty,
    required this.packedQty,
    required this.shippedQty,
    required this.shortQty,
    this.reasonCode,
    this.reservedFromLocation,
  });

  final String id;
  final String sku;
  final String name;
  final int orderedQty;
  final int reservedQty;
  final int pickedQty;
  final int packedQty;
  final int shippedQty;
  final int shortQty;
  final String? reasonCode;
  /// Source location for reservation (from allocation buckets). Shown as "Pick from …".
  final String? reservedFromLocation;

  DemoOrderLine copyWith({
    int? reservedQty,
    int? pickedQty,
    int? packedQty,
    int? shippedQty,
    int? shortQty,
    String? reasonCode,
    String? reservedFromLocation,
  }) {
    return DemoOrderLine(
      id: id,
      sku: sku,
      name: name,
      orderedQty: orderedQty,
      reservedQty: reservedQty ?? this.reservedQty,
      pickedQty: pickedQty ?? this.pickedQty,
      packedQty: packedQty ?? this.packedQty,
      shippedQty: shippedQty ?? this.shippedQty,
      shortQty: shortQty ?? this.shortQty,
      reasonCode: reasonCode ?? this.reasonCode,
      reservedFromLocation: reservedFromLocation ?? this.reservedFromLocation,
    );
  }
}
