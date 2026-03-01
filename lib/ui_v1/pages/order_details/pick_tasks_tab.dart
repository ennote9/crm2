// Pick Tasks tab v1: task list with quick filters, search, task detail drawer/sheet. Mock data.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';
import 'order_lines_tab.dart';

/// Pick task status for list and filters. Display as chip.
const List<String> kPickTaskStatuses = ['Open', 'In Progress', 'Done', 'Exception'];

/// Filter segment: All | Open | In Progress | Done | Exceptions
enum PickTaskFilter { all, open, inProgress, done, exceptions }

/// Mock row for one pick task.
class PickTaskMock {
  PickTaskMock({
    required this.id,
    required this.taskNo,
    required this.status,
    required this.zone,
    required this.location,
    required this.sku,
    required this.qty,
    required this.pickedQty,
  });
  final String id;
  final String taskNo;
  final String status;
  final String zone;
  final String location;
  final String sku;
  final int qty;
  final int pickedQty;
}

UiV1StatusVariant _pickTaskStatusVariant(String status) {
  final s = status.toLowerCase();
  if (s == 'open') return UiV1StatusVariant.neutral;
  if (s == 'in progress') return UiV1StatusVariant.inProgress;
  if (s == 'done') return UiV1StatusVariant.success;
  if (s == 'exception') return UiV1StatusVariant.warning;
  return UiV1StatusVariant.neutral;
}

/// Creates pick tasks from order lines (used when allocate runs and tasks empty). One task per line.
List<PickTaskMock> createPickTasksFromLines(List<OrderLineMock> lines, String orderNo) {
  final seed = (orderNo.hashCode & 0x7FFF);
  final zones = ['A', 'A', 'B', 'A', 'B'];
  final locations = ['A-01-02', 'A-02-01', 'B-01-01', 'A-01-03', 'B-02-02'];
  return List.generate(lines.length, (i) {
    final line = lines[i];
    final qty = line.reserved > 0 ? line.reserved : line.ordered;
    return PickTaskMock(
      id: 'PT-$seed-${i + 1}',
      taskNo: 'PT-${i + 1}',
      status: 'Open',
      zone: zones[i % zones.length],
      location: locations[i % locations.length],
      sku: line.sku,
      qty: qty,
      pickedQty: 0,
    );
  });
}

/// Pick Tasks tab: filters + search + dense list. State preserved when switching tabs.
class PickTasksTab extends StatefulWidget {
  const PickTasksTab({super.key, this.orderNo, this.tasks});

  final String? orderNo;
  /// When provided, tab uses this list (e.g. from page state after allocate).
  final List<PickTaskMock>? tasks;

  @override
  State<PickTasksTab> createState() => _PickTasksTabState();
}

class _PickTasksTabState extends State<PickTasksTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  PickTaskFilter _filter = PickTaskFilter.all;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static List<PickTaskMock> _mockTasks(String? orderNo) {
    final statuses = ['Open', 'Open', 'In Progress', 'Done', 'Done', 'Exception', 'Open', 'In Progress', 'Done', 'Open', 'In Progress', 'Exception', 'Done', 'Open', 'In Progress'];
    final zones = ['A', 'A', 'B', 'A', 'B', 'B', 'A', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B'];
    final locations = ['A-01-02', 'A-02-01', 'B-01-01', 'A-01-03', 'B-02-02', 'B-01-03', 'A-03-01', 'A-01-04', 'B-02-01', 'A-02-02', 'B-01-02', 'A-02-03', 'B-03-01', 'A-01-05', 'B-02-03'];
    final skus = ['SKU-001', 'SKU-002', 'SKU-003', 'SKU-001', 'SKU-004', 'SKU-002', 'SKU-005', 'SKU-003', 'SKU-001', 'SKU-004', 'SKU-002', 'SKU-005', 'SKU-003', 'SKU-006', 'SKU-004'];
    final qtys = [10, 5, 20, 10, 3, 5, 8, 20, 10, 3, 5, 8, 20, 4, 3];
    final pickedQtys = [0, 0, 20, 10, 0, 2, 0, 15, 10, 0, 3, 0, 20, 0, 2];
    return List.generate(15, (i) => PickTaskMock(
      id: 'PT-${((orderNo ?? 'ORD').hashCode & 0x7FFF)}-${i + 1}',
      taskNo: 'PT-${i + 1}',
      status: statuses[i],
      zone: zones[i],
      location: locations[i],
      sku: skus[i],
      qty: qtys[i],
      pickedQty: pickedQtys[i],
    ));
  }

  late List<PickTaskMock> _allTasks;

  @override
  void initState() {
    super.initState();
    _allTasks = widget.tasks ?? _mockTasks(widget.orderNo);
  }

