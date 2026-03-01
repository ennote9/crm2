import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_shell/app_shell.dart';
import '../../components/bulk_action_bar/index.dart';
import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../components/toolbar/index.dart';
import '../../theme/density.dart';
import '../../utils/nav_item.dart';
import 'orders_list_state.dart';
import '../order_details/order_details_page.dart';

/// Demo page that shows the ui_v1 App Shell with DataGrid demo (Orders mock).
class UiV1PlaygroundPage extends StatefulWidget {
  const UiV1PlaygroundPage({super.key, required this.listState, this.onThemeToggle});

  final OrdersListState listState;
  final VoidCallback? onThemeToggle;

  @override
  State<UiV1PlaygroundPage> createState() => _UiV1PlaygroundPageState();
}

enum _DemoState { data, loading, empty, error }

/// Content width below which grid is replaced by card list.
const double _kBreakpointCardList = 850;

/// Content width below which card list uses ultra-compact layout (chip always on own row).
const double _kBreakpointUltraNarrow = 360;

class _UiV1PlaygroundPageState extends State<UiV1PlaygroundPage> {
  UiV1NavItem _currentNavId = UiV1NavItem.orders;
  _DemoState _demoState = _DemoState.data;
  Set<String> _selectedIds = {};
  late List<OrderMock> _mockOrders;

  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _mockOrders = _createMockOrders();
    _searchController = TextEditingController(text: widget.listState.searchText);
    _searchFocusNode = FocusNode();
    widget.listState.addListener(_onListStateChanged);
  }

  @override
  void dispose() {
    widget.listState.removeListener(_onListStateChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onListStateChanged() {
    if (!mounted) return;
    if (_searchController.text != widget.listState.searchText) {
      _searchController.text = widget.listState.searchText;
    }
    setState(() {});
  }

  static List<OrderMock> _createMockOrders() {
    final statuses = [
      'Draft', 'Released', 'Allocating', 'Picking', 'Packing', 'Packed',
      'Shipped', 'Closed', 'On Hold', 'Shortage', 'Cancelled', 'Allocated',
    ];
    final warehouses = ['WH-A', 'WH-B', 'WH-C'];
    return List.generate(15, (i) {
      return OrderMock(
        id: 'ORD-${1000 + i}',
        orderNo: 'ORD-${1000 + i}',
        status: statuses[i % statuses.length],
        warehouse: warehouses[i % warehouses.length],
        created: '2025-0${(i % 9) + 1}-${10 + (i % 20)}',
      );
    });
  }

  List<OrderMock> get _rows {
    List<OrderMock> list;
    switch (_demoState) {
      case _DemoState.data:
        list = _mockOrders;
        break;
      case _DemoState.empty:
        return [];
      case _DemoState.loading:
      case _DemoState.error:
        list = _mockOrders;
        break;
    }
    return _applyFilters(list);
  }

  List<OrderMock> _applyFilters(List<OrderMock> list) {
    final st = widget.listState;
    var result = list;
    final query = st.searchText.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((o) =>
        o.orderNo.toLowerCase().contains(query) ||
        o.warehouse.toLowerCase().contains(query) ||
        o.status.toLowerCase().contains(query),
      ).toList();
    }
    if (st.statusFilters.isNotEmpty) {
      result = result.where((o) => st.statusFilters.contains(o.status)).toList();
    }
    if (st.warehouseFilter != null) {
      result = result.where((o) => o.warehouse == st.warehouseFilter).toList();
    }
    switch (st.viewId) {
      case UiV1WorklistViewId.onHold:
        result = result.where((o) => o.status == 'On Hold').toList();
        break;
      case UiV1WorklistViewId.shortage:
        result = result.where((o) => o.status == 'Shortage').toList();
        break;
      case UiV1WorklistViewId.today:
        result = result.where((o) => o.created.startsWith('2025-01')).toList();
        break;
      case UiV1WorklistViewId.all:
      case UiV1WorklistViewId.custom:
        break;
      default:
        break;
    }
    return result;
  }

  void _applyViewPreset(UiV1WorklistViewId viewId) {
    widget.listState.setViewId(viewId);
    widget.listState.setIsCustomView(false);
    switch (viewId) {
      case UiV1WorklistViewId.all:
        widget.listState.setStatusFilters({});
        widget.listState.setWarehouseFilter(null);
        break;
      case UiV1WorklistViewId.onHold:
        widget.listState.setStatusFilters({'On Hold'});
        widget.listState.setWarehouseFilter(null);
        break;
      case UiV1WorklistViewId.shortage:
        widget.listState.setStatusFilters({'Shortage'});
        widget.listState.setWarehouseFilter(null);
        break;
      case UiV1WorklistViewId.today:
        widget.listState.setStatusFilters({});
        widget.listState.setWarehouseFilter(null);
        break;
      case UiV1WorklistViewId.custom:
      default:
        widget.listState.setStatusFilters({});
        widget.listState.setWarehouseFilter(null);
    }
  }

  void _onFiltersApplied(UiV1OrdersFiltersResult result) {
    widget.listState.setStatusFilters(result.statuses);
    widget.listState.setWarehouseFilter(result.warehouse);
    widget.listState.setIsCustomView(true);
  }

  List<UiV1FilterChipItem> get _filterChips {
    final st = widget.listState;
    final chips = <UiV1FilterChipItem>[];
    for (final s in st.statusFilters) {
      chips.add(UiV1FilterChipItem(
        label: 'Status: $s',
        onRemove: () {
          final next = Set<String>.from(st.statusFilters)..remove(s);
          widget.listState.setStatusFilters(next);
        },
      ));
    }
    if (st.warehouseFilter != null) {
      chips.add(UiV1FilterChipItem(
        label: 'Warehouse: ${st.warehouseFilter}',
        onRemove: () => widget.listState.setWarehouseFilter(null),
      ));
    }
    return chips;
  }

  void _onMoreReset() {
    widget.listState.reset();
    _searchController.text = widget.listState.searchText;
  }

  void _onDevStateSelected(String id) {
    setState(() {
      switch (id) {
        case 'data': _demoState = _DemoState.data; break;
        case 'loading': _demoState = _DemoState.loading; break;
        case 'empty': _demoState = _DemoState.empty; break;
        case 'error': _demoState = _DemoState.error; break;
      }
    });
  }

  void _openOrderDetails(BuildContext context, OrderMock row) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailsPage(
          payload: OrderDetailsPayload(
            orderNo: row.orderNo,
            status: row.status,
            warehouse: row.warehouse,
            created: row.created,
          ),
        ),
      ),
    );
  }

  /// Stats counts from current filtered list (when showStatistics is true).
  (int total, int inProgress, int onHold, int shortage) get _statsCounts {
    final list = _demoState == _DemoState.data ? _applyFilters(_mockOrders) : <OrderMock>[];
    int inProgress = 0;
    int onHold = 0;
    int shortage = 0;
    for (final o in list) {
      if (o.status == 'Allocating' || o.status == 'Picking' || o.status == 'Packing') inProgress++;
      if (o.status == 'On Hold') onHold++;
      if (o.status == 'Shortage') shortage++;
    }
    return (list.length, inProgress, onHold, shortage);
  }

  bool get _loading => _demoState == _DemoState.loading;
  String? get _errorMessage =>
      _demoState == _DemoState.error ? 'Something went wrong.' : null;

  List<Widget> _bulkActions(BuildContext context) {
    return [
      FilledButton.tonal(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hold (placeholder)')),
          );
        },
        child: const Text('Hold'),
      ),
      const SizedBox(width: 8),
      FilledButton.tonal(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unhold (placeholder)')),
          );
        },
        child: const Text('Unhold'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return UiV1AppShell(
      currentNavId: _currentNavId,
      onNavSelected: (id) => setState(() => _currentNavId = id),
      onThemeToggle: widget.onThemeToggle,
      onUserMenuTap: () {},
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): _ClearSelectionIntent(),
          SingleActivator(LogicalKeyboardKey.keyF, control: true): _FocusSearchIntent(),
          SingleActivator(LogicalKeyboardKey.keyF, meta: true): _FocusSearchIntent(),
        },
        child: Actions(
          actions: {
            _ClearSelectionIntent: CallbackAction<_ClearSelectionIntent>(
              onInvoke: (_) {
                if (_selectedIds.isNotEmpty) {
                  setState(() => _selectedIds = {});
                }
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
              UiV1CommandToolbar(
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                onSearchSubmit: () => widget.listState.setSearchText(_searchController.text),
                onSearchClear: () {
                  _searchController.clear();
                  widget.listState.setSearchText('');
                },
                filterChips: _filterChips,
                onFiltersTap: () => showUiV1OrdersFiltersPanel(
                  context: context,
                  initialStatuses: widget.listState.statusFilters,
                  initialWarehouse: widget.listState.warehouseFilter,
                  onApply: _onFiltersApplied,
                ),
                currentViewId: widget.listState.viewId,
                isCustomView: widget.listState.isCustomView,
                onViewSelected: _applyViewPreset,
                onMoreReset: _onMoreReset,
                onDevStateSelected: _onDevStateSelected,
                showStatistics: widget.listState.showStatistics,
                onShowStatisticsChanged: (v) => widget.listState.setShowStatistics(v),
              ),
              if (widget.listState.showStatistics) ...[
                UiV1OrdersStatsPanel(
                  total: _statsCounts.$1,
                  inProgress: _statsCounts.$2,
                  onHold: _statsCounts.$3,
                  shortage: _statsCounts.$4,
                ),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                final contentWidth = constraints.maxWidth;
                final useCardList = contentWidth < _kBreakpointCardList;

                if (useCardList) {
                  final ultraNarrow = contentWidth < _kBreakpointUltraNarrow;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _OrdersCardList(
                        rows: _rows,
                        selectedIds: _selectedIds,
                        onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
                        loading: _loading,
                        errorMessage: _errorMessage,
                        onRetry: () => setState(() => _demoState = _DemoState.data),
                        emptyMessage: 'No orders',
                        ultraNarrow: ultraNarrow,
                        onRowOpen: (row) => _openOrderDetails(context, row),
                        onRowActions: (row) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Actions for ${row.orderNo}')),
                          );
                        },
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: UiV1BulkActionBar(
                          selectedCount: _selectedIds.length,
                          onClearSelection: () => setState(() => _selectedIds = {}),
                          primaryActions: _bulkActions(context),
                        ),
                      ),
                    ],
                  );
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: UiV1DataGrid<OrderMock>(
                        columns: _orderColumns,
                        rows: _rows,
                        rowIdGetter: (r) => r.id,
                        selectedIds: _selectedIds,
                        onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
                        loading: _loading,
                        errorMessage: _errorMessage,
                        onRetry: () => setState(() => _demoState = _DemoState.data),
                        emptyMessage: 'No orders',
                        onRowOpen: (row) => _openOrderDetails(context, row),
                        showRowActions: true,
                        onRowActions: (row) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Actions for ${row.orderNo}')),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: UiV1BulkActionBar(
                        selectedCount: _selectedIds.length,
                        onClearSelection: () => setState(() => _selectedIds = {}),
                        primaryActions: _bulkActions(context),
                      ),
                    ),
                  ],
                );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<UiV1DataGridColumn<OrderMock>> get _orderColumns => [
        UiV1DataGridColumn<OrderMock>(
          id: 'orderNo',
          label: 'Order No',
          flex: 3,
          cellBuilder: (r) => Text(
            r.orderNo,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        UiV1DataGridColumn<OrderMock>(
          id: 'status',
          label: 'Status',
          flex: 2,
          cellBuilder: (r) => UiV1StatusChip(
            label: r.status,
            variant: UiV1StatusChip.variantFromStatus(r.status),
          ),
        ),
        UiV1DataGridColumn<OrderMock>(
          id: 'warehouse',
          label: 'Warehouse',
          flex: 2,
          cellBuilder: (r) => Text(
            r.warehouse,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        UiV1DataGridColumn<OrderMock>(
          id: 'created',
          label: 'Created',
          flex: 2,
          cellBuilder: (r) => Text(
            r.created,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ];
}

class _ClearSelectionIntent extends Intent {
  const _ClearSelectionIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

/// Card list for Orders when content width < 850. Multi-row layout to avoid overflow.
class _OrdersCardList extends StatelessWidget {
  const _OrdersCardList({
    required this.rows,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
    required this.emptyMessage,
    required this.ultraNarrow,
    required this.onRowOpen,
    required this.onRowActions,
  });

  final List<OrderMock> rows;
  final Set<String> selectedIds;
  final void Function(Set<String>) onSelectionChanged;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyMessage;
  final bool ultraNarrow;
  final void Function(OrderMock) onRowOpen;
  final void Function(OrderMock) onRowActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final density = UiV1DensityTokens.dense;
    final cardPadding = 12.0;

    if (loading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: 6,
        itemBuilder: (_, i) => Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (rows.isEmpty) {
      return Center(child: Text(emptyMessage, style: theme.textTheme.bodyLarge));
    }

    final padding = ultraNarrow ? 8.0 : cardPadding;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final selected = selectedIds.contains(row.id);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onRowOpen(row),
            child: ClipRect(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: checkbox + Order No + "..." (always fits)
                    Row(
                      children: [
                        SizedBox(
                          width: 40,
                          height: density.tableRowHeight,
                          child: Center(
                            child: Checkbox(
                              value: selected,
                              onChanged: (_) {
                                final next = Set<String>.from(selectedIds);
                                if (selected) {
                                  next.remove(row.id);
                                } else {
                                  next.add(row.id);
                                }
                                onSelectionChanged(next);
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.orderNo,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz, size: 20),
                          onPressed: () => onRowActions(row),
                          tooltip: 'Actions',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(32, 32),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Row 2: Warehouse + Created (up to 2 lines, ellipsis to avoid overflow)
                    Text(
                      '${row.warehouse} · ${row.created}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    // Row 3: Status chip (own line to avoid overflow)
                    UiV1StatusChip(
                      label: row.status,
                      variant: UiV1StatusChip.variantFromStatus(row.status),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OrderMock {
  OrderMock({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.warehouse,
    required this.created,
  });
  final String id;
  final String orderNo;
  final String status;
  final String warehouse;
  final String created;
}
