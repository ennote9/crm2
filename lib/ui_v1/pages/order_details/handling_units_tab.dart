// Handling Units tab v1: HU list, filters, search, HU detail drawer with contents.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../demo_data/demo_data.dart';
import '../../icons/ui_icons.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';
import '../products/sku_link_text.dart';

/// HU status: Open / Packed / Shipped
const List<String> kHuStatuses = ['Open', 'Packed', 'Shipped'];

enum HuFilter { all, open, packed, shipped }

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

/// Handling Units tab: filters + search + dense list. State preserved when switching tabs.
class HandlingUnitsTab extends StatefulWidget {
  const HandlingUnitsTab({super.key, this.orderNo, this.hus});

  final String? orderNo;
  final List<DemoHandlingUnit>? hus;

  @override
  State<HandlingUnitsTab> createState() => _HandlingUnitsTabState();
}

class _HandlingUnitsTabState extends State<HandlingUnitsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  HuFilter _filter = HuFilter.all;
  final TextEditingController _searchController = TextEditingController();

  late List<DemoHandlingUnit> _allHus;

  @override
  void initState() {
    super.initState();
    _allHus = List.from(widget.hus ?? []);
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

  List<DemoHandlingUnit> get _filteredRows {
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

  static List<UiV1DataGridColumn<DemoHandlingUnit>> get _columns => [
    UiV1DataGridColumn<DemoHandlingUnit>(id: 'huNo', label: 'Hu No', flex: 1, cellBuilder: (r) => Text(r.huNo, overflow: TextOverflow.ellipsis, maxLines: 1)),
    UiV1DataGridColumn<DemoHandlingUnit>(id: 'type', label: 'Type', flex: 1, cellBuilder: (r) => Text(r.type, overflow: TextOverflow.ellipsis, maxLines: 1)),
    UiV1DataGridColumn<DemoHandlingUnit>(id: 'status', label: 'Status', flex: 1, cellBuilder: (r) => UiV1StatusChip(label: r.status, variant: _huStatusVariant(r.status))),
    UiV1DataGridColumn<DemoHandlingUnit>(id: 'sscc', label: 'SSCC', flex: 2, cellBuilder: (r) => Text(r.sscc ?? '—', overflow: TextOverflow.ellipsis, maxLines: 1)),
    UiV1DataGridColumn<DemoHandlingUnit>(id: 'linesCount', label: 'Lines', flex: 1, cellBuilder: (r) => Text('${r.linesCount}', overflow: TextOverflow.ellipsis, maxLines: 1)),
    UiV1DataGridColumn<DemoHandlingUnit>(id: 'totalQty', label: 'Total Qty', flex: 1, cellBuilder: (r) => Text('${r.totalQty}', overflow: TextOverflow.ellipsis, maxLines: 1)),
    UiV1DataGridColumn<DemoHandlingUnit>(id: 'weight', label: 'Weight', flex: 1, cellBuilder: (r) => Text(r.weight != null ? '${r.weight}' : '—', overflow: TextOverflow.ellipsis, maxLines: 1)),
  ];

  void _openHuDetail(DemoHandlingUnit hu) {
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
                                  icon: const Icon(UiIcons.clear, size: 18),
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
                child: UiV1DataGrid<DemoHandlingUnit>(
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

void _showHuDetailDrawer(BuildContext context, DemoHandlingUnit hu) {
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
                      IconButton(icon: const Icon(UiIcons.close), onPressed: () => Navigator.of(context).pop(), tooltip: 'Close'),
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
                SizedBox(height: s.md),
                Padding(
                  padding: EdgeInsets.fromLTRB(s.md, 0, s.md, s.md),
                  child: _HuDetailActions(hu: hu, density: density),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _showHuDetailBottomSheet(BuildContext context, DemoHandlingUnit hu) {
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
                IconButton(icon: const Icon(UiIcons.close), onPressed: () => Navigator.of(context).pop(), tooltip: 'Close'),
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
          SizedBox(height: s.md),
          Padding(
            padding: EdgeInsets.fromLTRB(s.md, 0, s.md, s.md),
            child: _HuDetailActions(hu: hu, density: density),
          ),
        ],
      ),
    ),
  );
}

class _HuDetailContent extends StatelessWidget {
  const _HuDetailContent({required this.hu, required this.density, required this.s, required this.theme});

  final DemoHandlingUnit hu;
  final UiV1DensityTokens density;
  final UiV1SpacingTokens s;
  final ThemeData theme;

  static const double _contentsRowHeight = 32;

  @override
  Widget build(BuildContext context) {
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
              SizedBox(
                height: _contentsRowHeight,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: s.sm),
                  alignment: Alignment.centerLeft,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('SKU', style: theme.textTheme.labelSmall)),
                      Expanded(flex: 2, child: Text('Name', style: theme.textTheme.labelSmall)),
                      Expanded(flex: 1, child: Text('Packed', style: theme.textTheme.labelSmall)),
                    ],
                  ),
                ),
              ),
              ...hu.contents.map((c) => SizedBox(
                height: _contentsRowHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: s.sm),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SkuLinkText(sku: c.sku, style: theme.textTheme.bodySmall),
                      ),
                      Expanded(
                        flex: 2,
                        child: SkuLinkText(sku: c.sku, label: c.name, style: theme.textTheme.bodySmall),
                      ),
                      Expanded(flex: 1, child: Align(alignment: Alignment.centerLeft, child: Text('${c.packedQty}', style: theme.textTheme.bodySmall))),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _HuDetailActions extends StatelessWidget {
  const _HuDetailActions({required this.hu, required this.density});
  final DemoHandlingUnit hu;
  final UiV1DensityTokens density;

  @override
  Widget build(BuildContext context) {
    final isShipped = hu.status == 'Shipped';
    final isOpen = hu.status == 'Open';
    final s = UiV1SpacingTokens.standard;
    return Wrap(
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
