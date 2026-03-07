// Product Details v2: strong header, dense enterprise layout, traceability chips, clickable usage.

import 'package:flutter/material.dart';

import '../../components/chips/index.dart';
import '../../components/section_card.dart';
import '../../components/icon_widget.dart';
import '../../demo_data/demo_data.dart';
import '../../icons/ui_icons.dart';
import '../../theme/tokens.dart';
import '../order_details/order_details_page.dart';
import '../orders/orders_worklist_page.dart';
import '../packing/packing_worklist_page.dart';
import '../picking/picking_worklist_page.dart';

/// Payload to open product details (from worklist or order/HU link). Pass productId or sku.
class ProductDetailsPayload {
  const ProductDetailsPayload({this.productId, this.sku}) : assert(productId != null || sku != null);
  final String? productId;
  final String? sku;
}

/// Product Details v2: strong header, dense sections, traceability chips, usage → worklists.
class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key, required this.payload});

  final ProductDetailsPayload payload;

  @override
  Widget build(BuildContext context) {
    final product = payload.productId != null
        ? demoRepository.getProductById(payload.productId!)
        : (payload.sku != null ? demoRepository.getProductBySku(payload.sku!) : null);
    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: Text('Product not found')),
      );
    }
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const UiV1Icon(icon: UiIcons.arrowBack),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(product.sku, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(s.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProductHeader(product: product, theme: theme, s: s),
            SizedBox(height: s.lg),
            UiV1SectionCard(title: 'Summary', child: _SummarySection(product: product, theme: theme, s: s)),
            SizedBox(height: s.md),
            UiV1SectionCard(title: 'Traceability', child: _TraceabilitySection(product: product, theme: theme, s: s)),
            SizedBox(height: s.md),
            UiV1SectionCard(title: 'Packaging & Dimensions', child: _PackagingSection(product: product, theme: theme, s: s)),
            SizedBox(height: s.md),
            UiV1SectionCard(title: 'Stock', child: _StockSection(product: product, theme: theme, s: s)),
            SizedBox(height: s.md),
            UiV1SectionCard(title: 'Stock by warehouse', child: _StockByWarehouseSection(product: product, theme: theme, s: s)),
            SizedBox(height: s.md),
            UiV1SectionCard(title: 'Stock by location', child: _StockByLocationSection(product: product, theme: theme, s: s)),
            SizedBox(height: s.md),
            UiV1SectionCard(title: 'Lots / batches', child: _LotsSection(product: product, theme: theme, s: s)),
            SizedBox(height: s.md),
            UiV1SectionCard(title: 'Usage in operations', child: _UsageSection(product: product, theme: theme, s: s, context: context)),
          ],
        ),
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product, required this.theme, required this.s});
  final DemoProduct product;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  static UiV1StatusVariant _statusVariant(String status) {
    final t = status.toLowerCase();
    if (t == 'active') return UiV1StatusVariant.success;
    if (t == 'inactive') return UiV1StatusVariant.neutral;
    if (t == 'blocked') return UiV1StatusVariant.warning;
    return UiV1StatusVariant.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final r = UiV1RadiusTokens.standard;
    return Container(
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(r.lg),
        border: Border.all(color: tokens.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            product.productName,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          SizedBox(height: s.xs),
          Wrap(
            spacing: s.sm,
            runSpacing: s.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              UiV1StatusChip(label: product.status, variant: _statusVariant(product.status)),
              Text(
                'GTIN-14: ${product.gtin14}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          SizedBox(height: s.xs),
          Text(
            '${product.brand} · ${product.category} · ${product.baseUom}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.product, required this.theme, required this.s});
  final DemoProduct product;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('SKU', product.sku),
      ('Product Name', product.productName),
      ('GTIN-14', product.gtin14),
      ('Status', product.status),
      ('Brand', product.brand),
      ('Category', product.category),
      ('Base UoM', product.baseUom),
      ('Selling UoM', product.sellingUom),
      ('Ordering UoM', product.orderingUom),
    ];
    return _TwoColumnGrid(theme: theme, s: s, entries: entries);
  }
}

class _TraceabilitySection extends StatelessWidget {
  const _TraceabilitySection({required this.product, required this.theme, required this.s});
  final DemoProduct product;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: s.xs,
          runSpacing: s.xs,
          children: [
            if (product.requiresLotTracking)
              _CompactChip(label: 'Lot-tracked', theme: theme),
            if (product.requiresSerialTracking)
              _CompactChip(label: 'Serial-tracked', theme: theme),
            if (product.requiresExpiryTracking)
              _CompactChip(label: 'Expiry-tracked', theme: theme),
          ],
        ),
        if (product.requiresExpiryTracking && (product.shelfLifeDays != null || product.bestBeforeDays != null)) ...[
          SizedBox(height: s.xs),
          Wrap(
            spacing: s.md,
            runSpacing: s.xs,
            children: [
              if (product.shelfLifeDays != null)
                Text('Shelf life: ${product.shelfLifeDays} days', style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis, maxLines: 1),
              if (product.bestBeforeDays != null)
                Text('Best before: ${product.bestBeforeDays} days', style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis, maxLines: 1),
            ],
          ),
        ],
        SizedBox(height: s.xs),
        _KeyValueRow(theme: theme, label: 'Barcode (primary)', value: product.barcodePrimary),
        if (product.barcodeSecondary != null && product.barcodeSecondary!.isNotEmpty)
          _KeyValueRow(theme: theme, label: 'Barcode (secondary)', value: product.barcodeSecondary!.join(', ')),
      ],
    );
  }
}

