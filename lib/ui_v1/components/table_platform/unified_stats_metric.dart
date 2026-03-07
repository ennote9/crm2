// Stats metric definition for Table Platform v1. Metrics are computed on current filtered dataset.

/// Metric aggregation type.
enum UnifiedStatsMetricType {
  count,
  sum,
  distinctCount,
}

/// Definition of one stats metric. Value is computed over visible (filtered) rows only.
class UnifiedStatsMetricDefinition<T> {
  const UnifiedStatsMetricDefinition({
    required this.id,
    required this.label,
    required this.type,
    this.fieldGetter,
    this.predicate,
    this.formatter,
  });

  final String id;
  final String label;
  final UnifiedStatsMetricType type;
  /// For sum: extract numeric value from row. For distinctCount: extract value to count distinct.
  final num Function(T row)? fieldGetter;
  /// For count: count rows where predicate is true. If null, count all rows (for type count).
  final bool Function(T row)? predicate;
  /// Format the computed number for display. If null, toString().
  final String Function(num value)? formatter;

  /// Compute metric value over [rows] (current filtered dataset).
  num compute(Iterable<T> rows) {
    final list = rows.toList();
    switch (type) {
      case UnifiedStatsMetricType.count:
        if (predicate != null) {
          return list.where(predicate!).length;
        }
        return list.length;
      case UnifiedStatsMetricType.sum:
        if (fieldGetter == null) return 0;
        return list.fold<num>(0, (s, r) => s + (fieldGetter!(r)));
      case UnifiedStatsMetricType.distinctCount:
        if (fieldGetter == null) return 0;
        final distinct = list.map((r) => fieldGetter!(r)).toSet();
        return distinct.length;
    }
  }

  String format(num value) => formatter != null ? formatter!(value) : value.toString();
}
