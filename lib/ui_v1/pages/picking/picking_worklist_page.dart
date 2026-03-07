// Picking Worklist v1: all pick tasks from DemoRepository, filters, open order details (Pick Tasks tab).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../demo_data/demo_data.dart';
import '../../theme/tokens.dart';
import '../order_details/order_details_page.dart';
import '../products/sku_link_text.dart';

/// Quick filters: All | Open | In Progress | Done | Exceptions
enum PickingWorklistFilter {
  all,
  open,
  inProgress,
  done,
  exceptions,
}

/// Picking worklist: all pick tasks from repo, dense grid, open order with Pick Tasks tab.
class PickingWorklistPage extends StatefulWidget {
  const PickingWorklistPage({super.key, this.initialSearch});

  /// Pre-fill search (e.g. SKU from Product Details).
  final String? initialSearch;

  @override
  State<PickingWorklistPage> createState() => _PickingWorklistPageState();
}

class _PickingWorklistPageState extends State<PickingWorklistPage> {
  late String _searchText;
  PickingWorklistFilter _filter = PickingWorklistFilter.all;
  Set<String> _selectedIds = {};
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchText = widget.initialSearch ?? '';
    _searchController = TextEditingController(text: _searchText);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<DemoPickTask> get _allTasks => demoRepository.getAllPickTasks();

  List<DemoPickTask> get _rows {
    var list = _allTasks;
    final query = _searchText.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) {
        final orderNo = t.orderNo ?? '';
        return t.taskNo.toLowerCase().contains(query) ||
            orderNo.toLowerCase().contains(query) ||
            t.sku.toLowerCase().contains(query) ||
            t.location.toLowerCase().contains(query);
      }).toList();
    }
    switch (_filter) {
      case PickingWorklistFilter.all:
        break;
      case PickingWorklistFilter.open:
        list = list.where((t) => t.status == 'Open').toList();
        break;
      case PickingWorklistFilter.inProgress:
        list = list.where((t) => t.status == 'In Progress').toList();
        break;
      case PickingWorklistFilter.done:
        list = list.where((t) => t.status == 'Done').toList();
        break;
      case PickingWorklistFilter.exceptions:
        list = list.where((t) => t.status == 'Exception').toList();
        break;
    }
    return list;
  }

  void _onSearchSubmit() {
    setState(() => _searchText = _searchController.text);
  }

  void _openOrderDetails(DemoPickTask task) {
    final orderNo = task.orderNo;
    if (orderNo == null || orderNo.isEmpty) return;
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
            initialTabIndex: 1,
          ),
        ),
      ),
    );
  }

  static UiV1StatusVariant _statusVariant(String status) {
    final s = status.toLowerCase();
    if (s == 'open') return UiV1StatusVariant.neutral;
    if (s == 'in progress') return UiV1StatusVariant.inProgress;
    if (s == 'done') return UiV1StatusVariant.success;
    if (s == 'exception') return UiV1StatusVariant.warning;
    return UiV1StatusVariant.neutral;
  }

  static List<UiV1DataGridColumn<DemoPickTask>> get _columns => [
    UiV1DataGridColumn<DemoPickTask>(
      id: 'taskNo',
      label: 'Task No',
      flex: 1,
      cellBuilder: (r) => Text(r.taskNo, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoPickTask>(
      id: 'orderNo',
      label: 'Order No',
      flex: 2,
      cellBuilder: (r) => Text(r.orderNo ?? '—', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoPickTask>(
      id: 'status',
      label: 'Status',
      flex: 1,
      cellBuilder: (r) => UiV1StatusChip(label: r.status, variant: _statusVariant(r.status)),
    ),
    UiV1DataGridColumn<DemoPickTask>(
      id: 'zone',
      label: 'Zone',
      flex: 1,
      cellBuilder: (r) => Text(r.zone, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoPickTask>(
      id: 'location',
      label: 'Location',
      flex: 2,
      cellBuilder: (r) => Text(r.location, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoPickTask>(
      id: 'sku',
      label: 'SKU',
      flex: 2,
      cellBuilder: (r) => SkuLinkText(sku: r.sku),
    ),
    UiV1DataGridColumn<DemoPickTask>(
      id: 'qty',
      label: 'Qty',
      flex: 1,
      cellBuilder: (r) => Text('${r.qty}', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoPickTask>(
      id: 'pickedQty',
      label: 'Picked Qty',
      flex: 1,
      cellBuilder: (r) => Text('${r.pickedQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
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
                  SegmentedButton<PickingWorklistFilter>(
                    segments: const [
                      ButtonSegment<PickingWorklistFilter>(value: PickingWorklistFilter.all, label: Text('All')),
                      ButtonSegment<PickingWorklistFilter>(value: PickingWorklistFilter.open, label: Text('Open')),
                      ButtonSegment<PickingWorklistFilter>(value: PickingWorklistFilter.inProgress, label: Text('In Progress')),
                      ButtonSegment<PickingWorklistFilter>(value: PickingWorklistFilter.done, label: Text('Done')),
                      ButtonSegment<PickingWorklistFilter>(value: PickingWorklistFilter.exceptions, label: Text('Exceptions')),
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
                        _filter = PickingWorklistFilter.all;
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
                child: UiV1DataGrid<DemoPickTask>(
                  columns: _columns,
                  rows: _rows,
                  rowIdGetter: (r) => r.id,
                  selectedIds: _selectedIds,
                  onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
                  loading: false,
                  errorMessage: null,
                  onRetry: null,
                  emptyMessage: 'No pick tasks',
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