class _CompactChip extends StatelessWidget {
  const _CompactChip({required this.label, required this.theme});
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.theme, required this.label, required this.value});
  final ThemeData theme;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis, maxLines: 1)),
        Expanded(child: Text(value, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis, maxLines: 2)),
      ],
    );
  }
}

class _PackagingSection extends StatelessWidget {
  const _PackagingSection({required this.product, required this.theme, required this.s});
  final DemoProduct product;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, String)>[
      if (product.length != null) ('Length', '${product.length}'),
      if (product.width != null) ('Width', '${product.width}'),
      if (product.height != null) ('Height', '${product.height}'),
      if (product.unitsPerCase != null) ('Units per case', '${product.unitsPerCase}'),
      if (product.casesPerLayer != null) ('Cases per layer', '${product.casesPerLayer}'),
      if (product.layersPerPallet != null) ('Layers per pallet', '${product.layersPerPallet}'),
      if (product.netWeight != null) ('Net weight', '${product.netWeight}'),
      if (product.grossWeight != null) ('Gross weight', '${product.grossWeight}'),
      if (product.storageCondition != null) ('Storage condition', product.storageCondition!),
    ];
    if (entries.isEmpty) {
      return Text('—', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis, maxLines: 1);
    }
    return _TwoColumnGrid(theme: theme, s: s, entries: entries);
  }
}

