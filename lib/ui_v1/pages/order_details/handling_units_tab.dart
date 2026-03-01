// Handling Units tab v1: HU list, filters, search, HU detail drawer with contents. Mock data.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';
import 'order_actions_model.dart';
import 'order_lines_tab.dart';

/// HU status: Open / Packed / Shipped
const List<String> kHuStatuses = ['Open', 'Packed', 'Shipped'];

enum HuFilter { all, open, packed, shipped }

/// Mock row for one handling unit.
class HuMock {
  HuMock({
    required this.id,
    required this.huNo,
    required this.type,
    required this.status,
    this.sscc,
    required this.linesCount,
    required this.totalQty,
    this.weight,
    required this.contents,
  });
  final String id;
  final String huNo;
  final String type;
  final String status;
  final String? sscc;
  final int linesCount;
  final int totalQty;
  final double? weight;
  final List<HuContentMock> contents;

  HuMock copyWith({String? status}) {
    return HuMock(
      id: id,
      huNo: huNo,
      type: type,
      status: status ?? this.status,
      sscc: sscc,
      linesCount: linesCount,
      totalQty: totalQty,
      weight: weight,
      contents: contents,
    );
  }
}

/// One line in HU contents.
class HuContentMock {
  HuContentMock({required this.sku, required this.name, required this.packedQty});
  final String sku;
  final String name;
  final int packedQty;
}

UiV1StatusVariant _huStatusVariant(String status) {
  final s = status.toLowerCase();
  if (s == 'open') return UiV1StatusVariant.neutral;
  if (s == 'packed') return UiV1StatusVariant.info;
  if (s == 'shipped') return UiV1StatusVariant.success;
  return UiV1StatusVariant.neutral;
}

/// Demo E_HU_* reasons for HU actions (not in MessageCatalog; demo only).
const String kEHuShipped = 'E_HU_001';
const String kEHuNotPacked = 'E_HU_002';
const String kEHuNothingToUnpack = 'E_HU_003';

List<HuMock> _mockHus(String? orderNo) {
  final count = getMockHuCountForOrder(orderNo ?? '');
  if (count == 0) return [];
  final statuses = ['Open', 'Open', 'Packed', 'Packed', 'Packed', 'Shipped', 'Shipped', 'Open', 'Packed', 'Packed', 'Shipped', 'Open', 'Packed'];
  final types = ['Pallet', 'Box', 'Box', 'Pallet', 'Box', 'Pallet', 'Box', 'Box', 'Pallet', 'Box', 'Pallet', 'Box', 'Box'];
  final ssccs = [null, '380123456700000001', null, '380123456700000002', '380123456700000003', '380123456700000004', '380123456700000005', null, '380123456700000006', null, '380123456700000007', null, '380123456700000008'];
  final linesCounts = [2, 1, 3, 2, 1, 2, 1, 2, 3, 1, 2, 1, 2];
  final totalQtys = [25, 10, 45, 20, 5, 30, 10, 15, 50, 8, 22, 6, 18];
  final weights = [12.5, 2.0, 18.0, 8.0, 1.5, 15.0, 3.0, 4.0, 20.0, 2.5, 11.0, 1.0, 6.0];
  final seed = (orderNo ?? 'ORD').hashCode & 0x7FFF;
  return List.generate(count.clamp(0, 13), (i) {
    final huId = 'HU-$seed-${i + 1}';
    return HuMock(
      id: huId,
      huNo: 'HU-${i + 1}',
      type: types[i],
      status: statuses[i],
      sscc: ssccs[i],
      linesCount: linesCounts[i],
      totalQty: totalQtys[i],
      weight: weights[i],
      contents: [
        HuContentMock(sku: 'SKU-00${i % 5 + 1}', name: 'Product ${i % 5 + 1}', packedQty: totalQtys[i] ~/ 2),
        if (linesCounts[i] > 1) HuContentMock(sku: 'SKU-00${(i + 2) % 5 + 1}', name: 'Product ${(i + 2) % 5 + 1}', packedQty: totalQtys[i] - (totalQtys[i] ~/ 2)),
      ],
    );
  });
}

/// Creates mock HU list for order (used by page state and HU tab).
List<HuMock> createMockHusForOrder(String orderNo) => _mockHus(orderNo);

/// Creates one default HU from lines (used when pack_completed and hus empty). Status Packed.
List<HuMock> createDefaultHuFromLines(List<OrderLineMock> lines, String orderNo) {
  if (lines.isEmpty) return [];
  final seed = (orderNo.hashCode & 0x7FFF);
  final contents = lines.map((l) {
    int qty = l.picked > 0 ? (l.picked - (l.short > 0 ? l.short : 0)) : l.ordered;
    if (qty < 0) qty = 0;
    return HuContentMock(sku: l.sku, name: l.name, packedQty: qty);
  }).toList();
  final totalQty = contents.fold<int>(0, (s, c) => s + c.packedQty);
  return [
    HuMock(
      id: 'HU-$seed-1',
      huNo: 'HU-1',
      type: 'Box',
      status: 'Packed',
      sscc: null,
      linesCount: contents.length,
      totalQty: totalQty,
      weight: totalQty * 0.5,
      contents: contents,
    ),
  ];
}

