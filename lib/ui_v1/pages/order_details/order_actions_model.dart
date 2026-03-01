// Order-level UI actions model (mock / backend contract).
// UI does not define business rules; it only reads available_actions and disabled_actions.

/// Reason a given action is disabled (MessageCatalog style: code + message).
class DisabledActionReason {
  const DisabledActionReason({
    required this.code,
    required this.message,
  });
  final String code;   // E_* | W_* | I_*
  final String message;
}

/// Order actions UI contract (UiActionsContract: available_actions / disabled_actions).
class OrderActionsUi {
  const OrderActionsUi({
    required this.availableActions,
    required this.disabledActions,
  });
  final List<String> availableActions;
  final Map<String, DisabledActionReason> disabledActions;
}

/// Action ids used for Next step / More (UI demo only; not process truth).
/// Order: ship > start_packing > start_picking > allocate > release > close.
const List<String> kOrderActionPriority = [
  'ship',
  'start_packing',
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
  'start_packing',
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
    case 'start_packing': return 'Start packing';
    case 'ship': return 'Ship';
    case 'close': return 'Close';
    default: return actionId;
  }
}

const DisabledActionReason _kReasonDone = DisabledActionReason(
  code: 'E_DONE_001',
  message: 'Заказ уже закрыт или отменён.',
);

const DisabledActionReason _kReasonBusy = DisabledActionReason(
  code: 'E_BUSY_001',
  message: 'Действие недоступно: операция уже выполняется.',
);

/// Mock UI actions by order status (demo only). Uses availableActions/disabledActions only.
OrderActionsUi createMockOrderActionsUiForStatus(String status) {
  final s = status.toLowerCase();
  if (s == 'closed' || s == 'cancelled') {
    return OrderActionsUi(
      availableActions: [],
      disabledActions: {
        'release': _kReasonDone,
        'allocate': _kReasonDone,
        'start_picking': _kReasonDone,
        'start_packing': _kReasonDone,
        'ship': _kReasonDone,
        'close': _kReasonDone,
      },
    );
  }
  if (s == 'packed') {
    return OrderActionsUi(
      availableActions: ['ship'],
      disabledActions: {
        'release': _kReasonDone,
        'allocate': const DisabledActionReason(
          code: 'E_ALL_001',
          message: 'Действие недоступно: заказ уже зарезервирован.',
        ),
        'start_picking': _kReasonBusy,
        'start_packing': _kReasonBusy,
        'close': const DisabledActionReason(
          code: 'E_CLS_001',
          message: 'Нельзя закрыть заказ: сначала выполните отгрузку (Shipped).',
        ),
      },
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
        'start_packing': _kReasonBusy,
        'ship': const DisabledActionReason(
          code: 'E_SHP_001',
          message: 'Отгрузка доступна только после упаковки (Packed).',
        ),
        'close': const DisabledActionReason(
          code: 'E_CLS_001',
          message: 'Нельзя закрыть заказ: сначала выполните отгрузку (Shipped).',
        ),
      },
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
        'start_packing': _kReasonBusy,
        'ship': const DisabledActionReason(
          code: 'E_SHP_001',
          message: 'Отгрузка доступна только после упаковки (Packed).',
        ),
        'close': const DisabledActionReason(
          code: 'E_CLS_001',
          message: 'Нельзя закрыть заказ: сначала выполните отгрузку (Shipped).',
        ),
      },
    );
  }
  if (s == 'allocated') {
    return OrderActionsUi(
      availableActions: ['start_picking'],
      disabledActions: {
        'release': _kReasonBusy,
        'allocate': _kReasonBusy,
        'start_packing': const DisabledActionReason(
          code: 'E_PAK_001',
          message: 'Нельзя начать упаковку: нет подобранных позиций.',
        ),
        'ship': const DisabledActionReason(
          code: 'E_SHP_001',
          message: 'Отгрузка доступна только после упаковки (Packed).',
        ),
        'close': const DisabledActionReason(
          code: 'E_CLS_001',
          message: 'Нельзя закрыть заказ: сначала выполните отгрузку (Shipped).',
        ),
      },
    );
  }
  if (s == 'picked') {
    return OrderActionsUi(
      availableActions: ['start_packing'],
      disabledActions: {
        'release': _kReasonBusy,
        'allocate': _kReasonBusy,
        'start_picking': _kReasonBusy,
        'ship': const DisabledActionReason(
          code: 'E_SHP_001',
          message: 'Отгрузка доступна только после упаковки (Packed).',
        ),
        'close': const DisabledActionReason(
          code: 'E_CLS_001',
          message: 'Нельзя закрыть заказ: сначала выполните отгрузку (Shipped).',
        ),
      },
    );
  }
  if (s == 'shipped') {
    return OrderActionsUi(
      availableActions: ['close'],
      disabledActions: {
        'release': _kReasonBusy,
        'allocate': _kReasonBusy,
        'start_picking': _kReasonBusy,
        'start_packing': _kReasonBusy,
        'ship': _kReasonBusy,
        'close': _kReasonBusy,
      },
    );
  }
  if (s.contains('allocating') || s.contains('picking') || s.contains('packing')) {
    return OrderActionsUi(
      availableActions: [],
      disabledActions: {
        'release': _kReasonBusy,
        'allocate': _kReasonBusy,
        'start_picking': _kReasonBusy,
        'start_packing': _kReasonBusy,
        'ship': _kReasonBusy,
        'close': _kReasonBusy,
      },
    );
  }
  // Fallback: e.g. On Hold, Shortage, other
  return OrderActionsUi(
    availableActions: ['release', 'allocate'],
    disabledActions: {
      'start_picking': _kReasonBusy,
      'start_packing': _kReasonBusy,
      'ship': const DisabledActionReason(
        code: 'E_SHP_001',
        message: 'Отгрузка доступна только после упаковки (Packed).',
      ),
      'close': const DisabledActionReason(
        code: 'E_CLS_001',
        message: 'Нельзя закрыть заказ: сначала выполните отгрузку (Shipped).',
      ),
    },
  );
}
