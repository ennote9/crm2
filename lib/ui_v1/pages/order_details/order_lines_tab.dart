// Lines tab v1: mini-grid of order lines (dense, tokens). Mock data.

import 'package:flutter/material.dart';

import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../theme/density.dart';

/// Mock row for one order line in the Lines grid.
class OrderLineMock {
  OrderLineMock({
    required this.id,
    required this.sku,
    required this.name,
    required this.ordered,
    required this.reserved,
    required this.picked,
    required this.packed,
    required this.shipped,
    required this.short,
  });
  final String id;
  final String sku;
  final String name;
  final int ordered;
  final int reserved;
  final int picked;
  final int packed;
  final int shipped;
  final int short;
}

/// Lines tab content: dense mini-grid. No row actions, selection disabled.
class OrderLinesTab extends StatelessWidget {
  const OrderLinesTab({super.key, this.orderNo});

  final String? orderNo;

  static List<OrderLineMock> _mockLines() {
    return [
      OrderLineMock(id: 'L1', sku: 'SKU-001', name: 'Product A', ordered: 10, reserved: 10, picked: 8, packed: 0, shipped: 0, short: 0),
      OrderLineMock(id: 'L2', sku: 'SKU-002', name: 'Product B', ordered: 5, reserved: 4, picked: 4, packed: 4, shipped: 0, short: 1),
      OrderLineMock(id: 'L3', sku: 'SKU-003', name: 'Product C', ordered: 20, reserved: 20, picked: 18, packed: 18, shipped: 18, short: 2),
      OrderLineMock(id: 'L4', sku: 'SKU-004', name: 'Product D', ordered: 3, reserved: 3, picked: 3, packed: 3, shipped: 3, short: 0),
    ];
  }

  static List<UiV1DataGridColumn<OrderLineMock>> get _columns => [
    UiV1DataGridColumn<OrderLineMock>(
      id: 'sku',
      label: 'SKU',
      flex: 2,
      cellBuilder: (r) => Text(r.sku, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<OrderLineMock>(
      id: 'name',
      label: 'Name',
      flex: 2,
      cellBuilder: (r) => Text(r.name, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<OrderLineMock>(
      id: 'ordered',
      label: 'Ordered',
      flex: 1,
      cellBuilder: (r) => Text('${r.ordered}', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<OrderLineMock>(
      id: 'reserved',
      label: 'Reserved',
      flex: 1,
      cellBuilder: (r) => Text('${r.reserved}', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<OrderLineMock>(
      id: 'picked',
      label: 'Picked',
      flex: 1,
      cellBuilder: (r) => Text('${r.picked}', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<OrderLineMock>(
      id: 'packed',
      label: 'Packed',
      flex: 1,
      cellBuilder: (r) => Text('${r.packed}', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<OrderLineMock>(
      id: 'shipped',
      label: 'Shipped',
      flex: 1,
      cellBuilder: (r) => Text('${r.shipped}', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<OrderLineMock>(
      id: 'short',
      label: 'Short',
      flex: 1,
      cellBuilder: (r) {
        if (r.short > 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text('${r.short}', overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
              const SizedBox(width: 4),
              UiV1StatusChip(label: 'Shortage', variant: UiV1StatusVariant.warning),
            ],
          );
        }
        return Text('${r.short}', overflow: TextOverflow.ellipsis, maxLines: 1);
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = _mockLines();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: UiV1DataGrid<OrderLineMock>(
        columns: _columns,
        rows: rows,
        rowIdGetter: (r) => r.id,
        selectedIds: const {},
        onSelectionChanged: null,
        emptyMessage: 'No lines',
        showRowActions: false,
        density: UiV1Density.dense,
      ),
    );
  }
}
