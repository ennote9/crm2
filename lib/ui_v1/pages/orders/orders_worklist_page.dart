// Orders worklist: first pilot consumer of Unified Table Platform v1.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/bulk_action_bar/index.dart';
import '../../components/chips/index.dart';
import '../../components/table_platform/index.dart';
import '../../demo_data/demo_data.dart';
import '../../icons/ui_icons.dart';
import '../../theme/density.dart';
import '../order_details/order_details_page.dart';
import 'orders_table_config.dart';

const double _kBreakpointCardList = 850;
const double _kBreakpointUltraNarrow = 360;

/// Orders list via Unified Table Platform: toolbar, stats, grid, saved views, current-view metrics.
class OrdersWorklistPage extends StatefulWidget {
  const OrdersWorklistPage({super.key, this.initialProductSku});

  final String? initialProductSku;

  @override
  State<OrdersWorklistPage> createState() => _OrdersWorklistPageState();
}

class _OrdersWorklistPageState extends State<OrdersWorklistPage> {
  late UnifiedTableController<DemoOrder> _controller;
  Set<String> _selectedIds = {};
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _controller = UnifiedTableController<DemoOrder>(
      config: createOrdersTableConfig(_openOrderDetails),
    );
    _searchController = TextEditingController(text: _controller.state.searchQuery);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<DemoOrder> get _fullList {
    if (widget.initialProductSku != null) {
      return demoRepository.getOrdersForProduct(widget.initialProductSku!);
    }
    return demoRepository.getOrders(const DemoOrdersFilters());
  }

  List<DemoOrder> get _visibleRows => _controller.getVisibleRows(_fullList);

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

  void _onSearchSubmit() {
    _controller.state = _controller.state.copyWithAsCustom(
      searchQuery: _searchController.text,
    );
    setState(() {});
  }

  void _onSearchClear() {
    _searchController.clear();
    _controller.state = _controller.state.copyWithAsCustom(searchQuery: '');
    setState(() {});
  }

  void _onReset() {
    _searchController.clear();
    _controller.state = _controller.config.initialState;
    setState(() {});
  }

  void _onFiltersTap() {
    showUnifiedViewPanel<DemoOrder>(
      context: context,
      controller: _controller,
      fullList: _fullList,
      onStateChanged: () => setState(() {}),
      initialTabIndex: 0,
    );
  }

  void _onViewPanelTap() {
    showUnifiedViewPanel<DemoOrder>(
      context: context,
      controller: _controller,
      fullList: _fullList,
      onStateChanged: () => setState(() {}),
    );
  }

  List<UnifiedFilterChipItem> get _filterChips {
    final config = _controller.config;
    return _controller.state.filters.map((d) {
      String columnLabel = d.columnId;
      for (final c in config.columns) {
        if (c.id == d.columnId) {
          columnLabel = c.label;
          break;
        }
      }
      final valueStr = d.toHumanReadableValueString();
      final label = valueStr.isEmpty ? columnLabel : '$columnLabel: $valueStr';
      return UnifiedFilterChipItem(
        label: label,
        onRemove: () {
          _controller.state = _controller.state.removeFilter(columnId: d.columnId);
          setState(() {});
        },
      );
    }).toList();
  }

  String? get _activeViewName {
    final id = _controller.state.activeViewId;
    if (id == null) return 'Custom';
    for (final v in _controller.config.savedViews) {
      if (v.id == id) return v.name;
    }
    return id;
  }

  Map<String, String> get _statsValues {
    final visible = _visibleRows;
    final raw = _controller.getStatsValues(visible);
    final out = <String, String>{};
    for (final e in raw.entries) {
      out[e.key] = _controller.formatMetricValue(e.key, e.value);
    }
    return out;
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
            UnifiedTableToolbar(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onSearchSubmit: _onSearchSubmit,
              onSearchClear: _onSearchClear,
              searchHint: 'Search order no, warehouse, status…',
              filterChips: _filterChips,
              onFiltersTap: _onFiltersTap,
              onViewPanelTap: _onViewPanelTap,
              onReset: _onReset,
              extraActions: widget.initialProductSku != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Product: ${widget.initialProductSku}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  : null,
              statsVisible: _controller.state.statsVisible,
            ),
            if (_controller.state.statsVisible) ...[
              UnifiedStatsPanel<DemoOrder>(
                metricDefinitions: _controller.config.availableMetrics,
                selectedMetricIds: _controller.state.selectedMetricIds,
                values: _statsValues,
              ),
            ],
            if (_controller.state.searchQuery.isNotEmpty ||
                _controller.state.filters.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: UnifiedFilterStateSummary(
                  searchQuery: _controller.state.searchQuery,
                  filterDescriptors: _controller.state.filters,
                  getColumnLabel: (id) {
                    for (final c in _controller.config.columns) {
                      if (c.id == id) return c.label;
                    }
                    return id;
                  },
                  onRemoveFilter: (columnId) {
                    _controller.state = _controller.state.removeFilter(columnId: columnId);
                    setState(() {});
                  },
                  viewName: _activeViewName,
                  onClearSearch: _onSearchClear,
                ),
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
                          rows: _visibleRows,
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
                        child: UnifiedTableGrid<DemoOrder>(
                          controller: _controller,
                          fullList: _fullList,
                          selectedIds: _selectedIds,
                          onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
                          loading: false,
                          errorMessage: null,
                          onRetry: null,
                          emptyMessage: 'No orders',
                          showRowActions: true,
                          showHeaderMenus: true,
                          onStateChanged: () => setState(() {}),
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
                FilledButton.icon(onPressed: onRetry, icon: const Icon(UiIcons.refresh), label: const Text('Retry')),
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
                          icon: const Icon(UiIcons.moreHoriz, size: 20),
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
