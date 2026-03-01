// Demo handling unit for HU tab.

/// One line in HU contents.
class DemoHuContent {
  DemoHuContent({
    required this.sku,
    required this.name,
    required this.packedQty,
  });
  final String sku;
  final String name;
  final int packedQty;
}

/// In-memory handling unit for demo.
class DemoHandlingUnit {
  DemoHandlingUnit({
    required this.id,
    required this.huNo,
    required this.type,
    required this.status,
    this.sscc,
    required this.contents,
    this.weight,
  });

  final String id;
  final String huNo;
  final String type;
  final String status;
  final String? sscc;
  final List<DemoHuContent> contents;
  final double? weight;

  int get linesCount => contents.length;
  int get totalQty => contents.fold(0, (s, c) => s + c.packedQty);

  DemoHandlingUnit copyWith({String? status}) {
    return DemoHandlingUnit(
      id: id,
      huNo: huNo,
      type: type,
      status: status ?? this.status,
      sscc: sscc,
      contents: contents,
      weight: weight,
    );
  }
}
