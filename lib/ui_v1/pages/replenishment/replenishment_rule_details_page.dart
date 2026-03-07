// Replenishment Rule Details (Object Page) v1 — summary, locations, thresholds, suggestion, Create movement.

import 'package:flutter/material.dart';

import '../../components/chips/index.dart';
import '../../components/icon_widget.dart';
import '../../components/section_card.dart';
import '../../demo_data/demo_data.dart';
import '../../icons/ui_icons.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';
import '../movements/movement_details_page.dart';
import '../products/product_details_page.dart';
import '../products/sku_link_text.dart';

class ReplenishmentRuleDetailsPayload {
  const ReplenishmentRuleDetailsPayload({required this.ruleId});
  final String ruleId;
}

class ReplenishmentRuleDetailsPage extends StatefulWidget {
  const ReplenishmentRuleDetailsPage({super.key, required this.payload});

  final ReplenishmentRuleDetailsPayload payload;

  @override
  State<ReplenishmentRuleDetailsPage> createState() => _ReplenishmentRuleDetailsPageState();
}

class _ReplenishmentRuleDetailsPageState extends State<ReplenishmentRuleDetailsPage> {
  DemoReplenishmentRule? _rule;

  @override
  void initState() {
    super.initState();
    _refreshFromRepo();
  }

  void _refreshFromRepo() {
    final rule = demoRepository.getReplenishmentRuleById(widget.payload.ruleId);
    setState(() => _rule = rule);
  }

  int get _currentQty => _rule != null ? demoRepository.getReplenishmentRuleCurrentQty(_rule!) : 0;
  int get _suggestedQty => _rule != null ? demoRepository.getSuggestedReplenishmentQty(_rule!) : 0;

  void _onCreateMovement() {
    if (_rule == null || _suggestedQty <= 0) return;
    final movement = demoRepository.createMovementFromReplenishmentRule(_rule!, 'Demo User');
    if (movement != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MovementDetailsPage(payload: MovementDetailsPayload(movementId: movement.id)),
        ),
      );
    }
  }

  void _openProductDetails() {
    if (_rule == null) return;
    final p = demoRepository.getProductBySku(_rule!.sku);
    if (p != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailsPage(payload: ProductDetailsPayload(productId: p.productId, sku: p.sku)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final density = UiV1DensityTokens.dense;

    if (_rule == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Replenishment Rule')),
        body: const Center(child: Text('Rule not found')),
      );
    }

    final rule = _rule!;
    final suggested = _suggestedQty;
    final current = _currentQty;
    final canCreate = rule.isActive && suggested > 0;
    final createDisabledReason = !rule.isActive
        ? 'Rule is inactive'
        : suggested <= 0
            ? 'Pick face at or above min (no replenishment needed)'
            : null;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: colorScheme.surface,
            elevation: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(s.lg, s.sm, s.lg, s.xs),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: tokens.colors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const UiV1Icon(icon: UiIcons.arrowBack),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                    style: IconButton.styleFrom(
                      minimumSize: Size(density.buttonHeight, density.buttonHeight),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(width: s.xxs),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            rule.ruleNo,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: s.sm),
                        UiV1StatusChip(
                          label: rule.isActive ? 'Active' : 'Inactive',
                          variant: rule.isActive ? UiV1StatusVariant.success : UiV1StatusVariant.neutral,
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: canCreate ? 'Create replenishment movement' : (createDisabledReason ?? ''),
                    child: FilledButton.icon(
                      onPressed: canCreate ? _onCreateMovement : null,
                      style: FilledButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
                      icon: const UiV1Icon(icon: UiIcons.arrowForward, size: 20),
                      label: const Text('Create movement'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(s.xl, s.sm, s.xl, s.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UiV1SectionCard(
                    title: 'Summary',
                    child: _RuleSummary(rule: rule, theme: theme, s: s),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Product / SKU',
                    child: Row(
                      children: [
                        SkuLinkText(sku: rule.sku),
                        SizedBox(width: s.sm),
                        Expanded(
                          child: SkuLinkText(sku: rule.sku, label: rule.productName, style: theme.textTheme.bodyMedium),
                        ),
                        TextButton(
                          onPressed: _openProductDetails,
                          child: const Text('Open product'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Location setup',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            SizedBox(width: 100, child: Text('Warehouse', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant))),
                            Text(rule.warehouse, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        SizedBox(height: s.xxs),
                        Row(
                          children: [
                            SizedBox(width: 100, child: Text('Pick face', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant))),
                            Text(rule.pickFaceLocation, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        SizedBox(height: s.xxs),
                        Row(
                          children: [
                            SizedBox(width: 100, child: Text('Source', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant))),
                            Text(rule.sourceLocation, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Thresholds',
                    child: Row(
                      children: [
                        _thresholdChip(theme, s, tokens, 'Min', rule.minQty),
                        SizedBox(width: s.sm),
                        _thresholdChip(theme, s, tokens, 'Target', rule.targetQty),
                      ],
                    ),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Current stock',
                    child: Text(
                      '$current available at ${rule.pickFaceLocation}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Suggestion',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Suggested replenishment: $suggested',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (suggested <= 0 && rule.isActive) ...[
                          SizedBox(height: s.xxs),
                          Text(
                            'Pick face is at or above min qty. No movement needed.',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thresholdChip(ThemeData theme, UiV1SpacingTokens spacing, UiV1Tokens tok, String label, int value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xxs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(tok.radius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          SizedBox(width: spacing.xxs),
          Text('$value', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RuleSummary extends StatelessWidget {
  const _RuleSummary({required this.rule, required this.theme, required this.s});
  final DemoReplenishmentRule rule;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    const labelWidth = 80.0;
    final rows = [
      _row('Rule No', rule.ruleNo, labelWidth),
      _row('Warehouse', rule.warehouse, labelWidth),
      _row('Status', rule.isActive ? 'Active' : 'Inactive', labelWidth),
      _row('Created', rule.createdAt, labelWidth),
      _row('Updated', rule.updatedAt, labelWidth),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows.asMap().entries.map((e) {
        return Padding(
          padding: EdgeInsets.only(bottom: e.key < rows.length - 1 ? s.xxs : 0),
          child: e.value,
        );
      }).toList(),
    );
  }

  Widget _row(String label, String value, double labelWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
