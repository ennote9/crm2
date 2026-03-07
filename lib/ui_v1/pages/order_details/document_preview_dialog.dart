// Document / label preview dialogs (demo): HU label, packing slip, shipment.
// No PDF or print — in-app preview only.

import 'package:flutter/material.dart';

import '../../components/section_card.dart';
import '../../demo_data/demo_data.dart';
import '../../theme/tokens.dart';

/// Shows HU/SSCC label preview. [onPrint] runs workflow action and closes.
Future<void> showHuLabelPreviewDialog(
  BuildContext context, {
  required HuLabelPreview preview,
  VoidCallback? onPrint,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _HuLabelPreviewDialog(preview: preview, onPrint: onPrint),
  );
}

class _HuLabelPreviewDialog extends StatelessWidget {
  const _HuLabelPreviewDialog({required this.preview, this.onPrint});
  final HuLabelPreview preview;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = UiV1SpacingTokens.standard;
    return AlertDialog(
      title: const Text('HU Label — Preview'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiV1SectionCard(title: 'Header', child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                _Row(label: 'Order', value: preview.orderNo),
                _Row(label: 'Warehouse', value: preview.warehouse),
                _Row(label: 'HU No', value: preview.huNo),
                _Row(label: 'Type', value: preview.type),
                _Row(label: 'Status', value: preview.status),
                _Row(label: 'SSCC', value: preview.sscc != null && preview.sscc!.isNotEmpty ? preview.sscc! : '— (assigned on print)'),
                ],
              )),
              SizedBox(height: s.sm),
              UiV1SectionCard(
                title: 'Contents (${preview.totalQty} total)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Row(
                    children: [
                      Expanded(flex: 2, child: Text('SKU', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                      Expanded(flex: 2, child: Text('Name', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                      Expanded(flex: 1, child: Text('Qty', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                    ],
                  ),
                  for (final r in preview.contentsSummary)
                    Padding(
                      padding: EdgeInsets.only(top: s.xxs),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(r.sku, style: theme.textTheme.bodySmall)),
                          Expanded(flex: 2, child: Text(r.name, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                          Expanded(flex: 1, child: Text('${r.qty}', style: theme.textTheme.bodySmall)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        if (onPrint != null)
          FilledButton(
            onPressed: () {
              onPrint!();
              Navigator.of(context).pop();
            },
            child: const Text('Print'),
          ),
      ],
    );
  }
}

/// Shows packing slip preview (read-only).
Future<void> showPackingSlipPreviewDialog(BuildContext context, {required PackingSlipPreview preview}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _PackingSlipPreviewDialog(preview: preview),
  );
}

class _PackingSlipPreviewDialog extends StatelessWidget {
  const _PackingSlipPreviewDialog({required this.preview});
  final PackingSlipPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = UiV1SpacingTokens.standard;
    return AlertDialog(
      title: const Text('Packing Slip — Preview'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiV1SectionCard(title: 'Order', child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Row(label: 'Order No', value: preview.orderNo),
                  _Row(label: 'Warehouse', value: preview.warehouse),
                  _Row(label: 'Status', value: preview.status),
                  _Row(label: 'Created', value: preview.createdAt),
                  _Row(label: 'HUs', value: '${preview.huCount}'),
                ],
              )),
              SizedBox(height: s.sm),
              UiV1SectionCard(
                title: 'Lines',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Row(
                    children: [
                      Expanded(flex: 2, child: Text('SKU', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                      Expanded(flex: 2, child: Text('Name', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                      Expanded(flex: 1, child: Text('Ord', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                      Expanded(flex: 1, child: Text('Packed', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                      Expanded(flex: 1, child: Text('Shipped', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                      Expanded(flex: 1, child: Text('Short', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                    ],
                  ),
                  for (final r in preview.lines)
                    Padding(
                      padding: EdgeInsets.only(top: s.xxs),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(r.sku, style: theme.textTheme.bodySmall)),
                          Expanded(flex: 2, child: Text(r.name, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                          Expanded(flex: 1, child: Text('${r.orderedQty}', style: theme.textTheme.bodySmall)),
                          Expanded(flex: 1, child: Text('${r.packedQty}', style: theme.textTheme.bodySmall)),
                          Expanded(flex: 1, child: Text('${r.shippedQty}', style: theme.textTheme.bodySmall)),
                          Expanded(flex: 1, child: Text('${r.shortQty}', style: theme.textTheme.bodySmall)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}

/// Shows shipment summary preview (read-only).
Future<void> showShipmentPreviewDialog(BuildContext context, {required ShipmentPreview preview}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _ShipmentPreviewDialog(preview: preview),
  );
}

class _ShipmentPreviewDialog extends StatelessWidget {
  const _ShipmentPreviewDialog({required this.preview});
  final ShipmentPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = UiV1SpacingTokens.standard;
    return AlertDialog(
      title: const Text('Shipment Summary — Preview'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiV1SectionCard(title: 'Shipment', child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Row(label: 'Order No', value: preview.orderNo),
                  _Row(label: 'Warehouse', value: preview.warehouse),
                  _Row(label: 'Status', value: preview.status),
                  _Row(label: 'Created', value: preview.createdAt),
                  _Row(label: 'HUs', value: '${preview.huCount}'),
                  _Row(label: 'Total shipped', value: '${preview.totalShipped}'),
                ],
              )),
              SizedBox(height: s.sm),
              UiV1SectionCard(
                title: 'Lines',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Row(
                    children: [
                      Expanded(flex: 2, child: Text('SKU', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                      Expanded(flex: 2, child: Text('Name', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                      Expanded(flex: 1, child: Text('Ord', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                      Expanded(flex: 1, child: Text('Packed', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                      Expanded(flex: 1, child: Text('Shipped', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                      Expanded(flex: 1, child: Text('Short', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                    ],
                  ),
                  for (final r in preview.lines)
                    Padding(
                      padding: EdgeInsets.only(top: s.xxs),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(r.sku, style: theme.textTheme.bodySmall)),
                          Expanded(flex: 2, child: Text(r.name, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                          Expanded(flex: 1, child: Text('${r.orderedQty}', style: theme.textTheme.bodySmall)),
                          Expanded(flex: 1, child: Text('${r.packedQty}', style: theme.textTheme.bodySmall)),
                          Expanded(flex: 1, child: Text('${r.shippedQty}', style: theme.textTheme.bodySmall)),
                          Expanded(flex: 1, child: Text('${r.shortQty}', style: theme.textTheme.bodySmall)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
