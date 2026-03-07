// Product master model (demo, GS1-aligned). Source of truth for product data.

/// In-memory product master for demo. Order lines, HU contents, pick/pack tasks reference by sku/productId.
class DemoProduct {
  DemoProduct({
    required this.productId,
    required this.sku,
    required this.productName,
    required this.gtin14,
    required this.brand,
    required this.category,
    required this.status,
    required this.baseUom,
    required this.sellingUom,
    required this.orderingUom,
    required this.barcodePrimary,
    this.barcodeSecondary,
    required this.requiresLotTracking,
    required this.requiresSerialTracking,
    required this.requiresExpiryTracking,
    this.shelfLifeDays,
    this.bestBeforeDays,
    this.countryOfOrigin,
    this.netWeight,
    this.grossWeight,
    this.length,
    this.width,
    this.height,
    this.unitsPerCase,
    this.casesPerLayer,
    this.layersPerPallet,
    this.storageCondition,
    this.hazardousFlag,
    this.notes,
  });

  final String productId;
  final String sku;
  final String productName;
  /// GTIN-14 as exactly 14 digits (string).
  final String gtin14;
  final String brand;
  final String category;
  /// Active | Inactive | Blocked
  final String status;
  final String baseUom;
  final String sellingUom;
  final String orderingUom;
  final String barcodePrimary;
  final List<String>? barcodeSecondary;
  final bool requiresLotTracking;
  final bool requiresSerialTracking;
  final bool requiresExpiryTracking;
  final int? shelfLifeDays;
  final int? bestBeforeDays;
  final String? countryOfOrigin;
  final double? netWeight;
  final double? grossWeight;
  final double? length;
  final double? width;
  final double? height;
  final int? unitsPerCase;
  final int? casesPerLayer;
  final int? layersPerPallet;
  /// Ambient | Chilled | Frozen | Cosmetic Controlled | etc.
  final String? storageCondition;
  final bool? hazardousFlag;
  final String? notes;
}
