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

  DemoOrderLine copyWith({
    int? pickedQty,
    int? packedQty,
    int? shippedQty,
    int? shortQty,
    String? reasonCode,
  }) {
    return DemoOrderLine(
      id: id,
      sku: sku,
      name: name,
      orderedQty: orderedQty,
      reservedQty: reservedQty,
      pickedQty: pickedQty ?? this.pickedQty,
      packedQty: packedQty ?? this.packedQty,
      shippedQty: shippedQty ?? this.shippedQty,
      shortQty: shortQty ?? this.shortQty,
      reasonCode: reasonCode ?? this.reasonCode,
    );
  }
}
