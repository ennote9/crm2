// Products Worklist v1: product master list from DemoRepository, filters, open product details.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/chips/index.dart';
import '../../components/data_grid/index.dart';
import '../../demo_data/demo_data.dart';
import '../../theme/tokens.dart';
import 'product_details_page.dart';

/// Quick filters: All | Active | Inactive | Lot-tracked | Expiry-tracked
enum ProductsWorklistFilter {
  all,
  active,
  inactive,
  lotTracked,
  expiryTracked,
}

/// Products worklist: dense grid, open product details on row.
class ProductsWorklistPage extends StatefulWidget {
  const ProductsWorklistPage({super.key});

  @override
  State<ProductsWorklistPage> createState() => _ProductsWorklistPageState();
}

class _ProductsWorklistPageState extends State<ProductsWorklistPage> {
  String _searchText = '';
  ProductsWorklistFilter _filter = ProductsWorklistFilter.all;
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

  List<DemoProduct> get _rows {
    final statusFilter = switch (_filter) {
      ProductsWorklistFilter.all => <String>{},
      ProductsWorklistFilter.active => {'Active'},
      ProductsWorklistFilter.inactive => {'Inactive'},
      ProductsWorklistFilter.lotTracked => <String>{},
      ProductsWorklistFilter.expiryTracked => <String>{},
    };
    return demoRepository.getProducts(
      search: _searchText,
      statusFilter: statusFilter,
      lotTracked: _filter == ProductsWorklistFilter.lotTracked ? true : null,
      expiryTracked: _filter == ProductsWorklistFilter.expiryTracked ? true : null,
    );
  }

  void _onSearchSubmit() {
    setState(() => _searchText = _searchController.text);
  }

  void _openProductDetails(DemoProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsPage(payload: ProductDetailsPayload(productId: product.productId, sku: product.sku)),
      ),
    );
  }

  static UiV1StatusVariant _statusVariant(String status) {
    final s = status.toLowerCase();
    if (s == 'active') return UiV1StatusVariant.success;
    if (s == 'inactive') return UiV1StatusVariant.neutral;
    if (s == 'blocked') return UiV1StatusVariant.warning;
    return UiV1StatusVariant.neutral;
  }

  static List<UiV1DataGridColumn<DemoProduct>> get _columns => [
    UiV1DataGridColumn<DemoProduct>(
      id: 'sku',
      label: 'SKU',
      flex: 2,
      cellBuilder: (r) => Text(r.sku, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoProduct>(
      id: 'productName',
      label: 'Product Name',
      flex: 3,
      cellBuilder: (r) => Text(r.productName, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoProduct>(
      id: 'gtin14',
      label: 'GTIN',
      flex: 2,
      cellBuilder: (r) => Text(r.gtin14, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoProduct>(
      id: 'status',
      label: 'Status',
      flex: 1,
      cellBuilder: (r) => UiV1StatusChip(label: r.status, variant: _statusVariant(r.status)),
    ),
    UiV1DataGridColumn<DemoProduct>(
      id: 'baseUom',
      label: 'Base UoM',
      flex: 1,
      cellBuilder: (r) => Text(r.baseUom, overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoProduct>(
      id: 'lot',
      label: 'Lot',
      flex: 1,
      cellBuilder: (r) => Text(r.requiresLotTracking ? 'Yes' : '—', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoProduct>(
      id: 'serial',
      label: 'Serial',
      flex: 1,
      cellBuilder: (r) => Text(r.requiresSerialTracking ? 'Yes' : '—', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoProduct>(
      id: 'expiry',
      label: 'Expiry',
      flex: 1,
      cellBuilder: (r) => Text(r.requiresExpiryTracking ? 'Yes' : '—', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoProduct>(
      id: 'unitsPerCase',
      label: 'Units/Case',
      flex: 1,
      cellBuilder: (r) => Text(r.unitsPerCase != null ? '${r.unitsPerCase}' : '—', overflow: TextOverflow.ellipsis, maxLines: 1),
    ),
    UiV1DataGridColumn<DemoProduct>(
      id: 'brand',
      label: 'Brand',
      flex: 2,
      cellBuilder: (r) => Text(r.brand, overflow: TextOverflow.ellipsis, maxLines: 1),
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
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search SKU, name, GTIN, brand…',
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
                  SegmentedButton<ProductsWorklistFilter>(
                    segments: const [
                      ButtonSegment<ProductsWorklistFilter>(value: ProductsWorklistFilter.all, label: Text('All')),
                      ButtonSegment<ProductsWorklistFilter>(value: ProductsWorklistFilter.active, label: Text('Active')),
                      ButtonSegment<ProductsWorklistFilter>(value: ProductsWorklistFilter.inactive, label: Text('Inactive')),
                      ButtonSegment<ProductsWorklistFilter>(value: ProductsWorklistFilter.lotTracked, label: Text('Lot-tracked')),
                      ButtonSegment<ProductsWorklistFilter>(value: ProductsWorklistFilter.expiryTracked, label: Text('Expiry-tracked')),
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
                        _filter = ProductsWorklistFilter.all;
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
                child: UiV1DataGrid<DemoProduct>(
                  columns: _columns,
                  rows: _rows,
                  rowIdGetter: (r) => r.productId,
                  selectedIds: _selectedIds,
                  onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
                  loading: false,
                  errorMessage: null,
                  onRetry: null,
                  emptyMessage: 'No products',
                  onRowOpen: _openProductDetails,
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
