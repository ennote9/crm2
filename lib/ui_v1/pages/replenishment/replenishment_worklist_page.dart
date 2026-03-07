// Replenishment Worklist v1: list of replenishment rules, filters, open rule details.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../components/icon_widget.dart';
import '../../demo_data/demo_data.dart';
import '../../icons/ui_icons.dart';
import '../../theme/tokens.dart';
import '../products/sku_link_text.dart';
import 'replenishment_rule_details_page.dart';

enum ReplenishmentWorklistFilter {
  all,
  active,
  inactive,
  needsReplenishment,
}

class ReplenishmentWorklistPage extends StatefulWidget {
  const ReplenishmentWorklistPage({super.key, this.initialSearch});

  final String? initialSearch;

  @override
  State<ReplenishmentWorklistPage> createState() => _ReplenishmentWorklistPageState();
}

class _ReplenishmentWorklistPageState extends State<ReplenishmentWorklistPage> {
  late String _searchText;
  ReplenishmentWorklistFilter _filter = ReplenishmentWorklistFilter.all;
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

  List<DemoReplenishmentRule> get _rows {
    final filterStr = _filter == ReplenishmentWorklistFilter.all
        ? 'all'
        : _filter == ReplenishmentWorklistFilter.active
            ? 'active'
            : _filter == ReplenishmentWorklistFilter.inactive
                ? 'inactive'
                : 'needs_replenishment';
    return demoRepository.getReplenishmentRules(search: _searchText, filter: filterStr);
  }

  void _onSearchSubmit() {
    setState(() => _searchText = _searchController.text);
  }

  void _openRuleDetails(DemoReplenishmentRule rule) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReplenishmentRuleDetailsPage(payload: ReplenishmentRuleDetailsPayload(ruleId: rule.id)),
      ),
    );
  }

  static List<UiV1DataGridColumn<DemoReplenishmentRule>> _columns(BuildContext context) {
    return [
      UiV1DataGridColumn<DemoReplenishmentRule>(
        id: 'ruleNo',
        label: 'Rule No',
        flex: 1,
        cellBuilder: (r) => Text(r.ruleNo, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoReplenishmentRule>(
        id: 'sku',
        label: 'SKU',
        flex: 1,
        cellBuilder: (r) => SkuLinkText(sku: r.sku),
      ),
      UiV1DataGridColumn<DemoReplenishmentRule>(
        id: 'product',
        label: 'Product',
        flex: 2,
        cellBuilder: (r) => Text(r.productName, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoReplenishmentRule>(
        id: 'warehouse',
        label: 'Warehouse',
        flex: 1,
        cellBuilder: (r) => Text(r.warehouse, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoReplenishmentRule>(
        id: 'pickFace',
        label: 'Pick Face',
        flex: 1,
        cellBuilder: (r) => Text(r.pickFaceLocation, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoReplenishmentRule>(
        id: 'source',
        label: 'Source',
        flex: 1,
        cellBuilder: (r) => Text(r.sourceLocation, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoReplenishmentRule>(
        id: 'min',
        label: 'Min',
        flex: 1,
        cellBuilder: (r) => Text('${r.minQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoReplenishmentRule>(
        id: 'target',
        label: 'Target',
        flex: 1,
        cellBuilder: (r) => Text('${r.targetQty}', overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoReplenishmentRule>(
        id: 'current',
        label: 'Current',
        flex: 1,
        cellBuilder: (r) => Text('${demoRepository.getReplenishmentRuleCurrentQty(r)}', overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoReplenishmentRule>(
        id: 'suggested',
        label: 'Suggested',
        flex: 1,
        cellBuilder: (r) => Text('${demoRepository.getSuggestedReplenishmentQty(r)}', overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      UiV1DataGridColumn<DemoReplenishmentRule>(
        id: 'status',
        label: 'Status',
        flex: 1,
        cellBuilder: (r) => UiV1StatusChip(
          label: r.isActive ? 'Active' : 'Inactive',
          variant: r.isActive ? UiV1StatusVariant.success : UiV1StatusVariant.neutral,
        ),
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
                        hintText: 'Search rule no, SKU, location…',
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
                  SegmentedButton<ReplenishmentWorklistFilter>(
                    segments: const [
                      ButtonSegment<ReplenishmentWorklistFilter>(value: ReplenishmentWorklistFilter.all, label: Text('All')),
                      ButtonSegment<ReplenishmentWorklistFilter>(value: ReplenishmentWorklistFilter.active, label: Text('Active')),
                      ButtonSegment<ReplenishmentWorklistFilter>(value: ReplenishmentWorklistFilter.inactive, label: Text('Inactive')),
                      ButtonSegment<ReplenishmentWorklistFilter>(value: ReplenishmentWorklistFilter.needsReplenishment, label: Text('Needs Replenishment')),
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
                        _filter = ReplenishmentWorklistFilter.all;
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
                child: UiV1DataGrid<DemoReplenishmentRule>(
                  columns: _columns(context),
                  rows: _rows,
                  rowIdGetter: (r) => r.id,
                  selectedIds: _selectedIds,
                  onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
                  loading: false,
                  errorMessage: null,
                  onRetry: null,
                  emptyMessage: 'No replenishment rules',
                  onRowOpen: _openRuleDetails,
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
