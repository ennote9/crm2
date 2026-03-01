// Demo event for Events tab.

/// Event category for filter.
enum DemoEventCategory {
  workflow,
  exception,
  system,
}

/// In-memory order event for demo.
class DemoEvent {
  DemoEvent({
    required this.id,
    required this.code,
    required this.occurredAt,
    required this.actor,
    required this.category,
    this.payload,
  });

  final String id;
  final String code;
  final DateTime occurredAt;
  final String actor;
  final DemoEventCategory category;
  final String? payload;
}
