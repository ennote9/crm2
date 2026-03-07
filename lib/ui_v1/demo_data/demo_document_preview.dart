// Demo document/label preview models for HU label, packing slip, shipment.

/// HU / SSCC label preview (from Handling Units drawer — Print label).
class HuLabelPreview {
  const HuLabelPreview({
    required this.orderNo,
    required this.warehouse,
    required this.huNo,
    required this.type,
    required this.status,
    this.sscc,
    required this.contentsSummary,
    required this.totalQty,
    this.generatedAt,
  });
  final String orderNo;
  final String warehouse;
  final String huNo;
  final String type;
  final String status;
  final String? sscc;
  final List<HuLabelContentRow> contentsSummary;
  final int totalQty;
  final DateTime? generatedAt;
}

class HuLabelContentRow {
  const HuLabelContentRow({required this.sku, required this.name, required this.qty});
  final String sku;
  final String name;
  final int qty;
}

/// Packing slip / shipment summary preview (from Order Details — Documents).
class PackingSlipPreview {
  const PackingSlipPreview({
    required this.orderNo,
    required this.warehouse,
    required this.status,
    required this.createdAt,
    required this.lines,
    required this.huCount,
    this.generatedAt,
  });
  final String orderNo;
  final String warehouse;
  final String status;
  final String createdAt;
  final List<PackingSlipLineRow> lines;
  final int huCount;
  final DateTime? generatedAt;
}

class PackingSlipLineRow {
  const PackingSlipLineRow({
    required this.sku,
    required this.name,
    required this.orderedQty,
    required this.packedQty,
    required this.shippedQty,
    required this.shortQty,
  });
  final String sku;
  final String name;
  final int orderedQty;
  final int packedQty;
  final int shippedQty;
  final int shortQty;
}

/// Shipment label / shipping doc preview (from Order Details — Documents).
class ShipmentPreview {
  const ShipmentPreview({
    required this.orderNo,
    required this.warehouse,
    required this.status,
    required this.createdAt,
    required this.lines,
    required this.huCount,
    required this.totalShipped,
    this.generatedAt,
  });
  final String orderNo;
  final String warehouse;
  final String status;
  final String createdAt;
  final List<PackingSlipLineRow> lines;
  final int huCount;
  final int totalShipped;
  final DateTime? generatedAt;
}
