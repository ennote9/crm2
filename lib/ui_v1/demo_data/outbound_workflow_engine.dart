// Outbound Workflow Engine v1: central transition logic for orders, pick tasks, HU, lines.

import 'demo_handling_unit.dart';
import 'demo_pick_task.dart';
import 'demo_repository.dart';

/// Central engine for outbound order workflow. All transitions go through this layer.
/// Uses [demoRepository] as single source of truth; records events for every state change.
class OutboundWorkflowEngine {
  OutboundWorkflowEngine(this._repo);
  final DemoRepository _repo;

  // --- Order-level guards and execution ---

  /// Returns true if [actionId] is allowed in current order state (and order is not On Hold/Cancelled/Closed).
  bool canExecuteOrderAction(String orderId, String actionId) {
    final bundle = _repo.getOrderDetails(orderId);
    final order = bundle.order;
    final s = order.status.toLowerCase();
    if (s == 'on hold' || s == 'cancelled' || s == 'closed') return false;
    return bundle.actionsUi.availableActions.contains(actionId);
  }

  /// Executes order-level transition. Returns true if executed, false if guard failed.
  bool executeOrderAction(String orderId, String actionId) {
    if (!canExecuteOrderAction(orderId, actionId)) return false;
    _repo.applyAction(orderId, actionId);
    return true;
  }

  /// Place order on hold. Stores current status as baseStatus.
  bool placeOnHold(String orderId) {
    final bundle = _repo.getOrderDetails(orderId);
    final order = bundle.order;
    final s = order.status.toLowerCase();
    if (s == 'on hold' || s == 'cancelled' || s == 'closed') return false;
    _repo.setOrderStatus(orderId, 'On Hold', baseStatus: order.status);
    _repo.addOrderEvent(orderId, 'hold_created', 'Order placed on hold');
    return true;
  }

  /// Resolve hold: restore status from baseStatus.
  bool resolveHold(String orderId) {
    final bundle = _repo.getOrderDetails(orderId);
    final order = bundle.order;
    if (order.status.toLowerCase() != 'on hold') return false;
    final base = order.baseStatus ?? 'Allocated';
    _repo.setOrderStatus(orderId, base, baseStatus: null);
    _repo.addOrderEvent(orderId, 'hold_resolved', 'Hold resolved');
    return true;
  }

  // Pick-task actions: start_pick_task | complete_pick_task | report_pick_exception

  bool canExecutePickTaskAction(String orderId, String taskId, String actionId) {
    final tasks = _repo.getOrderDetails(orderId).tasks;
    DemoPickTask? task;
    for (final t in tasks) {
      if (t.id == taskId) { task = t; break; }
    }
    if (task == null) return false;
    final status = task.status.toLowerCase();
    switch (actionId) {
      case 'start_pick_task':
        return status == 'open';
      case 'complete_pick_task':
        return status == 'open' || status == 'in progress';
      case 'report_pick_exception':
        return status == 'open' || status == 'in progress';
      default:
        return false;
    }
  }

  bool executePickTaskAction(String orderId, String taskId, String actionId) {
    if (!canExecutePickTaskAction(orderId, taskId, actionId)) return false;
    final status = actionId == 'start_pick_task'
        ? 'In Progress'
        : (actionId == 'complete_pick_task' ? 'Done' : 'Exception');
    _repo.updatePickTaskStatus(orderId, taskId, status);
    return true;
  }

  // HU actions: seal_hu | print_label | unpack_hu
  // SSCC rule: label does not require SSCC beforehand; SSCC is assigned when print_label is executed.

  bool canExecuteHuAction(String orderId, String huId, String actionId) {
    final hus = _repo.getOrderDetails(orderId).hus;
    DemoHandlingUnit? hu;
    for (final h in hus) {
      if (h.id == huId) { hu = h; break; }
    }
    if (hu == null) return false;
    final status = hu.status.toLowerCase();
    switch (actionId) {
      case 'seal_hu':
        return status != 'shipped' && (status == 'packed' || status == 'open');
      case 'print_label':
        return status != 'open' && status != 'shipped';
      case 'unpack_hu':
        return status == 'packed' && status != 'shipped';
      default:
        return false;
    }
  }

  bool executeHuAction(String orderId, String huId, String actionId, {String? sscc}) {
    if (!canExecuteHuAction(orderId, huId, actionId)) return false;
    switch (actionId) {
      case 'seal_hu':
        _repo.updateHu(orderId, huId, status: 'Packed');
        break;
      case 'print_label':
        _repo.updateHu(orderId, huId, sscc: sscc ?? '380${DateTime.now().millisecondsSinceEpoch % 10000000000000000}'.padRight(18, '0'));
        break;
      case 'unpack_hu':
        _repo.updateHu(orderId, huId, status: 'Open');
        break;
      default:
        return false;
    }
    return true;
  }

  // Lines: mark shortage and set reason code (delegate to repo; events already added there)

  void executeMarkShortage(String orderId, List<String> lineIds, int shortQty, String reasonCode) {
    _repo.updateLinesShortage(orderId, lineIds, shortQty, reasonCode);
  }

  void executeSetReasonCode(String orderId, List<String> lineIds, String reasonCode) {
    _repo.updateLinesReasonCode(orderId, lineIds, reasonCode);
  }
}

/// Global singleton for ui_v1. Use after [demoRepository] is seeded.
OutboundWorkflowEngine get outboundWorkflowEngine => _outboundWorkflowEngine;
final OutboundWorkflowEngine _outboundWorkflowEngine = OutboundWorkflowEngine(demoRepository);