class _TwoColumnGrid extends StatelessWidget {
  const _TwoColumnGrid({required this.theme, required this.s, required this.entries});
  final ThemeData theme;
  final UiV1SpacingTokens s;
  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    const labelWidth = 120.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final left = entries.take((entries.length + 1) ~/ 2).toList();
        final right = entries.skip((entries.length + 1) ~/ 2).toList();
        return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: left.map((e) => Padding(
                    padding: EdgeInsets.only(bottom: s.xxs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: labelWidth, child: Text(e.$1, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis, maxLines: 1)),
                        Expanded(child: Text(e.$2, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis, maxLines: 2)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              SizedBox(width: s.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: right.map((e) => Padding(
                    padding: EdgeInsets.only(bottom: s.xxs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: labelWidth, child: Text(e.$1, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis, maxLines: 1)),
                        Expanded(child: Text(e.$2, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis, maxLines: 2)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          );
        },
    );
  }
}

class _StockSection extends StatelessWidget {
  const _StockSection({required this.product, required this.theme, required this.s});
  final DemoProduct product;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    final records = demoRepository.getInventoryBySku(product.sku);
    final onHand = records.fold<int>(0, (s, r) => s + r.onHandQty);
    final available = records.fold<int>(0, (s, r) => s + r.availableQty);
    final reserved = records.fold<int>(0, (s, r) => s + r.reservedQty);
    final picked = records.fold<int>(0, (s, r) => s + r.pickedQty);
    final packed = records.fold<int>(0, (s, r) => s + r.packedQty);
    final shipped = records.fold<int>(0, (s, r) => s + r.shippedQty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StockRow(label: 'On hand', value: onHand, theme: theme),
        _StockRow(label: 'Available', value: available, theme: theme),
        _StockRow(label: 'Reserved', value: reserved, theme: theme),
        _StockRow(label: 'Picked', value: picked, theme: theme),
        _StockRow(label: 'Packed', value: packed, theme: theme),
        _StockRow(label: 'Shipped', value: shipped, theme: theme),
      ],
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.label, required this.value, required this.theme});
  final String label;
  final int value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
          Text('$value', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Compact table: one row per warehouse (aggregated from location buckets). Totals match Stock + location detail.
class _StockByWarehouseSection extends StatelessWidget {
  const _StockByWarehouseSection({required this.product, required this.theme, required this.s});
  final DemoProduct product;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  static const double _colWidth = 56;
  static const double _whWidth = 64;

  @override
  Widget build(BuildContext context) {
    final records = demoRepository.getInventoryBySku(product.sku);
    final byWh = <String, ({int onHand, int available, int reserved, int picked, int packed, int shipped})>{};
    for (final r in records) {
      final cur = byWh[r.warehouse];
      if (cur == null) {
        byWh[r.warehouse] = (onHand: r.onHandQty, available: r.availableQty, reserved: r.reservedQty, picked: r.pickedQty, packed: r.packedQty, shipped: r.shippedQty);
      } else {
        byWh[r.warehouse] = (onHand: cur.onHand + r.onHandQty, available: cur.available + r.availableQty, reserved: cur.reserved + r.reservedQty, picked: cur.picked + r.pickedQty, packed: cur.packed + r.packedQty, shipped: cur.shipped + r.shippedQty);
      }
    }
    final sortedWh = byWh.keys.toList()..sort();
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final cellStyle = theme.textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {
            0: FixedColumnWidth(_whWidth),
            1: FixedColumnWidth(_colWidth),
            2: FixedColumnWidth(_colWidth),
            3: FixedColumnWidth(_colWidth),
            4: FixedColumnWidth(_colWidth),
            5: FixedColumnWidth(_colWidth),
            6: FixedColumnWidth(_colWidth),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              children: [
                _cell('Warehouse', labelStyle),
                _cell('On hand', labelStyle),
                _cell('Available', labelStyle),
                _cell('Reserved', labelStyle),
                _cell('Picked', labelStyle),
                _cell('Packed', labelStyle),
                _cell('Shipped', labelStyle),
              ],
            ),
            for (final wh in sortedWh)
              TableRow(
                children: [
                  _cell(wh, cellStyle),
                  _cell('${byWh[wh]!.onHand}', cellStyle),
                  _cell('${byWh[wh]!.available}', cellStyle),
                  _cell('${byWh[wh]!.reserved}', cellStyle),
                  _cell('${byWh[wh]!.picked}', cellStyle),
                  _cell('${byWh[wh]!.packed}', cellStyle),
                  _cell('${byWh[wh]!.shipped}', cellStyle),
                ],
              ),
          ],
        ),
        if (sortedWh.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: s.xs),
            child: Text('No warehouse records', style: labelStyle),
          ),
      ],
    );
  }

  Widget _cell(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(text, style: style, overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }
}

/// One row per location bucket: Warehouse, Location, On hand, Available, Reserved, Picked, Packed, Shipped.
class _StockByLocationSection extends StatelessWidget {
  const _StockByLocationSection({required this.product, required this.theme, required this.s});
  final DemoProduct product;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  static const double _colWidth = 52;
  static const double _whWidth = 56;
  static const double _locWidth = 72;

  @override
  Widget build(BuildContext context) {
    final records = demoRepository.getInventoryBySku(product.sku);
    final sorted = List<DemoInventoryRecord>.from(records)
      ..sort((a, b) => a.warehouse.compareTo(b.warehouse) != 0 ? a.warehouse.compareTo(b.warehouse) : a.location.compareTo(b.location));
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final cellStyle = theme.textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {
            0: FixedColumnWidth(_whWidth),
            1: FixedColumnWidth(_locWidth),
            2: FixedColumnWidth(_colWidth),
            3: FixedColumnWidth(_colWidth),
            4: FixedColumnWidth(_colWidth),
            5: FixedColumnWidth(_colWidth),
            6: FixedColumnWidth(_colWidth),
            7: FixedColumnWidth(_colWidth),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              children: [
                _cell('Warehouse', labelStyle),
                _cell('Location', labelStyle),
                _cell('On hand', labelStyle),
                _cell('Available', labelStyle),
                _cell('Reserved', labelStyle),
                _cell('Picked', labelStyle),
                _cell('Packed', labelStyle),
                _cell('Shipped', labelStyle),
              ],
            ),
            for (final r in sorted)
              TableRow(
                children: [
                  _cell(r.warehouse, cellStyle),
                  _cell(r.location, cellStyle),
                  _cell('${r.onHandQty}', cellStyle),
                  _cell('${r.availableQty}', cellStyle),
                  _cell('${r.reservedQty}', cellStyle),
                  _cell('${r.pickedQty}', cellStyle),
                  _cell('${r.packedQty}', cellStyle),
                  _cell('${r.shippedQty}', cellStyle),
                ],
              ),
          ],
        ),
        if (sorted.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: s.xs),
            child: Text('No location records', style: labelStyle),
          ),
      ],
    );
  }

  Widget _cell(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(text, style: style, overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }
}

