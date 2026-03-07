// Product Details v2: strong header, dense enterprise layout, traceability chips, clickable usage.

import 'package:flutter/material.dart';

import '../../components/chips/index.dart';
import '../../demo_data/demo_data.dart';
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
          icon: const Icon(Icons.arrow_back),
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
            _Section(title: 'Summary', child: _SummarySection(product: product, theme: theme, s: s)),
            SizedBox(height: s.md),
            _Section(title: 'Traceability', child: _TraceabilitySection(product: product, theme: theme, s: s)),
            SizedBox(height: s.md),
            _Section(title: 'Packaging & Dimensions', child: _PackagingSection(product: product, theme: theme, s: s)),
            SizedBox(height: s.md),
            _Section(title: 'Usage in operations', child: _UsageSection(product: product, theme: theme, s: s, context: context)),
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
    return Container(
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        SizedBox(height: s.xs),
        child,
      ],
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
    return Container(
      padding: EdgeInsets.all(s.sm),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
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
      ),
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
    return Container(
      padding: EdgeInsets.all(s.sm),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
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
      ),
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

    return Container(
      padding: EdgeInsets.all(s.sm),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
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
      ),
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