  @override
  void didUpdateWidget(PickTasksTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != null && widget.tasks != oldWidget.tasks) {
      _allTasks = List.from(widget.tasks!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<PickTaskMock> get _filteredRows {
    var list = _allTasks;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) =>
        t.sku.toLowerCase().contains(query) ||
        t.location.toLowerCase().contains(query) ||
        t.taskNo.toLowerCase().contains(query) ||
        t.zone.toLowerCase().contains(query),
      ).toList();
    }
    switch (_filter) {
      case PickTaskFilter.all:
        break;
      case PickTaskFilter.open:
        list = list.where((t) => t.status == 'Open').toList();
        break;
      case PickTaskFilter.inProgress:
        list = list.where((t) => t.status == 'In Progress').toList();
        break;
      case PickTaskFilter.done:
        list = list.where((t) => t.status == 'Done').toList();
        break;
      case PickTaskFilter.exceptions:
        list = list.where((t) => t.status == 'Exception').toList();
        break;
    }
    return list;
  }

  static List<UiV1DataGridColumn<PickTaskMock>> get _columns => [
    UiV1DataGridColumn<PickTaskMock>(
      id: 'taskNo',
      label: 'Task No',
      flex: 1,
      cellBuilder: (r) => Text(r.taskNo, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<PickTaskMock>(
      id: 'status',
      label: 'Status',
      flex: 1,
      cellBuilder: (r) => UiV1StatusChip(
        label: r.status,
        variant: _pickTaskStatusVariant(r.status),
      ),
    ),
    UiV1DataGridColumn<PickTaskMock>(
      id: 'zone',
      label: 'Zone',
      flex: 1,
      cellBuilder: (r) => Text(r.zone, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<PickTaskMock>(
      id: 'location',
      label: 'Location',
      flex: 2,
      cellBuilder: (r) => Text(r.location, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<PickTaskMock>(
      id: 'sku',
      label: 'SKU',
      flex: 2,
      cellBuilder: (r) => Text(r.sku, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<PickTaskMock>(
      id: 'qty',
      label: 'Qty',
      flex: 1,
      cellBuilder: (r) => Text('${r.qty}', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<PickTaskMock>(
      id: 'pickedQty',
      label: 'Picked',
      flex: 1,
      cellBuilder: (r) => Text('${r.pickedQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
  ];

  void _openTaskDetail(PickTaskMock task) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 600) {
      _showTaskDetailDrawer(context, task);
    } else {
      _showTaskDetailBottomSheet(context, task);
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
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.escape): _ClearSearchIntent(),
      },
      child: Actions(
        actions: {
          _ClearSearchIntent: CallbackAction<_ClearSearchIntent>(
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
                  SegmentedButton<PickTaskFilter>(
                    segments: [
                      ButtonSegment<PickTaskFilter>(value: PickTaskFilter.all, label: const Text('All')),
                      ButtonSegment<PickTaskFilter>(value: PickTaskFilter.open, label: const Text('Open')),
                      ButtonSegment<PickTaskFilter>(value: PickTaskFilter.inProgress, label: const Text('In Progress')),
                      ButtonSegment<PickTaskFilter>(value: PickTaskFilter.done, label: const Text('Done')),
                      ButtonSegment<PickTaskFilter>(value: PickTaskFilter.exceptions, label: const Text('Exceptions')),
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
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search SKU, Location…',
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
                        onSubmitted: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: s.sm),
              Expanded(
                child: UiV1DataGrid<PickTaskMock>(
                  columns: _columns,
                  rows: _filteredRows,
                  rowIdGetter: (r) => r.id,
                  selectedIds: {},
                  onSelectionChanged: null,
                  showRowActions: false,
                  density: UiV1Density.dense,
                  emptyMessage: 'No pick tasks',
                  onRowOpen: _openTaskDetail,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClearSearchIntent extends Intent {}

void _showTaskDetailDrawer(BuildContext context, PickTaskMock task) {
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
            width: 400,
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
                          task.taskNo,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(s.md),
                    child: _TaskDetailContent(task: task, density: density, s: s, theme: theme),
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

void _showTaskDetailBottomSheet(BuildContext context, PickTaskMock task) {
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
                  child: Text(
                    task.taskNo,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Flexible(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.all(s.md),
              children: [
                _TaskDetailContent(task: task, density: density, s: s, theme: theme),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TaskDetailContent extends StatelessWidget {
  const _TaskDetailContent({
    required this.task,
    required this.density,
    required this.s,
    required this.theme,
  });

  final PickTaskMock task;
  final UiV1DensityTokens density;
  final UiV1SpacingTokens s;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow(label: 'Status', value: task.status),
        SizedBox(height: s.xs),
        _DetailRow(label: 'Zone', value: task.zone),
        SizedBox(height: s.xs),
        _DetailRow(label: 'Location', value: task.location),
        SizedBox(height: s.xs),
        _DetailRow(label: 'SKU', value: task.sku),
        SizedBox(height: s.xs),
        _DetailRow(label: 'Qty', value: '${task.qty}'),
        SizedBox(height: s.xs),
        _DetailRow(label: 'Picked', value: '${task.pickedQty}'),
        SizedBox(height: s.xl),
        Wrap(
          spacing: s.xs,
          runSpacing: s.xs,
          children: [
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start (placeholder)')));
              },
              style: FilledButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
              child: const Text('Start'),
            ),
            FilledButton.tonal(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete (placeholder)')));
              },
              style: FilledButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
              child: const Text('Complete'),
            ),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report exception (placeholder)')));
              },
              style: OutlinedButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
              child: const Text('Report exception'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
