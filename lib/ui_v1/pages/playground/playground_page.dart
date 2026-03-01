import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_shell/app_shell.dart';
import '../../components/bulk_action_bar/index.dart';
import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../theme/density.dart';
import '../../utils/nav_item.dart';

/// Demo page that shows the ui_v1 App Shell with DataGrid demo (Orders mock).
class UiV1PlaygroundPage extends StatefulWidget {
  const UiV1PlaygroundPage({super.key, this.onThemeToggle});

  final VoidCallback? onThemeToggle;

  @override
  State<UiV1PlaygroundPage> createState() => _UiV1PlaygroundPageState();
}

enum _DemoState { data, loading, empty, error }

/// Content width below which grid is replaced by card list.
const double _kBreakpointCardList = 850;

/// Content width below which card list uses ultra-compact layout (chip always on own row).
const double _kBreakpointUltraNarrow = 360;

/// Content width below which toolbar shows single demo dropdown instead of 4 buttons.
const double _kBreakpointCompactToolbar = 520;

class _UiV1PlaygroundPageState extends State<UiV1PlaygroundPage> {
  UiV1NavItem _currentNavId = UiV1NavItem.orders;
  _DemoState _demoState = _DemoState.data;
  Set<String> _selectedIds = {};
  late List<OrderMock> _mockOrders;

  @override
  void initState() {
    super.initState();
    _mockOrders = _createMockOrders();
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
    switch (_demoState) {
      case _DemoState.data:
        return _mockOrders;
      case _DemoState.empty:
        return [];
      case _DemoState.loading:
      case _DemoState.error:
        return _mockOrders;
    }
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
    final theme = Theme.of(context);
    return UiV1AppShell(
      currentNavId: _currentNavId,
      onNavSelected: (id) => setState(() => _currentNavId = id),
      onThemeToggle: widget.onThemeToggle,
      onUserMenuTap: () {},
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): _ClearSelectionIntent(),
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
          },
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, toolbarConstraints) {
              final contentWidth = toolbarConstraints.maxWidth;
              final compactToolbar = contentWidth < _kBreakpointCompactToolbar;
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Text('Orders', style: theme.textTheme.titleLarge),
                    const SizedBox(width: 16),
                    if (compactToolbar)
                      DropdownButton<_DemoState>(
                        value: _demoState,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: _DemoState.data, child: Text('Data')),
                          DropdownMenuItem(value: _DemoState.loading, child: Text('Loading')),
                          DropdownMenuItem(value: _DemoState.empty, child: Text('Empty')),
                          DropdownMenuItem(value: _DemoState.error, child: Text('Error')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _demoState = v);
                        },
                      )
                    else
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            FilledButton.tonal(
                              onPressed: () => setState(() => _demoState = _DemoState.data),
                              child: const Text('Data'),
                            ),
                            OutlinedButton(
                              onPressed: () => setState(() => _demoState = _DemoState.loading),
                              child: const Text('Loading'),
                            ),
                            OutlinedButton(
                              onPressed: () => setState(() => _demoState = _DemoState.empty),
                              child: const Text('Empty'),
                            ),
                            OutlinedButton(
                              onPressed: () => setState(() => _demoState = _DemoState.error),
                              child: const Text('Error'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
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
                        onRowOpen: (row) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opened ${row.orderNo}')),
                          );
                        },
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
                        onRowOpen: (row) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opened ${row.orderNo}')),
                          );
                        },
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
          flex: 1,
          cellBuilder: (r) => Text(
            r.orderNo,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        UiV1DataGridColumn<OrderMock>(
          id: 'status',
          label: 'Status',
          flex: 1,
          cellBuilder: (r) => UiV1StatusChip(
            label: r.status,
            variant: UiV1StatusChip.variantFromStatus(r.status),
          ),
        ),
        UiV1DataGridColumn<OrderMock>(
          id: 'warehouse',
          label: 'Warehouse',
          flex: 1,
          cellBuilder: (r) => Text(
            r.warehouse,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        UiV1DataGridColumn<OrderMock>(
          id: 'created',
          label: 'Created',
          flex: 1,
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
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () => onRowActions(row),
                          tooltip: 'Actions',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Row 2: Warehouse + Created (one line, ellipsis)
                    Text(
                      '${row.warehouse} · ${row.created}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
