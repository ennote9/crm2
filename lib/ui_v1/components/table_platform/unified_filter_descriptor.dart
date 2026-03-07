// Unified filter descriptor for Table Platform v1. Typed column filters.

/// Filter operator. Controller evaluates all; UI uses subset by column type.
enum UnifiedFilterOperator {
  equals,
  notEquals,
  contains,
  notContains,
  startsWith,
  endsWith,
  inList,
  notInList,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  between,
  isEmpty,
  isNotEmpty,
}

/// Single filter: column + operator + value(s). Applied per row using column valueGetter.
class UnifiedFilterDescriptor {
  const UnifiedFilterDescriptor({
    required this.columnId,
    required this.operator,
    this.value,
    this.secondaryValue,
    this.values,
    this.id,
  });

  final String columnId;
  final UnifiedFilterOperator operator;
  final dynamic value;
  final dynamic secondaryValue;
  final List<dynamic>? values;
  final String? id;

  String get identity => id ?? columnId;

  static String operatorLabel(UnifiedFilterOperator op) {
    switch (op) {
      case UnifiedFilterOperator.equals:
        return 'is';
      case UnifiedFilterOperator.notEquals:
        return 'is not';
      case UnifiedFilterOperator.contains:
        return 'contains';
      case UnifiedFilterOperator.notContains:
        return 'does not contain';
      case UnifiedFilterOperator.startsWith:
        return 'starts with';
      case UnifiedFilterOperator.endsWith:
        return 'ends with';
      case UnifiedFilterOperator.inList:
        return 'one of';
      case UnifiedFilterOperator.notInList:
        return 'not one of';
      case UnifiedFilterOperator.greaterThan:
        return '>';
      case UnifiedFilterOperator.greaterThanOrEqual:
        return '≥';
      case UnifiedFilterOperator.lessThan:
        return '<';
      case UnifiedFilterOperator.lessThanOrEqual:
        return '≤';
      case UnifiedFilterOperator.between:
        return 'between';
      case UnifiedFilterOperator.isEmpty:
        return 'is empty';
      case UnifiedFilterOperator.isNotEmpty:
        return 'is not empty';
    }
  }

  /// Value part for chips/summary (technical).
  String valueDisplayString() {
    switch (operator) {
      case UnifiedFilterOperator.isEmpty:
      case UnifiedFilterOperator.isNotEmpty:
        return operatorLabel(operator);
      case UnifiedFilterOperator.between:
        return '$value – $secondaryValue';
      case UnifiedFilterOperator.inList:
      case UnifiedFilterOperator.notInList:
        return values != null && values!.isNotEmpty
            ? '${operatorLabel(operator)} [${values!.join(', ')}]'
            : operatorLabel(operator);
      default:
        return value != null ? '${operatorLabel(operator)} $value' : operatorLabel(operator);
    }
  }

  /// Human-readable value part for filter summary (e.g. "contains 100", "Released, Picking", "between 2025-02-01 – 2025-02-15").
  String toHumanReadableValueString() {
    switch (operator) {
      case UnifiedFilterOperator.isEmpty:
        return 'is empty';
      case UnifiedFilterOperator.isNotEmpty:
        return 'is not empty';
      case UnifiedFilterOperator.between:
        return 'between ${value ?? ''} – $secondaryValue';
      case UnifiedFilterOperator.inList:
        if (values == null || values!.isEmpty) return 'one of (none)';
        if (values!.length > 3) return 'one of (${values!.length})';
        return values!.map((e) => e.toString()).join(', ');
      case UnifiedFilterOperator.notInList:
        if (values == null || values!.isEmpty) return 'not one of (none)';
        if (values!.length > 3) return 'not one of (${values!.length})';
        return 'not one of ${values!.map((e) => e.toString()).join(', ')}';
      case UnifiedFilterOperator.equals:
        return 'is ${value ?? ''}';
      case UnifiedFilterOperator.notEquals:
        return 'is not ${value ?? ''}';
      case UnifiedFilterOperator.contains:
        return 'contains ${value ?? ''}';
      case UnifiedFilterOperator.notContains:
        return 'does not contain ${value ?? ''}';
      case UnifiedFilterOperator.startsWith:
        return 'starts with ${value ?? ''}';
      case UnifiedFilterOperator.endsWith:
        return 'ends with ${value ?? ''}';
      case UnifiedFilterOperator.greaterThan:
        return 'after ${value ?? ''}';
      case UnifiedFilterOperator.greaterThanOrEqual:
        return '≥ ${value ?? ''}';
      case UnifiedFilterOperator.lessThan:
        return 'before ${value ?? ''}';
      case UnifiedFilterOperator.lessThanOrEqual:
        return '≤ ${value ?? ''}';
    }
  }
}
