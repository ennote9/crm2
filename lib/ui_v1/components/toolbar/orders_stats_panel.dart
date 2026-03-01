// Orders Stats Panel MVP: Total, In progress, On Hold, Shortage (mock counts).

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// KPI item for the stats panel.
class UiV1OrdersStatsPanel extends StatelessWidget {
  const UiV1OrdersStatsPanel({
    super.key,
    required this.total,
    required this.inProgress,
    required this.onHold,
    required this.shortage,
  });

  final int total;
  final int inProgress;
  final int onHold;
  final int shortage;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).brightness == Brightness.dark
        ? UiV1Tokens.dark
        : UiV1Tokens.light;
    final s = tokens.spacing;
    final colors = tokens.colors;

    return Container(
      padding: EdgeInsets.all(s.sm),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          _KpiCard(
            label: 'Total',
            value: total.toString(),
            color: colors.textPrimary,
          ),
          SizedBox(width: s.md),
          _KpiCard(
            label: 'In progress',
            value: inProgress.toString(),
            color: colors.info,
          ),
          SizedBox(width: s.md),
          _KpiCard(
            label: 'On Hold',
            value: onHold.toString(),
            color: colors.warning,
          ),
          SizedBox(width: s.md),
          _KpiCard(
            label: 'Shortage',
            value: shortage.toString(),
            color: colors.warning,
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark
        ? UiV1Tokens.dark
        : UiV1Tokens.light;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: tokens.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
