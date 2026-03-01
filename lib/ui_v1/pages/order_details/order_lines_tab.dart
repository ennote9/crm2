// Lines tab v1: mini-grid, multi-select, bulk actions (Mark shortage, Set reason code). Mock data.

import 'package:flutter/material.dart';

import '../../components/bulk_action_bar/index.dart';
import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';

/// Reason codes for shortage (demo).
const List<String> kShortageReasonCodes = ['DAMAGED', 'LOST', 'EXPIRED', 'NOT_FOUND'];

const String kERsn001 = 'E_RSN_001';
const String kERsn001Message = 'Укажите причину (reason code).';

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
    this.reasonCode,
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
  final String? reasonCode;

  OrderLineMock copyWith({int? short, String? reasonCode, int? shipped, int? picked, int? packed}) {
    return OrderLineMock(
      id: id,
      sku: sku,
      name: name,
      ordered: ordered,
      reserved: reserved,
      picked: picked ?? this.picked,
      packed: packed ?? this.packed,
      shipped: shipped ?? this.shipped,
      short: short ?? this.short,
      reasonCode: reasonCode ?? this.reasonCode,
    );
  }
}

/// Creates default mock lines for order details (used by page state and Lines tab).
List<OrderLineMock> createMockOrderLines() {
  return [
    OrderLineMock(id: 'L1', sku: 'SKU-001', name: 'Product A', ordered: 10, reserved: 10, picked: 8, packed: 0, shipped: 0, short: 0),
    OrderLineMock(id: 'L2', sku: 'SKU-002', name: 'Product B', ordered: 5, reserved: 4, picked: 4, packed: 4, shipped: 0, short: 1, reasonCode: 'LOST'),
    OrderLineMock(id: 'L3', sku: 'SKU-003', name: 'Product C', ordered: 20, reserved: 20, picked: 18, packed: 18, shipped: 18, short: 2, reasonCode: 'DAMAGED'),
    OrderLineMock(id: 'L4', sku: 'SKU-004', name: 'Product D', ordered: 3, reserved: 3, picked: 3, packed: 3, shipped: 3, short: 0),
  ];
}

/// Lines tab: grid with selection, bulk action bar, Mark shortage / Set reason code.
class OrderLinesTab extends StatefulWidget {
  const OrderLinesTab({
    super.key,
    this.orderNo,
    this.lines,
    this.onLinesChanged,
  });

  final String? orderNo;
  /// When provided, tab is controlled (parent owns lines). Otherwise uses internal mock.
  final List<OrderLineMock>? lines;
  final void Function(List<OrderLineMock>)? onLinesChanged;

  @override
  State<OrderLinesTab> createState() => _OrderLinesTabState();
}

class _OrderLinesTabState extends State<OrderLinesTab> {
  late List<OrderLineMock> _lines;
  Set<String> _selectedIds = {};
  final s = UiV1SpacingTokens.standard;
  final density = UiV1DensityTokens.dense;

  @override
  void initState() {
    super.initState();
    _lines = widget.lines ?? createMockOrderLines();
  }

