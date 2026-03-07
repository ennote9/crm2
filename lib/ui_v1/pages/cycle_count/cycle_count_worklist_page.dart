// Cycle Count Worklist v1: list of count tasks, filters, open count task details.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../components/icon_widget.dart';
import '../../demo_data/demo_data.dart';
import '../../icons/ui_icons.dart';
import '../../theme/tokens.dart';
import '../products/sku_link_text.dart';
import 'count_task_details_page.dart';

enum CycleCountWorklistFilter {
  all,
  open,
  counted,
  posted,
  cancelled,
  varianceOnly,
}

class CycleCountWorklistPage extends StatefulWidget {
  const CycleCountWorklistPage({super.key, this.initialSearch});

  final String? initialSearch;

  @override
  State<CycleCountWorklistPage> createState() => _CycleCountWorklistPageState();
}

class _CycleCountWorklistPageState extends State<CycleCountWorklistPage> {
  late String _searchText;
  CycleCountWorklistFilter _filter = CycleCountWorklistFilter.all;
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

  List<DemoCountTask> get _rows {
    final filterStr = _filter == CycleCountWorklistFilter.all
        ? 'all'
        : _filter == CycleCountWorklistFilter.open
            ? 'open'
            : _filter == CycleCountWorklistFilter.counted
                ? 'counted'
                : _filter == CycleCountWorklistFilter.posted
                    ? 'posted'
                    : _filter == CycleCountWorklistFilter.cancelled
                        ? 'cancelled'
                        : 'variance_only';
    return demoRepository.getCountTasks(search: _searchText, filter: filterStr);
  }

  void _onSearchSubmit() {
    setState(() => _searchText = _searchController.text);
  }

  void _openTaskDetails(DemoCountTask task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CountTaskDetailsPage(payload: CountTaskDetailsPayload(taskId: task.id)),
      ),
    ).then((_) => setState(() {}));
  }

  static UiV1StatusVariant _statusVariant(String status) {
    switch (status) {
      case 'Draft':
        return UiV1StatusVariant.neutral;
      case 'Released':
        return UiV1StatusVariant.info;
      case 'Counted':
        return UiV1StatusVariant.warning;
      case 'Posted':
        return UiV1StatusVariant.success;
      case 'Cancelled':
        return UiV1StatusVariant.danger;
      default:
        return UiV1StatusVariant.neutral;
    }
  }

  static List<UiV1DataGridColumn<DemoCountTask>> _columns(BuildContext context) {
    return [
      UiV1DataGridColumn<DemoCountTask>(
        id: 'countNo',
        label: 'Count No',
        flex: 1,
        cellBuilder: (r) => Text(r.countNo, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoCountTask>(
        id: 'warehouse',
        label: 'Warehouse',
        flex: 1,
        cellBuilder: (r) => Text(r.warehouse, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoCountTask>(
        id: 'location',
        label: 'Location',
        flex: 1,
        cellBuilder: (r) => Text(r.location, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoCountTask>(
        id: 'sku',
        label: 'SKU',
        flex: 1,
        cellBuilder: (r) => SkuLinkText(sku: r.sku),
      ),
      UiV1DataGridColumn<DemoCountTask>(
        id: 'product',
        label: 'Product',
        flex: 2,
        cellBuilder: (r) => Text(r.productName, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoCountTask>(
        id: 'expected',
        label: 'Expected',
        flex: 1,
        cellBuilder: (r) => Text('${r.expectedQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoCountTask>(
        id: 'counted',
        label: 'Counted',
        flex: 1,
        cellBuilder: (r) => Text(r.countedQty != null ? '${r.countedQty}' : '—', overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoCountTask>(
        id: 'variance',
        label: 'Variance',
        flex: 1,
        cellBuilder: (r) {
          final v = r.varianceQty;
          if (r.countedQty == null) return Text('—', overflow: TextOverflow.ellipsis, maxLines: 1);
          return Text('$v', overflow: TextOverflow.ellipsis, maxLines: 1);
        },
      ),
      UiV1DataGridColumn<DemoCountTask>(
        id: 'status',
        label: 'Status',
        flex: 1,
        cellBuilder: (r) => UiV1StatusChip(label: r.status, variant: _statusVariant(r.status)),
      ),
      UiV1DataGridColumn<DemoCountTask>(
        id: 'created',
        label: 'Created',
        flex: 1,
        cellBuilder: (r) => Text(r.createdAt, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    ];
  }

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
                        hintText: 'Search count no, SKU, location, product…',
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
                          builder: (context, _) => _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const UiV1Icon(icon: UiIcons.clear, size: 18),
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
                  SegmentedButton<CycleCountWorklistFilter>(
                    segments: const [
                      ButtonSegment<CycleCountWorklistFilter>(value: CycleCountWorklistFilter.all, label: Text('All')),
                      ButtonSegment<CycleCountWorklistFilter>(value: CycleCountWorklistFilter.open, label: Text('Open')),
                      ButtonSegment<CycleCountWorklistFilter>(value: CycleCountWorklistFilter.counted, label: Text('Counted')),
                      ButtonSegment<CycleCountWorklistFilter>(value: CycleCountWorklistFilter.posted, label: Text('Posted')),
                      ButtonSegment<CycleCountWorklistFilter>(value: CycleCountWorklistFilter.cancelled, label: Text('Cancelled')),
                      ButtonSegment<CycleCountWorklistFilter>(value: CycleCountWorklistFilter.varianceOnly, label: Text('Variance only')),
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
                        _filter = CycleCountWorklistFilter.all;
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
                child: UiV1DataGrid<DemoCountTask>(
                  columns: _columns(context),
                  rows: _rows,
                  rowIdGetter: (r) => r.id,
                  selectedIds: _selectedIds,
                  onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
                  loading: false,
                  errorMessage: null,
                  onRetry: null,
                  emptyMessage: 'No count tasks',
                  onRowOpen: _openTaskDetails,
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
