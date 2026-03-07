// Lines tab v1: mini-grid, multi-select, bulk actions (Mark shortage, Set reason code).

import 'package:flutter/material.dart';

import '../../components/bulk_action_bar/index.dart';
import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../demo_data/demo_data.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';
import '../products/sku_link_text.dart';

/// Reason codes for shortage (demo).
const List<String> kShortageReasonCodes = ['DAMAGED', 'LOST', 'EXPIRED', 'NOT_FOUND'];

const String kERsn001 = 'E_RSN_001';
const String kERsn001Message = 'Укажите причину (reason code).';

/// Lines tab: grid with selection, bulk action bar, Mark shortage / Set reason code.
class OrderLinesTab extends StatefulWidget {
  const OrderLinesTab({
    super.key,
    this.orderNo,
    this.lines,
    this.onLinesChanged,
    this.onOrderDataChanged,
  });

  final String? orderNo;
  final List<DemoOrderLine>? lines;
  final void Function(List<DemoOrderLine>)? onLinesChanged;
  final VoidCallback? onOrderDataChanged;

  @override
  State<OrderLinesTab> createState() => _OrderLinesTabState();
}

class _OrderLinesTabState extends State<OrderLinesTab> {
  late List<DemoOrderLine> _lines;
  Set<String> _selectedIds = {};
  final s = UiV1SpacingTokens.standard;
  final density = UiV1DensityTokens.dense;

  @override
  void initState() {
    super.initState();
    _lines = List.from(widget.lines ?? []);
  }

  @override
  void didUpdateWidget(OrderLinesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines != null && widget.lines != oldWidget.lines) {
      _lines = List.from(widget.lines!);
    }
  }

  List<DemoOrderLine> get _effectiveLines => widget.lines ?? _lines;

  List<UiV1DataGridColumn<DemoOrderLine>> _columns(BuildContext context) {
    return [
      UiV1DataGridColumn<DemoOrderLine>(
        id: 'sku',
        label: 'SKU',
        flex: 2,
        cellBuilder: (r) => SkuLinkText(sku: r.sku),
      ),
      UiV1DataGridColumn<DemoOrderLine>(
        id: 'name',
        label: 'Name',
        flex: 2,
        cellBuilder: (r) => SkuLinkText(sku: r.sku, label: r.name),
      ),
      UiV1DataGridColumn<DemoOrderLine>(
        id: 'ordered',
        label: 'Ordered',
        flex: 1,
        cellBuilder: (r) => Text('${r.orderedQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoOrderLine>(
        id: 'reserved',
        label: 'Reserved',
        flex: 1,
        cellBuilder: (r) => Text('${r.reservedQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoOrderLine>(
        id: 'pickFrom',
        label: 'Pick from',
        flex: 1,
        cellBuilder: (r) => Text(r.reservedFromLocation ?? '—', overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoOrderLine>(
        id: 'picked',
        label: 'Picked',
        flex: 1,
        cellBuilder: (r) => Text('${r.pickedQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoOrderLine>(
        id: 'packed',
        label: 'Packed',
        flex: 1,
        cellBuilder: (r) => Text('${r.packedQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoOrderLine>(
        id: 'shipped',
        label: 'Shipped',
        flex: 1,
        cellBuilder: (r) => Text('${r.shippedQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoOrderLine>(
        id: 'short',
        label: 'Short',
        flex: 1,
        cellBuilder: (r) {
          if (r.shortQty > 0) {
            final content = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text('${r.shortQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: UiV1StatusChip(label: 'Shortage', variant: UiV1StatusVariant.warning),
                ),
              ],
            );
            final tooltip = r.reasonCode != null ? '${r.shortQty} — ${r.reasonCode}' : null;
            return tooltip != null
                ? Tooltip(message: tooltip, child: content)
                : content;
          }
          return Text('${r.shortQty}', overflow: TextOverflow.ellipsis, maxLines: 1);
        },
      ),
    ];
  }

  Future<void> _onMarkShortage() async {
    if (_selectedIds.isEmpty || widget.orderNo == null) return;
    final result = await showDialog<({int shortQty, String? reasonCode})>(
      context: context,
      builder: (context) => _MarkShortageDialog(s: s, density: density),
    );
    if (result == null || !mounted) return;
    if (result.reasonCode == null || result.reasonCode!.isEmpty) {
      await _showInfoDialog(kERsn001, kERsn001Message);
      return;
    }
    outboundWorkflowEngine.executeMarkShortage(
      widget.orderNo!,
      _selectedIds.toList(),
      result.shortQty,
      result.reasonCode!,
    );
    widget.onOrderDataChanged?.call();
    setState(() => _selectedIds = {});
  }

  Future<void> _onSetReasonCode() async {
    if (_selectedIds.isEmpty || widget.orderNo == null) return;
    final reasonCode = await showDialog<String>(
      context: context,
      builder: (context) => _SetReasonCodeDialog(s: s, density: density),
    );
    if (reasonCode == null || !mounted) return;
    outboundWorkflowEngine.executeSetReasonCode(
      widget.orderNo!,
      _selectedIds.toList(),
      reasonCode,
    );
    widget.onOrderDataChanged?.call();
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
            child: UiV1DataGrid<DemoOrderLine>(
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
                onPressed: (_selectedIds.isEmpty || !canExecuteLineAction()) ? null : _onMarkShortage,
                style: FilledButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
                child: const Text('Mark shortage'),
              ),
              SizedBox(width: s.xs),
              FilledButton.tonal(
                onPressed: (_selectedIds.isEmpty || !canExecuteLineAction()) ? null : _onSetReasonCode,
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
              initialValue: _reasonCode,
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
          initialValue: _value,
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

