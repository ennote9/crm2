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
const List<String> kOrderActionPriority = [
  'ship',
  'start_packing',
  'start_picking',
  'allocate',
  'release',
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

/// Returns the "next" action by priority: first that is either available or disabled.
String? nextActionByPriority(OrderActionsUi ui) {
  for (final action in kOrderActionPriority) {
    if (ui.availableActions.contains(action) || ui.disabledActions.containsKey(action)) {
      return action;
    }
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

/// Mock data for Order Details header (demo only).
/// Use E_* for info dialog, W_* for confirm (OK/Cancel) dialog.
OrderActionsUi createMockOrderActionsUi() {
  return OrderActionsUi(
    availableActions: ['release', 'allocate', 'start_picking'],
    disabledActions: {
      'start_packing': const DisabledActionReason(
        code: 'E_PAK_001',
        message: 'Нельзя начать упаковку: нет подобранных позиций.',
      ),
      'ship': const DisabledActionReason(
        code: 'W_SHP_001',
        message: 'Отгружается меньше запланированного. Недостача будет зафиксирована как Short.',
      ),
      'close': const DisabledActionReason(
        code: 'E_CLS_001',
        message: 'Нельзя закрыть заказ: сначала выполните отгрузку (Shipped).',
      ),
    },
  );
}
