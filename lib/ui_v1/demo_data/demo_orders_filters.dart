// Filters for demo orders worklist.

/// View preset id (matches UiV1WorklistViewId.id).
class DemoOrdersFilters {
  const DemoOrdersFilters({
    this.search = '',
    this.statusFilters = const {},
    this.warehouse,
    this.viewId = 'all',
  });

  final String search;
  final Set<String> statusFilters;
  final String? warehouse;
  final String viewId;
}
