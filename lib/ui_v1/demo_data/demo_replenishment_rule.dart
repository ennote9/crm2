// Demo replenishment rule (bin refill / pick-face replenishment) for Replenishment module v1.

/// In-memory replenishment rule. Used to suggest qty and create replenishment movements.
class DemoReplenishmentRule {
  const DemoReplenishmentRule({
    required this.id,
    required this.ruleNo,
    required this.sku,
    required this.productName,
    required this.warehouse,
    required this.pickFaceLocation,
    required this.sourceLocation,
    required this.minQty,
    required this.targetQty,
    required this.isActive,
    this.lotAware = false,
    this.expiryAware = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ruleNo;
  final String sku;
  final String productName;
  final String warehouse;
  final String pickFaceLocation;
  final String sourceLocation;
  final int minQty;
  final int targetQty;
  final bool isActive;
  final bool lotAware;
  final bool expiryAware;
  final String createdAt;
  final String updatedAt;

  DemoReplenishmentRule copyWith({
    String? sku,
    String? productName,
    String? pickFaceLocation,
    String? sourceLocation,
    int? minQty,
    int? targetQty,
    bool? isActive,
    bool? lotAware,
    bool? expiryAware,
    String? updatedAt,
  }) {
    return DemoReplenishmentRule(
      id: id,
      ruleNo: ruleNo,
      sku: sku ?? this.sku,
      productName: productName ?? this.productName,
      warehouse: warehouse,
      pickFaceLocation: pickFaceLocation ?? this.pickFaceLocation,
      sourceLocation: sourceLocation ?? this.sourceLocation,
      minQty: minQty ?? this.minQty,
      targetQty: targetQty ?? this.targetQty,
      isActive: isActive ?? this.isActive,
      lotAware: lotAware ?? this.lotAware,
      expiryAware: expiryAware ?? this.expiryAware,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
