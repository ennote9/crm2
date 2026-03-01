// Demo pick task for Pick Tasks tab.

/// In-memory pick task for demo.
class DemoPickTask {
  DemoPickTask({
    required this.id,
    required this.taskNo,
    required this.status,
    required this.zone,
    required this.location,
    required this.sku,
    required this.qty,
    required this.pickedQty,
  });

  final String id;
  final String taskNo;
  final String status;
  final String zone;
  final String location;
  final String sku;
  final int qty;
  final int pickedQty;
}
