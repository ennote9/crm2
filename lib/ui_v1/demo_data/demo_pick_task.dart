// Demo pick task for Pick Tasks tab and Picking Worklist.

/// In-memory pick task for demo.
/// [orderNo] is set when task is returned from [DemoRepository.getAllPickTasks] (worklist).
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
    this.orderNo,
  });

  final String id;
  final String taskNo;
  final String status;
  final String zone;
  final String location;
  final String sku;
  final int qty;
  final int pickedQty;
  /// Order number (set when aggregating for picking worklist).
  final String? orderNo;
}
