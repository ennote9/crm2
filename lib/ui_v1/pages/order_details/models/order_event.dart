// Order event model for Events tab (audit timeline). Mock / backend contract.

/// Single order-level event.
class OrderEventMock {
  OrderEventMock({
    required this.id,
    required this.eventCode,
    required this.occurredAt,
    required this.actor,
    this.note,
  });
  final String id;
  final String eventCode;
  final DateTime occurredAt;
  final String actor;
  final String? note;
}

/// Filter segments: All / Workflow / Exceptions / System.
enum OrderEventCategory {
  workflow,
  exceptions,
  system,
}

/// Event codes used in mock (aligned with OrderEvents / workflow).
const List<String> kWorkflowEventCodes = [
  'released',
  'allocated',
  'pick_started',
  'pick_completed',
  'pack_started',
  'pack_completed',
  'shipped',
  'closed',
];

const List<String> kExceptionEventCodes = [
  'hold_created',
  'hold_resolved',
  'shortage_detected',
];

const List<String> kSystemEventCodes = [
  'order_created',
  'export_sent',
];

/// Maps eventCode to category for filter segments.
OrderEventCategory? eventCodeToCategory(String eventCode) {
  final code = eventCode.toLowerCase();
  if (kWorkflowEventCodes.contains(code)) return OrderEventCategory.workflow;
  if (kExceptionEventCodes.contains(code)) return OrderEventCategory.exceptions;
  if (kSystemEventCodes.contains(code)) return OrderEventCategory.system;
  return null;
}

/// Key timestamp keys for the strip (first occurrence of that event in list).
const List<String> kKeyTimestampCodes = [
  'released',
  'allocated',
  'pick_started',
  'pick_completed',
  'pack_started',
  'pack_completed',
  'shipped',
  'closed',
];

String eventCodeToLabel(String eventCode) {
  final code = eventCode.toLowerCase();
  switch (code) {
    case 'order_created': return 'Created';
    case 'released': return 'Released';
    case 'allocated': return 'Allocated';
    case 'pick_started': return 'Pick started';
    case 'pick_completed': return 'Pick completed';
    case 'pack_started': return 'Pack started';
    case 'pack_completed': return 'Pack completed';
    case 'shipped': return 'Shipped';
    case 'closed': return 'Closed';
    case 'hold_created': return 'Hold created';
    case 'hold_resolved': return 'Hold resolved';
    case 'shortage_detected': return 'Shortage detected';
    case 'export_sent': return 'Export sent';
    default: return eventCode;
  }
}
