// Demo packing task for Packing Worklist (aggregated from order lines).

/// In-memory packing task row for demo worklist.
/// One row per order line; [orderNo] and [warehouse] from order.
class DemoPackingTask {
  DemoPackingTask({
    required this.id,
    required this.taskNo,
    required this.orderNo,
    required this.status,
    required this.sku,
    required this.pickedQty,
    required this.packedQty,
    required this.shortQty,
    required this.warehouse,
  });

  final String id;
  final String taskNo;
  final String orderNo;
  final String status;
  final String sku;
  final int pickedQty;
  final int packedQty;
  final int shortQty;
  final String warehouse;
}