  @override
  void didUpdateWidget(OrderLinesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines != null && widget.lines != oldWidget.lines) {
      _lines = List.from(widget.lines!);
    }
  }

  List<OrderLineMock> get _effectiveLines => widget.lines ?? _lines;

  void _setLines(List<OrderLineMock> next) {
    if (widget.onLinesChanged != null) {
      widget.onLinesChanged!(next);
    } else {
      setState(() => _lines = next);
    }
  }

  List<UiV1DataGridColumn<OrderLineMock>> _columns(BuildContext context) {
    return [
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
            final content = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text('${r.short}', overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
                const SizedBox(width: 4),
                UiV1StatusChip(label: 'Shortage', variant: UiV1StatusVariant.warning),
              ],
            );
            final tooltip = r.reasonCode != null ? '${r.short} — ${r.reasonCode}' : null;
            return tooltip != null
                ? Tooltip(message: tooltip, child: content)
                : content;
          }
          return Text('${r.short}', overflow: TextOverflow.ellipsis, maxLines: 1);
        },
      ),
    ];
  }

  Future<void> _onMarkShortage() async {
    if (_selectedIds.isEmpty) return;
    final result = await showDialog<({int shortQty, String? reasonCode})>(
      context: context,
      builder: (context) => _MarkShortageDialog(s: s, density: density),
    );
    if (result == null || !mounted) return;
    if (result.reasonCode == null || result.reasonCode!.isEmpty) {
      await _showInfoDialog(kERsn001, kERsn001Message);
      return;
    }
    _setLines(_effectiveLines.map((line) {
      if (!_selectedIds.contains(line.id)) return line;
      return line.copyWith(short: result.shortQty, reasonCode: result.reasonCode);
    }).toList());
    setState(() => _selectedIds = {});
  }

  Future<void> _onSetReasonCode() async {
    if (_selectedIds.isEmpty) return;
    final reasonCode = await showDialog<String>(
      context: context,
      builder: (context) => _SetReasonCodeDialog(s: s, density: density),
    );
    if (reasonCode == null || !mounted) return;
    _setLines(_effectiveLines.map((line) {
      if (!_selectedIds.contains(line.id)) return line;
      return line.copyWith(reasonCode: reasonCode);
    }).toList());
    setState(() => _selectedIds = {});
  }

  Future<void> _showInfoDialog(String code, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(code),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: s.xl, vertical: s.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: UiV1DataGrid<OrderLineMock>(
              columns: _columns(context),
              rows: _effectiveLines,
              rowIdGetter: (r) => r.id,
              selectedIds: _selectedIds,
              onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
              showRowActions: false,
              density: UiV1Density.dense,
              emptyMessage: 'No lines',
            ),
          ),
          UiV1BulkActionBar(
            selectedCount: _selectedIds.length,
            onClearSelection: () => setState(() => _selectedIds = {}),
            primaryActions: [
              FilledButton.tonal(
                onPressed: _selectedIds.isEmpty ? null : _onMarkShortage,
                style: FilledButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
                child: const Text('Mark shortage'),
              ),
              SizedBox(width: s.xs),
              FilledButton.tonal(
                onPressed: _selectedIds.isEmpty ? null : _onSetReasonCode,
                style: FilledButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
                child: const Text('Set reason code'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarkShortageDialog extends StatefulWidget {
  const _MarkShortageDialog({required this.s, required this.density});
  final UiV1SpacingTokens s;
  final UiV1DensityTokens density;

  @override
  State<_MarkShortageDialog> createState() => _MarkShortageDialogState();
}

class _MarkShortageDialogState extends State<_MarkShortageDialog> {
  final _shortController = TextEditingController(text: '1');
  String? _reasonCode;

  @override
  void dispose() {
    _shortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark shortage'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _shortController,
              decoration: const InputDecoration(
                labelText: 'Short qty',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: widget.s.sm),
            DropdownButtonFormField<String>(
              value: _reasonCode,
              decoration: const InputDecoration(
                labelText: 'Reason code (required)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Select —')),
                ...kShortageReasonCodes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (v) => setState(() => _reasonCode = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final shortQty = int.tryParse(_shortController.text.trim()) ?? 0;
            Navigator.of(context).pop((shortQty: shortQty, reasonCode: _reasonCode));
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _SetReasonCodeDialog extends StatefulWidget {
  const _SetReasonCodeDialog({required this.s, required this.density});
  final UiV1SpacingTokens s;
  final UiV1DensityTokens density;

  @override
  State<_SetReasonCodeDialog> createState() => _SetReasonCodeDialogState();
}

class _SetReasonCodeDialogState extends State<_SetReasonCodeDialog> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set reason code'),
      content: SizedBox(
        width: 280,
        child: DropdownButtonFormField<String>(
          value: _value,
          decoration: const InputDecoration(
            labelText: 'Reason code',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('— Select —')),
            ...kShortageReasonCodes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
          ],
          onChanged: (v) => setState(() => _value = v),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop<String>(_value),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
