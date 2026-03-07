// Movements Worklist v1: internal movements list, filters, open movement details.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../components/icon_widget.dart';
import '../../demo_data/demo_data.dart';
import '../../icons/ui_icons.dart';
import '../../theme/tokens.dart';
import '../products/sku_link_text.dart';
import 'movement_details_page.dart';

/// Quick filters: All | Open | In Progress | Done | Cancelled
enum MovementsWorklistFilter {
  all,
  open,
  inProgress,
  done,
  cancelled,
}

/// Movements worklist: all movements from repo, dense grid, open movement details on row tap.
class MovementsWorklistPage extends StatefulWidget {
  const MovementsWorklistPage({super.key, this.initialSearch});

  final String? initialSearch;

  @override
  State<MovementsWorklistPage> createState() => _MovementsWorklistPageState();
}

class _MovementsWorklistPageState extends State<MovementsWorklistPage> {
  late String _searchText;
  MovementsWorklistFilter _filter = MovementsWorklistFilter.all;
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

  List<DemoMovement> get _rows {
    var list = demoRepository.getMovements();
    final query = _searchText.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((m) =>
        m.movementNo.toLowerCase().contains(query) ||
        m.sku.toLowerCase().contains(query) ||
        m.productName.toLowerCase().contains(query) ||
        m.fromLocation.toLowerCase().contains(query) ||
        m.toLocation.toLowerCase().contains(query) ||
        m.warehouse.toLowerCase().contains(query),
      ).toList();
    }
    switch (_filter) {
      case MovementsWorklistFilter.all:
        break;
      case MovementsWorklistFilter.open:
        list = list.where((m) => m.status == 'Draft' || m.status == 'Released').toList();
        break;
      case MovementsWorklistFilter.inProgress:
        list = list.where((m) => m.status == 'In Progress').toList();
        break;
      case MovementsWorklistFilter.done:
        list = list.where((m) => m.status == 'Completed').toList();
        break;
      case MovementsWorklistFilter.cancelled:
        list = list.where((m) => m.status == 'Cancelled').toList();
        break;
    }
    return list;
  }

  void _onSearchSubmit() {
    setState(() => _searchText = _searchController.text);
  }

  void _openMovementDetails(DemoMovement m) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MovementDetailsPage(payload: MovementDetailsPayload(movementId: m.id)),
      ),
    );
  }

  static UiV1StatusVariant _statusVariant(String status) {
    final s = status.toLowerCase();
    if (s == 'draft') return UiV1StatusVariant.neutral;
    if (s == 'released') return UiV1StatusVariant.info;
    if (s == 'in progress') return UiV1StatusVariant.inProgress;
    if (s == 'completed') return UiV1StatusVariant.success;
    if (s == 'cancelled') return UiV1StatusVariant.warning;
    return UiV1StatusVariant.neutral;
  }

  static List<UiV1DataGridColumn<DemoMovement>> get _columns => [
    UiV1DataGridColumn<DemoMovement>(
      id: 'movementNo',
      label: 'Movement No',
      flex: 1,
      cellBuilder: (r) => Text(r.movementNo, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoMovement>(
      id: 'type',
      label: 'Type',
      flex: 1,
      cellBuilder: (r) => Text(r.movementType.label, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoMovement>(
      id: 'sku',
      label: 'SKU',
      flex: 1,
      cellBuilder: (r) => SkuLinkText(sku: r.sku),
    ),
    UiV1DataGridColumn<DemoMovement>(
      id: 'productName',
      label: 'Product Name',
      flex: 2,
      cellBuilder: (r) => Text(r.productName, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoMovement>(
      id: 'fromLocation',
      label: 'From',
      flex: 1,
      cellBuilder: (r) => Text(r.fromLocation, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoMovement>(
      id: 'toLocation',
      label: 'To',
      flex: 1,
      cellBuilder: (r) => Text(r.toLocation, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoMovement>(
      id: 'qty',
      label: 'Qty',
      flex: 1,
      cellBuilder: (r) => Text('${r.qty}', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoMovement>(
      id: 'status',
      label: 'Status',
      flex: 1,
      cellBuilder: (r) => UiV1StatusChip(label: r.status, variant: _statusVariant(r.status)),
    ),
    UiV1DataGridColumn<DemoMovement>(
      id: 'warehouse',
      label: 'Warehouse',
      flex: 1,
      cellBuilder: (r) => Text(r.warehouse, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoMovement>(
      id: 'created',
      label: 'Created',
      flex: 1,
      cellBuilder: (r) => Text(r.createdAt, overflow: TextOverflow.ellipsis, maxLines: 1),
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
                        hintText: 'Search movement no, SKU, location…',
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
                  SegmentedButton<MovementsWorklistFilter>(
                    segments: const [
                      ButtonSegment<MovementsWorklistFilter>(value: MovementsWorklistFilter.all, label: Text('All')),
                      ButtonSegment<MovementsWorklistFilter>(value: MovementsWorklistFilter.open, label: Text('Open')),
                      ButtonSegment<MovementsWorklistFilter>(value: MovementsWorklistFilter.inProgress, label: Text('In Progress')),
                      ButtonSegment<MovementsWorklistFilter>(value: MovementsWorklistFilter.done, label: Text('Done')),
                      ButtonSegment<MovementsWorklistFilter>(value: MovementsWorklistFilter.cancelled, label: Text('Cancelled')),
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
                        _filter = MovementsWorklistFilter.all;
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
                child: UiV1DataGrid<DemoMovement>(
                  columns: _columns,
                  rows: _rows,
                  rowIdGetter: (r) => r.id,
                  selectedIds: _selectedIds,
                  onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
                  loading: false,
                  errorMessage: null,
                  onRetry: null,
                  emptyMessage: 'No movements',
                  onRowOpen: _openMovementDetails,
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