/// Lots/batches for lot-tracked SKU; otherwise "Not lot-tracked."
class _LotsSection extends StatelessWidget {
  const _LotsSection({required this.product, required this.theme, required this.s});
  final DemoProduct product;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  static const double _colWidth = 56;

  @override
  Widget build(BuildContext context) {
    if (!product.requiresLotTracking) {
      return Text('Not lot-tracked.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    final records = demoRepository.getInventoryBySku(product.sku).where((r) => r.lot != null && r.lot!.isNotEmpty).toList();
    records.sort((a, b) => (a.lot ?? '').compareTo(b.lot ?? ''));
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final cellStyle = theme.textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {
            0: FixedColumnWidth(80),
            1: FixedColumnWidth(56),
            2: FixedColumnWidth(72),
            3: FixedColumnWidth(_colWidth),
            4: FixedColumnWidth(88),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              children: [
                _cell('Lot', labelStyle),
                _cell('Warehouse', labelStyle),
                _cell('Location', labelStyle),
                _cell('Available', labelStyle),
                _cell('Expiry', labelStyle),
              ],
            ),
            for (final r in records)
              TableRow(
                children: [
                  _cell(r.lot ?? '—', cellStyle),
                  _cell(r.warehouse, cellStyle),
                  _cell(r.location, cellStyle),
                  _cell('${r.availableQty}', cellStyle),
                  _cell(r.expiryDate ?? '—', cellStyle),
                ],
              ),
          ],
        ),
        if (records.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: s.xs),
            child: Text('No lot records', style: labelStyle),
          ),
      ],
    );
  }

  Widget _cell(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(text, style: style, overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }
}

class _UsageSection extends StatelessWidget {
  const _UsageSection({required this.product, required this.theme, required this.s, required this.context});
  final DemoProduct product;
  final ThemeData theme;
  final UiV1SpacingTokens s;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final orders = demoRepository.getOrdersForProduct(product.productId);
    final huList = demoRepository.getHuForProduct(product.productId);
    final allPickTasks = demoRepository.getAllPickTasks();
    final openPickCount = allPickTasks.where((t) => t.sku == product.sku && (t.status == 'Open' || t.status == 'In Progress')).length;
    final allPacking = demoRepository.getAllPackingTasks();
    final exceptionCount = allPacking.where((t) => t.sku == product.sku && t.status == 'Exception').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UsageTile(
          label: 'Recent Orders',
          count: orders.length,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OrdersWorklistPage(initialProductSku: product.sku))),
          theme: theme,
          s: s,
        ),
        _UsageTile(
          label: 'Open Pick Tasks',
          count: openPickCount,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PickingWorklistPage(initialSearch: product.sku))),
          theme: theme,
          s: s,
        ),
        _UsageTile(
          label: 'Packed HU count',
          count: huList.length,
          onTap: () {
            if (huList.isNotEmpty) {
              final first = huList.first;
              final bundle = demoRepository.getOrderDetails(first.orderNo);
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OrderDetailsPage(payload: OrderDetailsPayload(orderNo: bundle.order.orderNo, status: bundle.order.status, warehouse: bundle.order.warehouse, created: bundle.order.createdAt, baseStatus: bundle.order.status == 'On Hold' ? (bundle.order.baseStatus ?? 'Allocated') : null, initialTabIndex: 2))));
            } else {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OrdersWorklistPage(initialProductSku: product.sku)));
            }
          },
            theme: theme,
            s: s,
          ),
          _UsageTile(
            label: 'Exceptions (shortage/hold)',
            count: exceptionCount,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PackingWorklistPage(initialSearch: product.sku, initialFilterExceptions: true))),
            theme: theme,
            s: s,
          ),
        ],
    );
  }
}

class _UsageTile extends StatelessWidget {
  const _UsageTile({required this.label, required this.count, required this.onTap, required this.theme, required this.s});
  final String label;
  final int count;
  final VoidCallback onTap;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: s.xs, horizontal: s.xs),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis, maxLines: 1)),
            Text('$count', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1),
            SizedBox(width: s.xs),
            Icon(Icons.arrow_forward_ios, size: 12, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