/// Handling Units tab: filters + search + dense list. State preserved when switching tabs.
class HandlingUnitsTab extends StatefulWidget {
  const HandlingUnitsTab({super.key, this.orderNo, this.hus});

  final String? orderNo;
  /// When provided, tab uses this list (e.g. from page state after Ship).
  final List<HuMock>? hus;

  @override
  State<HandlingUnitsTab> createState() => _HandlingUnitsTabState();
}

class _HandlingUnitsTabState extends State<HandlingUnitsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  HuFilter _filter = HuFilter.all;
  final TextEditingController _searchController = TextEditingController();

  late List<HuMock> _allHus;

  @override
  void initState() {
    super.initState();
    _allHus = widget.hus ?? _mockHus(widget.orderNo);
  }

  @override
  void didUpdateWidget(HandlingUnitsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hus != null && widget.hus != oldWidget.hus) {
      _allHus = List.from(widget.hus!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HuMock> get _filteredRows {
    var list = _allHus;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((h) =>
        h.huNo.toLowerCase().contains(query) ||
        (h.sscc?.toLowerCase().contains(query) ?? false),
      ).toList();
    }
    switch (_filter) {
      case HuFilter.all:
        break;
      case HuFilter.open:
        list = list.where((h) => h.status == 'Open').toList();
        break;
      case HuFilter.packed:
        list = list.where((h) => h.status == 'Packed').toList();
        break;
      case HuFilter.shipped:
        list = list.where((h) => h.status == 'Shipped').toList();
        break;
    }
    return list;
  }

  static List<UiV1DataGridColumn<HuMock>> get _columns => [
    UiV1DataGridColumn<HuMock>(id: 'huNo', label: 'Hu No', flex: 1, cellBuilder: (r) => Text(r.huNo, overflow: TextOverflow.ellipsis, maxLines: 1)),
    UiV1DataGridColumn<HuMock>(id: 'type', label: 'Type', flex: 1, cellBuilder: (r) => Text(r.type, overflow: TextOverflow.ellipsis, maxLines: 1)),
    UiV1DataGridColumn<HuMock>(id: 'status', label: 'Status', flex: 1, cellBuilder: (r) => UiV1StatusChip(label: r.status, variant: _huStatusVariant(r.status))),
    UiV1DataGridColumn<HuMock>(id: 'sscc', label: 'SSCC', flex: 2, cellBuilder: (r) => Text(r.sscc ?? '—', overflow: TextOverflow.ellipsis, maxLines: 1)),
    UiV1DataGridColumn<HuMock>(id: 'linesCount', label: 'Lines', flex: 1, cellBuilder: (r) => Text('${r.linesCount}', overflow: TextOverflow.ellipsis, maxLines: 1)),
    UiV1DataGridColumn<HuMock>(id: 'totalQty', label: 'Total Qty', flex: 1, cellBuilder: (r) => Text('${r.totalQty}', overflow: TextOverflow.ellipsis, maxLines: 1)),
    UiV1DataGridColumn<HuMock>(id: 'weight', label: 'Weight', flex: 1, cellBuilder: (r) => Text(r.weight != null ? '${r.weight}' : '—', overflow: TextOverflow.ellipsis, maxLines: 1)),
  ];

  void _openHuDetail(HuMock hu) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 600) {
      _showHuDetailDrawer(context, hu);
    } else {
      _showHuDetailBottomSheet(context, hu);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final density = UiV1DensityTokens.dense;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{const SingleActivator(LogicalKeyboardKey.escape): _ClearHuSearchIntent()},
      child: Actions(
        actions: {
          _ClearHuSearchIntent: CallbackAction<_ClearHuSearchIntent>(
            onInvoke: (_) {
              _searchController.clear();
              setState(() {});
              return null;
            },
          ),
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(s.xl, s.sm, s.xl, s.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: s.md,
                runSpacing: s.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SegmentedButton<HuFilter>(
                    segments: [
                      ButtonSegment<HuFilter>(value: HuFilter.all, label: const Text('All')),
                      ButtonSegment<HuFilter>(value: HuFilter.open, label: const Text('Open')),
                      ButtonSegment<HuFilter>(value: HuFilter.packed, label: const Text('Packed')),
                      ButtonSegment<HuFilter>(value: HuFilter.shipped, label: const Text('Shipped')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (v) => setState(() => _filter = v.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs)),
                      textStyle: WidgetStateProperty.all(theme.textTheme.labelMedium),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    height: density.inputHeight,
                    child: ListenableBuilder(
                      listenable: _searchController,
                      builder: (context, _) => TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search HuNo, SSCC…',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
                          border: const OutlineInputBorder(),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: s.sm),
              Expanded(
                child: UiV1DataGrid<HuMock>(
                  columns: _columns,
                  rows: _filteredRows,
                  rowIdGetter: (r) => r.id,
                  selectedIds: {},
                  onSelectionChanged: null,
                  showRowActions: false,
                  density: UiV1Density.dense,
                  emptyMessage: 'No handling units',
                  onRowOpen: _openHuDetail,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClearHuSearchIntent extends Intent {}

void _showHuDetailDrawer(BuildContext context, HuMock hu) {
  final theme = Theme.of(context);
  final s = UiV1SpacingTokens.standard;
  final density = UiV1DensityTokens.dense;

  showGeneralDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          elevation: 8,
          child: Container(
            width: 420,
            height: double.infinity,
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.all(s.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          hu.huNo,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(), tooltip: 'Close'),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(s.md),
                    child: _HuDetailContent(hu: hu, density: density, s: s, theme: theme),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _showHuDetailBottomSheet(BuildContext context, HuMock hu) {
  final theme = Theme.of(context);
  final s = UiV1SpacingTokens.standard;
  final density = UiV1DensityTokens.dense;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(s.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(hu.huNo, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(), tooltip: 'Close'),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Flexible(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.all(s.md),
              children: [_HuDetailContent(hu: hu, density: density, s: s, theme: theme)],
            ),
          ),
        ],
      ),
    ),
  );
}

class _HuDetailContent extends StatelessWidget {
  const _HuDetailContent({required this.hu, required this.density, required this.s, required this.theme});

  final HuMock hu;
  final UiV1DensityTokens density;
  final UiV1SpacingTokens s;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isShipped = hu.status == 'Shipped';
    final isOpen = hu.status == 'Open';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HuDetailRow(label: 'Type', value: hu.type),
        SizedBox(height: s.xs),
        _HuDetailRow(label: 'Status', value: hu.status),
        SizedBox(height: s.xs),
        _HuDetailRow(label: 'SSCC', value: hu.sscc ?? '—'),
        SizedBox(height: s.xs),
        _HuDetailRow(label: 'Lines', value: '${hu.linesCount}'),
        SizedBox(height: s.xs),
        _HuDetailRow(label: 'Total Qty', value: '${hu.totalQty}'),
        SizedBox(height: s.xs),
        if (hu.weight != null) _HuDetailRow(label: 'Weight', value: '${hu.weight}'),
        SizedBox(height: s.md),
        Text('Contents', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(height: s.xxs),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(UiV1RadiusTokens.standard.sm),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('SKU', style: theme.textTheme.labelSmall)),
                    Expanded(flex: 2, child: Text('Name', style: theme.textTheme.labelSmall)),
                    Expanded(flex: 1, child: Text('Packed', style: theme.textTheme.labelSmall)),
                  ],
                ),
              ),
              ...hu.contents.map((c) => Padding(
                padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(c.sku, overflow: TextOverflow.ellipsis, maxLines: 1, style: theme.textTheme.bodySmall)),
                    Expanded(flex: 2, child: Text(c.name, overflow: TextOverflow.ellipsis, maxLines: 1, style: theme.textTheme.bodySmall)),
                    Expanded(flex: 1, child: Text('${c.packedQty}', style: theme.textTheme.bodySmall)),
                  ],
                ),
              )),
            ],
          ),
        ),
        SizedBox(height: s.lg),
        Wrap(
          spacing: s.xs,
          runSpacing: s.xs,
          children: [
            _HuActionButton(
              label: 'Seal HU',
              onPressed: isShipped ? null : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seal HU (placeholder)'))),
              disabledReason: isShipped ? (kEHuShipped, 'HU уже отгружен.') : (isOpen ? (kEHuNotPacked, 'Сначала упакуйте HU.') : null),
              density: density,
            ),
            _HuActionButton(
              label: 'Print label',
              onPressed: isOpen ? null : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print label (placeholder)'))),
              disabledReason: isOpen ? (kEHuNotPacked, 'Нет SSCC для печати.') : null,
              density: density,
            ),
            _HuActionButton(
              label: 'Unpack',
              onPressed: isShipped ? null : (isOpen ? null : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unpack (placeholder)')))),
              disabledReason: isShipped ? (kEHuShipped, 'HU уже отгружен.') : (isOpen ? (kEHuNothingToUnpack, 'Нет содержимого для распаковки.') : null),
              density: density,
            ),
          ],
        ),
      ],
    );
  }
}

class _HuDetailRow extends StatelessWidget {
  const _HuDetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis, maxLines: 1)),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis, maxLines: 2)),
      ],
    );
  }
}

class _HuActionButton extends StatelessWidget {
  const _HuActionButton({
    required this.label,
    required this.onPressed,
    required this.disabledReason,
    required this.density,
  });
  final String label;
  final VoidCallback? onPressed;
  final (String code, String message)? disabledReason;
  final UiV1DensityTokens density;

  @override
  Widget build(BuildContext context) {
    if (disabledReason != null) {
      return Tooltip(
        message: '${disabledReason!.$1}: ${disabledReason!.$2}',
        child: FilledButton.tonal(
          onPressed: null,
          style: FilledButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
          child: Text(label),
        ),
      );
    }
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
      child: Text(label),
    );
  }
}
