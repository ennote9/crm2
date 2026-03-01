// Order-level UI actions model (mock / backend contract).
// UI does not define business rules; it only reads available_actions and disabled_actions.

/// Reason a given action is disabled (MessageCatalog style: code + message). E_* only.
class DisabledActionReason {
  const DisabledActionReason({
    required this.code,
    required this.message,
  });
  final String code;
  final String message;
}

/// Warning before executing an available action (W_*). Does not disable the action.
class ActionReason {
  const ActionReason({required this.code, required this.message});
  final String code;
  final String message;
}

/// Order actions UI contract (UiActionsContract: available_actions / disabled_actions / actionWarnings).
class OrderActionsUi {
  const OrderActionsUi({
    required this.availableActions,
    required this.disabledActions,
    this.actionWarnings = const {},
  });
  final List<String> availableActions;
  final Map<String, DisabledActionReason> disabledActions;
  /// W_* per action: action is available but requires confirm before execution.
  final Map<String, ActionReason> actionWarnings;
}

/// Action ids used for Next step / More (UI demo only; not process truth).
/// Order: ship > complete_packing > start_packing > complete_picking > start_picking > allocate > release > close.
const List<String> kOrderActionPriority = [
  'ship',
  'complete_packing',
  'start_packing',
  'complete_picking',
  'start_picking',
  'allocate',
  'release',
  'close',
];

/// All order-level actions shown in More menu (same set for demo).
const List<String> kOrderActionIds = [
  'release',
  'allocate',
  'start_picking',
  'complete_picking',
  'start_packing',
  'complete_packing',
  'ship',
  'close',
];

/// First action from kOrderActionPriority that is in availableActions.
String? nextAvailableActionByPriority(OrderActionsUi ui) {
  for (final action in kOrderActionPriority) {
    if (ui.availableActions.contains(action)) return action;
  }
  return null;
}

/// First action from kOrderActionPriority that is in disabledActions (fallback when no available).
String? nextDisabledActionByPriority(OrderActionsUi ui) {
  for (final action in kOrderActionPriority) {
    if (ui.disabledActions.containsKey(action)) return action;
  }
  return null;
}

/// Human-readable label for action id (demo only).
String actionIdToLabel(String actionId) {
  switch (actionId) {
    case 'release': return 'Release';
    case 'allocate': return 'Allocate';
    case 'start_picking': return 'Start picking';
    case 'complete_picking': return 'Complete picking';
    case 'start_packing': return 'Start packing';
    case 'complete_packing': return 'Complete packing';
    case 'ship': return 'Ship';
    case 'close': return 'Close';
    default: return actionId;
  }
}

/// When status is Closed (or Cancelled): all actions disabled.
const DisabledActionReason _kReasonDone = DisabledActionReason(
  code: 'E_DONE_001',
  message: 'Заказ уже завершён. Действия недоступны.',
);

const ActionReason _kWarningShipShort = ActionReason(
  code: 'W_SHP_001',
  message: 'Отгружается меньше запланированного. Недостача будет зафиксирована как Short.',
);

const DisabledActionReason _kReasonBusy = DisabledActionReason(
  code: 'E_BUSY_001',
  message: 'Действие недоступно: операция уже выполняется.',
);

/// Next step disabled when order is on hold. Use in header (not in createMockOrderActionsUiForStatus).
const DisabledActionReason kReasonHold = DisabledActionReason(
  code: 'E_HOLD_001',
  message: 'Заказ на удержании (On Hold). Действия заблокированы.',
);

/// Next step disabled when order is cancelled.
const DisabledActionReason kReasonCancelled = DisabledActionReason(
  code: 'E_CAN_001',
  message: 'Заказ отменён. Действия недоступны.',
);

/// Ship disabled when HU count == 0 (task: E_SHP_001).
const DisabledActionReason _kReasonShipNoHu = DisabledActionReason(
  code: 'E_SHP_001',
  message: 'Нельзя отгрузить: нет грузомест (HU).',
);

