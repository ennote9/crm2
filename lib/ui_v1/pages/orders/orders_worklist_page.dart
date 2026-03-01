// Orders worklist: production list (toolbar + stats + grid/cards + bulk bar). State lives in page.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/bulk_action_bar/index.dart';
import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../components/toolbar/index.dart';
import '../../demo_data/demo_data.dart';
import '../../theme/density.dart';
import '../order_details/order_details_page.dart';

const double _kBreakpointCardList = 850;
const double _kBreakpointUltraNarrow = 360;

/// Production orders list: CommandToolbar, optional Stats panel, DataGrid/card list, BulkActionBar.
/// All state (search, filters, view, show statistics, selection) lives in this page;
/// preserved when navigating to OrderDetailsPage and back (push/pop).
class OrdersWorklistPage extends StatefulWidget {
  const OrdersWorklistPage({super.key});

  @override
  State<OrdersWorklistPage> createState() => _OrdersWorklistPageState();
}

class _OrdersWorklistPageState extends State<OrdersWorklistPage> {
  // Worklist state (preserved on push/pop to details)
  String _searchText = '';
  Set<String> _statusFilters = {};
  String? _warehouseFilter;
  UiV1WorklistViewId _viewId = UiV1WorklistViewId.all;
  bool _isCustomView = false;
  bool _showStatistics = false;
  Set<String> _selectedIds = {};
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _searchText);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<DemoOrder> get _rows => demoRepository.getOrders(DemoOrdersFilters(
    search: _searchText,
    statusFilters: _statusFilters,
    warehouse: _warehouseFilter,
    viewId: _viewId.id,
  ));

  void _applyViewPreset(UiV1WorklistViewId viewId) {
    setState(() {
      _viewId = viewId;
      _isCustomView = false;
      switch (viewId) {
        case UiV1WorklistViewId.all:
          _statusFilters = {};
          _warehouseFilter = null;
          break;
        case UiV1WorklistViewId.onHold:
          _statusFilters = {'On Hold'};
          _warehouseFilter = null;
          break;
        case UiV1WorklistViewId.shortage:
          _statusFilters = {'Shortage'};
          _warehouseFilter = null;
          break;
        case UiV1WorklistViewId.today:
          _statusFilters = {};
          _warehouseFilter = null;
          break;
        case UiV1WorklistViewId.custom:
        default:
          _statusFilters = {};
          _warehouseFilter = null;
      }
    });
  }

  void _onFiltersApplied(UiV1OrdersFiltersResult result) {
    setState(() {
      _statusFilters = Set.from(result.statuses);
      _warehouseFilter = result.warehouse;
      _isCustomView = true;
    });
  }

  List<UiV1FilterChipItem> get _filterChips {
    final chips = <UiV1FilterChipItem>[];
    for (final s in _statusFilters) {
      chips.add(UiV1FilterChipItem(
        label: 'Status: $s',
        onRemove: () {
          setState(() {
            final next = Set<String>.from(_statusFilters)..remove(s);
            _statusFilters = next;
          });
        },
      ));
    }
    if (_warehouseFilter != null) {
      chips.add(UiV1FilterChipItem(
        label: 'Warehouse: $_warehouseFilter',
        onRemove: () => setState(() => _warehouseFilter = null),
      ));
    }
    return chips;
  }

  void _onMoreReset() {
    setState(() {
      _searchText = '';
      _searchController.text = '';
      _statusFilters = {};
      _warehouseFilter = null;
      _viewId = UiV1WorklistViewId.all;
      _isCustomView = false;
    });
  }

  void _onSearchSubmit() {
    setState(() => _searchText = _searchController.text);
  }

  (int total, int inProgress, int onHold, int shortage) get _statsCounts {
    final list = _rows;
    var inProgress = 0, onHold = 0, shortage = 0;
    for (final o in list) {
      if (o.status == 'Allocating' || o.status == 'Picking' || o.status == 'Packing') inProgress++;
      if (o.status == 'On Hold') onHold++;
      if (o.status == 'Shortage') shortage++;
    }
    return (list.length, inProgress, onHold, shortage);
  }

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

  void _openOrderDetails(DemoOrder row) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailsPage(
          payload: OrderDetailsPayload(
            orderNo: row.orderNo,
            status: row.status,
            warehouse: row.warehouse,
            created: row.createdAt,
            baseStatus: row.status == 'On Hold' ? row.baseStatus ?? 'Allocated' : null,
          ),
        ),
      ),
    );
  }

  static List<UiV1DataGridColumn<DemoOrder>> get _orderColumns => [
    UiV1DataGridColumn<DemoOrder>(
      id: 'orderNo',
      label: 'Order No',
      flex: 3,
      cellBuilder: (r) => Text(r.orderNo, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoOrder>(
      id: 'status',
      label: 'Status',
      flex: 2,
      cellBuilder: (r) => UiV1StatusChip(
        label: r.status,
        variant: UiV1StatusChip.variantFromStatus(r.status),
      ),
    ),
    UiV1DataGridColumn<DemoOrder>(
      id: 'warehouse',
      label: 'Warehouse',
      flex: 2,
      cellBuilder: (r) => Text(r.warehouse, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoOrder>(
      id: 'created',
      label: 'Created',
      flex: 2,
      cellBuilder: (r) => Text(r.createdAt, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
            UiV1CommandToolbar(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onSearchSubmit: _onSearchSubmit,
              onSearchClear: () {
                _searchController.clear();
                setState(() => _searchText = '');
              },
              filterChips: _filterChips,
              onFiltersTap: () => showUiV1OrdersFiltersPanel(
                context: context,
                initialStatuses: _statusFilters,
                initialWarehouse: _warehouseFilter,
                onApply: _onFiltersApplied,
              ),
              currentViewId: _viewId,
              isCustomView: _isCustomView,
              onViewSelected: _applyViewPreset,
              onMoreReset: _onMoreReset,
              onDevStateSelected: null,
              showStatistics: _showStatistics,
              onShowStatisticsChanged: (v) => setState(() => _showStatistics = v),
            ),
            if (_showStatistics) ...[
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
                          loading: false,
                          errorMessage: null,
                          onRetry: null,
                          emptyMessage: 'No orders',
                          ultraNarrow: ultraNarrow,
                          onRowOpen: _openOrderDetails,
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
                        child: UiV1DataGrid<DemoOrder>(
                          columns: _orderColumns,
                          rows: _rows,
                          rowIdGetter: (r) => r.id,
                          selectedIds: _selectedIds,
                          onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
                          loading: false,
                          errorMessage: null,
                          onRetry: null,
                          emptyMessage: 'No orders',
                          onRowOpen: _openOrderDetails,
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
    );
  }
}

class _ClearSelectionIntent extends Intent {
  const _ClearSelectionIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

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

  final List<DemoOrder> rows;
  final Set<String> selectedIds;
  final void Function(Set<String>) onSelectionChanged;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyMessage;
  final bool ultraNarrow;
  final void Function(DemoOrder) onRowOpen;
  final void Function(DemoOrder) onRowActions;

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
              if (onRetry != null)
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
                    Text(
                      '${row.warehouse} · ${row.createdAt}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
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
