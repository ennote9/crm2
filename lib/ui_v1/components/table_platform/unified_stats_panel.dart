// Unified stats panel for Table Platform v1. Metrics computed on current filtered dataset.

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'unified_stats_metric.dart';

/// One metric card: label + value. [metricId] and [label] from definition; [value] from controller.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final c = tokens.colors.textPrimary;

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
            color: c,
          ),
        ),
      ],
    );
  }
}

/// Shows metric cards for selected metrics. Values are precomputed on current filtered dataset.
class UnifiedStatsPanel<T> extends StatelessWidget {
  const UnifiedStatsPanel({
    super.key,
    required this.metricDefinitions,
    required this.selectedMetricIds,
    required this.values,
  });

  final List<UnifiedStatsMetricDefinition<T>> metricDefinitions;
  final List<String> selectedMetricIds;
  /// metricId -> displayed value (already formatted).
  final Map<String, String> values;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;

    final ids = selectedMetricIds.isEmpty
        ? metricDefinitions.map((m) => m.id).toList()
        : selectedMetricIds;
    final children = <Widget>[];
    var first = true;
    for (final def in metricDefinitions) {
      if (!ids.contains(def.id)) continue;
      if (!first) children.add(SizedBox(width: s.md));
      first = false;
      children.add(_MetricCard(label: def.label, value: values[def.id] ?? '0'));
    }
    if (children.isEmpty) return const SizedBox.shrink();

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: EdgeInsets.all(s.sm),
        decoration: BoxDecoration(
          color: tokens.colors.surfaceAlt,
          border: Border(
            bottom: BorderSide(color: tokens.colors.border),
          ),
        ),
        child: Row(
          children: children,
        ),
      ),
    );
  }
}