const DisabledActionReason _kReasonShipNotPacked = DisabledActionReason(
  code: 'E_SHP_002',
  message: 'Отгрузка доступна только после упаковки (Packed).',
);

/// Mock HU count for order (demo). Same source used by HU tab list and Ship availability.
/// ORD-1001 => 0 (Ship disabled when Packed); others => 10.
int getMockHuCountForOrder(String orderNo) {
  return orderNo == 'ORD-1001' ? 0 : 10;
}

/// Mock UI actions by order status (demo only). hasShort => W_SHP_001 for ship when Packed.
/// huCount: when status Packed and huCount == 0, ship disabled (E_SHP_003).
OrderActionsUi createMockOrderActionsUiForStatus(String status, {bool hasShort = false, int? huCount}) {
  final s = status.toLowerCase();
  if (s == 'closed' || s == 'cancelled') {
    return OrderActionsUi(
      availableActions: [],
      disabledActions: {
        'release': _kReasonDone,
        'allocate': _kReasonDone,
        'start_picking': _kReasonDone,
        'complete_picking': _kReasonDone,
        'start_packing': _kReasonDone,
        'complete_packing': _kReasonDone,
        'ship': _kReasonDone,
        'close': _kReasonDone,
      },
      actionWarnings: {},
    );
  }
  if (s == 'packed') {
    final shipAvailable = huCount == null || huCount >= 1;
    final disabled = <String, DisabledActionReason>{
      'release': _kReasonDone,
      'allocate': const DisabledActionReason(
        code: 'E_ALL_001',
        message: 'Действие недоступно: заказ уже зарезервирован.',
      ),
      'start_picking': _kReasonBusy,
      'complete_picking': _kReasonBusy,
      'start_packing': _kReasonBusy,
      'complete_packing': _kReasonBusy,
      'close': const DisabledActionReason(
        code: 'E_CLS_001',
        message: 'Закрытие доступно только после отгрузки (Shipped).',
      ),
    };
    if (!shipAvailable) disabled['ship'] = _kReasonShipNoHu;
    return OrderActionsUi(
      availableActions: shipAvailable ? ['ship'] : [],
      disabledActions: disabled,
      actionWarnings: hasShort && shipAvailable ? {'ship': _kWarningShipShort} : {},
    );
  }
  if (s == 'draft') {
    return OrderActionsUi(
      availableActions: ['release'],
      disabledActions: {
        'allocate': const DisabledActionReason(
          code: 'E_ALL_002',
          message: 'Нельзя резервировать: сначала выпустите заказ (Release).',
        ),
        'start_picking': _kReasonBusy,
        'complete_picking': _kReasonBusy,
        'start_packing': _kReasonBusy,
        'complete_packing': _kReasonBusy,
        'ship': _kReasonShipNotPacked,
        'close': const DisabledActionReason(
          code: 'E_CLS_001',
          message: 'Закрытие доступно только после отгрузки (Shipped).',
        ),
      },
      actionWarnings: {},
    );
  }
  if (s == 'released') {
    return OrderActionsUi(
      availableActions: ['allocate'],
      disabledActions: {
        'release': _kReasonBusy,
        'start_picking': const DisabledActionReason(
          code: 'E_PCK_001',
          message: 'Нельзя начать отбор: нет зарезервированных количеств.',
        ),
        'complete_picking': _kReasonBusy,
        'start_packing': _kReasonBusy,
        'complete_packing': _kReasonBusy,
        'ship': _kReasonShipNotPacked,
        'close': const DisabledActionReason(
          code: 'E_CLS_001',
          message: 'Закрытие доступно только после отгрузки (Shipped).',
        ),
      },
      actionWarnings: {},
    );
  }
  if (s == 'allocated') {
    return OrderActionsUi(
      availableActions: ['start_picking'],
      disabledActions: {
        'release': _kReasonBusy,
        'allocate': _kReasonBusy,
        'complete_picking': _kReasonBusy,
        'start_packing': const DisabledActionReason(
          code: 'E_PAK_001',
          message: 'Нельзя начать упаковку: нет подобранных позиций.',
        ),
        'complete_packing': _kReasonBusy,
        'ship': _kReasonShipNotPacked,
        'close': const DisabledActionReason(
          code: 'E_CLS_001',
          message: 'Закрытие доступно только после отгрузки (Shipped).',
        ),
      },
      actionWarnings: {},
    );
  }
  if (s == 'picking') {
    return OrderActionsUi(
      availableActions: ['complete_picking'],
      disabledActions: {
        'release': _kReasonBusy,
        'allocate': _kReasonBusy,
        'start_picking': _kReasonBusy,
        'start_packing': _kReasonBusy,
        'complete_packing': _kReasonBusy,
        'ship': _kReasonShipNotPacked,
        'close': const DisabledActionReason(
          code: 'E_CLS_001',
          message: 'Закрытие доступно только после отгрузки (Shipped).',
        ),
      },
      actionWarnings: {},
    );
  }
  if (s == 'picked') {
    return OrderActionsUi(
      availableActions: ['start_packing'],
      disabledActions: {
        'release': _kReasonBusy,
        'allocate': _kReasonBusy,
        'start_picking': _kReasonBusy,
        'complete_picking': _kReasonBusy,
        'complete_packing': _kReasonBusy,
        'ship': _kReasonShipNotPacked,
        'close': const DisabledActionReason(
          code: 'E_CLS_001',
          message: 'Закрытие доступно только после отгрузки (Shipped).',
        ),
      },
      actionWarnings: {},
    );
  }
  if (s == 'packing') {
    return OrderActionsUi(
      availableActions: ['complete_packing'],
      disabledActions: {
        'release': _kReasonBusy,
        'allocate': _kReasonBusy,
        'start_picking': _kReasonBusy,
        'complete_picking': _kReasonBusy,
        'start_packing': _kReasonBusy,
        'ship': _kReasonShipNotPacked,
        'close': const DisabledActionReason(
          code: 'E_CLS_001',
          message: 'Закрытие доступно только после отгрузки (Shipped).',
        ),
      },
      actionWarnings: {},
    );
  }
  if (s == 'shipped') {
    return OrderActionsUi(
      availableActions: ['close'],
      disabledActions: {
        'release': _kReasonBusy,
        'allocate': _kReasonBusy,
        'start_picking': _kReasonBusy,
        'complete_picking': _kReasonBusy,
        'start_packing': _kReasonBusy,
        'complete_packing': _kReasonBusy,
        'ship': _kReasonBusy,
      },
      actionWarnings: {},
    );
  }
  if (s.contains('allocating')) {
    return OrderActionsUi(
      availableActions: [],
      disabledActions: {
        'release': _kReasonBusy,
        'allocate': _kReasonBusy,
        'start_picking': _kReasonBusy,
        'complete_picking': _kReasonBusy,
        'start_packing': _kReasonBusy,
        'complete_packing': _kReasonBusy,
        'ship': _kReasonBusy,
        'close': _kReasonBusy,
      },
      actionWarnings: {},
    );
  }
  // Fallback: e.g. On Hold, Shortage, other
  return OrderActionsUi(
    availableActions: ['release', 'allocate'],
    disabledActions: {
      'start_picking': _kReasonBusy,
      'complete_picking': _kReasonBusy,
      'start_packing': _kReasonBusy,
      'complete_packing': _kReasonBusy,
      'ship': const DisabledActionReason(
        code: 'E_SHP_001',
        message: 'Отгрузка доступна только после упаковки (Packed).',
      ),
      'close': const DisabledActionReason(
        code: 'E_CLS_001',
        message: 'Закрытие доступно только после отгрузки (Shipped).',
      ),
    },
    actionWarnings: {},
  );
}
