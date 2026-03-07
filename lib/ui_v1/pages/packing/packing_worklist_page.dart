// Packing Worklist v1: all packing tasks from DemoRepository, filters, open order details (HU tab).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../demo_data/demo_data.dart';
import '../../theme/tokens.dart';
import '../order_details/order_details_page.dart';
import '../products/sku_link_text.dart';

/// Quick filters: All | Open | In Progress | Packed | Exceptions
enum PackingWorklistFilter {
  all,
  open,
  inProgress,
  packed,
  exceptions,
}

/// Packing worklist: all packing tasks from repo, dense grid, open order with HU tab.
class PackingWorklistPage extends StatefulWidget {
  const PackingWorklistPage({super.key, this.initialSearch, this.initialFilterExceptions = false});

  /// Pre-fill search (e.g. SKU from Product Details).
  final String? initialSearch;
  /// When true, set filter to Exceptions (e.g. from Product Details).
  final bool initialFilterExceptions;

  @override
  State<PackingWorklistPage> createState() => _PackingWorklistPageState();
}

class _PackingWorklistPageState extends State<PackingWorklistPage> {
  late String _searchText;
  late PackingWorklistFilter _filter;
  Set<String> _selectedIds = {};
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchText = widget.initialSearch ?? '';
    _filter = widget.initialFilterExceptions ? PackingWorklistFilter.exceptions : PackingWorklistFilter.all;
    _searchController = TextEditingController(text: _searchText);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<DemoPackingTask> get _allTasks => demoRepository.getAllPackingTasks();

  List<DemoPackingTask> get _rows {
    var list = _allTasks;
    final query = _searchText.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) {
        return t.taskNo.toLowerCase().contains(query) ||
            t.orderNo.toLowerCase().contains(query) ||
            t.sku.toLowerCase().contains(query);
      }).toList();
    }
    switch (_filter) {
      case PackingWorklistFilter.all:
        break;
      case PackingWorklistFilter.open:
        list = list.where((t) => t.status == 'Open').toList();
        break;
      case PackingWorklistFilter.inProgress:
        list = list.where((t) => t.status == 'In Progress').toList();
        break;
      case PackingWorklistFilter.packed:
        list = list.where((t) => t.status == 'Packed').toList();
        break;
      case PackingWorklistFilter.exceptions:
        list = list.where((t) => t.status == 'Exception').toList();
        break;
    }
    return list;
  }

  void _onSearchSubmit() {
    setState(() => _searchText = _searchController.text);
  }

  void _openOrderDetails(DemoPackingTask task) {
    final orderNo = task.orderNo;
    if (orderNo.isEmpty) return;
    final bundle = demoRepository.getOrderDetails(orderNo);
    final order = bundle.order;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailsPage(
          payload: OrderDetailsPayload(
            orderNo: order.orderNo,
            status: order.status,
            warehouse: order.warehouse,
            created: order.createdAt,
            baseStatus: order.status == 'On Hold' ? (order.baseStatus ?? 'Allocated') : null,
            initialTabIndex: 2,
          ),
        ),
      ),
    );
  }

  static UiV1StatusVariant _statusVariant(String status) {
    final s = status.toLowerCase();
    if (s == 'open') return UiV1StatusVariant.neutral;
    if (s == 'in progress') return UiV1StatusVariant.inProgress;
    if (s == 'packed') return UiV1StatusVariant.success;
    if (s == 'exception') return UiV1StatusVariant.warning;
    return UiV1StatusVariant.neutral;
  }

  static List<UiV1DataGridColumn<DemoPackingTask>> get _columns => [
    UiV1DataGridColumn<DemoPackingTask>(
      id: 'taskNo',
      label: 'Task No',
      flex: 1,
      cellBuilder: (r) => Text(r.taskNo, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoPackingTask>(
      id: 'orderNo',
      label: 'Order No',
      flex: 2,
      cellBuilder: (r) => Text(r.orderNo, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoPackingTask>(
      id: 'status',
      label: 'Status',
      flex: 1,
      cellBuilder: (r) => UiV1StatusChip(label: r.status, variant: _statusVariant(r.status)),
    ),
    UiV1DataGridColumn<DemoPackingTask>(
      id: 'sku',
      label: 'SKU',
      flex: 2,
      cellBuilder: (r) => SkuLinkText(sku: r.sku),
    ),
    UiV1DataGridColumn<DemoPackingTask>(
      id: 'pickedQty',
      label: 'Picked Qty',
      flex: 1,
      cellBuilder: (r) => Text('${r.pickedQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoPackingTask>(
      id: 'packedQty',
      label: 'Packed Qty',
      flex: 1,
      cellBuilder: (r) => Text('${r.packedQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoPackingTask>(
      id: 'shortQty',
      label: 'Short Qty',
      flex: 1,
      cellBuilder: (r) => Text('${r.shortQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoPackingTask>(
      id: 'warehouse',
      label: 'Warehouse',
      flex: 1,
      cellBuilder: (r) => Text(r.warehouse, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _ClearSelectionIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true): _FocusSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, meta: true): _FocusSearchIntent(),
      },
      child: Actions(
        actions: {
          _ClearSelectionIntent: CallbackAction<_ClearSelectionIntent>(
            onInvoke: (_) {
              if (_selectedIds.isNotEmpty) setState(() => _selectedIds = {});
              return null;
            },
          ),
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) {
              FocusScope.of(context).requestFocus(_searchFocusNode);
              return null;
            },
          ),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(s.xl, s.md, s.xl, s.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 220,
                    height: 32,
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onSubmitted: (_) => _onSearchSubmit(),
                      decoration: InputDecoration(
                        hintText: 'Search taskNo, orderNo, SKU…',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(tokens.radius.sm),
                        ),
                        suffixIcon: ListenableBuilder(
                          listenable: _searchController,
                          builder: (_, child) => _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchText = '');
                                  },
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(32, 32),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: s.sm),
                  SegmentedButton<PackingWorklistFilter>(
                    segments: const [
                      ButtonSegment<PackingWorklistFilter>(value: PackingWorklistFilter.all, label: Text('All')),
                      ButtonSegment<PackingWorklistFilter>(value: PackingWorklistFilter.open, label: Text('Open')),
                      ButtonSegment<PackingWorklistFilter>(value: PackingWorklistFilter.inProgress, label: Text('In Progress')),
                      ButtonSegment<PackingWorklistFilter>(value: PackingWorklistFilter.packed, label: Text('Packed')),
                      ButtonSegment<PackingWorklistFilter>(value: PackingWorklistFilter.exceptions, label: Text('Exceptions')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (v) => setState(() => _filter = v.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: s.sm, vertical: 6)),
                      textStyle: WidgetStateProperty.all(theme.textTheme.labelMedium),
                    ),
                  ),
                  SizedBox(width: s.sm),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchText = '';
                        _filter = PackingWorklistFilter.all;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: UiV1DataGrid<DemoPackingTask>(
                  columns: _columns,
                  rows: _rows,
                  rowIdGetter: (r) => r.id,
                  selectedIds: _selectedIds,
                  onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
                  loading: false,
                  errorMessage: null,
                  onRetry: null,
                  emptyMessage: 'No packing tasks',
                  onRowOpen: _openOrderDetails,
                  showRowActions: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearSelectionIntent extends Intent {
  const _ClearSelectionIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}
