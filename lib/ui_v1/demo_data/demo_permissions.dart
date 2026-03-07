// Centralized permissions v1: section visibility and action execution by role.

import 'package:flutter/foundation.dart';

import 'demo_user.dart';
import '../utils/nav_item.dart';

/// Permission denied reason (E_PRM_001). Use when action is disabled by role.
const String kPermissionDeniedCode = 'E_PRM_001';
const String kPermissionDeniedMessage = 'Недостаточно прав для выполнения действия.';

// --- Section (sidebar) visibility per role ---

bool _canViewSection(DemoRole role, UiV1NavItem section) {
  switch (role) {
    case DemoRole.admin:
      return true;
    case DemoRole.supervisor:
      return true;
    case DemoRole.picker:
      return section == UiV1NavItem.orders ||
          section == UiV1NavItem.picking ||
          section == UiV1NavItem.movements ||
          section == UiV1NavItem.replenishment ||
          section == UiV1NavItem.cycleCount ||
          section == UiV1NavItem.products;
    case DemoRole.packer:
      return section == UiV1NavItem.orders ||
          section == UiV1NavItem.packing ||
          section == UiV1NavItem.movements ||
          section == UiV1NavItem.replenishment ||
          section == UiV1NavItem.cycleCount ||
          section == UiV1NavItem.products;
    case DemoRole.viewer:
      return section == UiV1NavItem.orders || section == UiV1NavItem.products;
  }
}

// --- Order-level actions (Next step / More): release, allocate, start_picking, ... ---

bool _canExecuteOrderAction(DemoRole role, String actionId) {
  switch (role) {
    case DemoRole.admin:
      return true;
    case DemoRole.supervisor:
      return true;
    case DemoRole.picker:
      return false; // Picker cannot run order-level transitions
    case DemoRole.packer:
      return actionId == 'start_packing' ||
          actionId == 'complete_packing'; // no release, allocate, ship, close
    case DemoRole.viewer:
      return false;
  }
}

// --- Pick task actions: start_pick_task, complete_pick_task, report_pick_exception ---

bool _canExecutePickTaskAction(DemoRole role) {
  switch (role) {
    case DemoRole.admin:
    case DemoRole.supervisor:
    case DemoRole.picker:
      return true;
    case DemoRole.packer:
    case DemoRole.viewer:
      return false;
  }
}

// --- HU actions: seal_hu, print_label, unpack_hu ---

bool _canExecuteHuAction(DemoRole role) {
  switch (role) {
    case DemoRole.admin:
    case DemoRole.supervisor:
    case DemoRole.packer:
      return true;
    case DemoRole.picker:
    case DemoRole.viewer:
      return false;
  }
}

// --- Line actions: mark_shortage, set_reason_code ---

bool _canExecuteLineAction(DemoRole role) {
  switch (role) {
    case DemoRole.admin:
    case DemoRole.supervisor:
      return true;
    case DemoRole.picker:
    case DemoRole.packer:
    case DemoRole.viewer:
      return false;
  }
}

// --- Hold: place_on_hold, resolve_hold ---

bool _canExecuteHoldAction(DemoRole role) {
  switch (role) {
    case DemoRole.admin:
    case DemoRole.supervisor:
      return true;
    case DemoRole.picker:
    case DemoRole.packer:
    case DemoRole.viewer:
      return false;
  }
}

// --- Public API: read from current user ---

/// Whether the current user can see this nav section (sidebar).
bool canViewSection(UiV1NavItem section) {
  return _canViewSection(currentUserStore.currentUser.role, section);
}

/// Whether the current user can execute this order-level action.
bool canExecuteOrderAction(String actionId) {
  return _canExecuteOrderAction(currentUserStore.currentUser.role, actionId);
}

/// Whether the current user can run pick task actions (Start / Complete / Report exception).
bool canExecutePickTaskAction() {
  return _canExecutePickTaskAction(currentUserStore.currentUser.role);
}

/// Whether the current user can run HU actions (Seal / Print label / Unpack).
bool canExecuteHuAction() {
  return _canExecuteHuAction(currentUserStore.currentUser.role);
}

/// Whether the current user can run line bulk actions (Mark shortage / Set reason code).
bool canExecuteLineAction() {
  return _canExecuteLineAction(currentUserStore.currentUser.role);
}

/// Whether the current user can place on hold / resolve hold.
bool canExecuteHoldAction() {
  return _canExecuteHoldAction(currentUserStore.currentUser.role);
}

/// True if current user is denied permission for this order action (show E_PRM_001).
bool isPermissionDeniedForOrderAction(String actionId) {
  return !canExecuteOrderAction(actionId);
}

// --- Current user store (demo switcher) ---

/// Holds current user. Notify listeners when switching role so UI rebuilds.
class CurrentUserStore extends ChangeNotifier {
  CurrentUserStore() : _currentUser = _defaultUser;
  DemoUser _currentUser;
  DemoUser get currentUser => _currentUser;
  set currentUser(DemoUser user) {
    if (_currentUser.userId != user.userId || _currentUser.role != user.role) {
      _currentUser = user;
      notifyListeners();
    }
  }

  void setRole(DemoRole role) {
    currentUser = DemoUser(
      userId: _currentUser.userId,
      fullName: _currentUser.fullName,
      role: role,
    );
  }
}

DemoUser get _defaultUser => const DemoUser(
  userId: 'demo-1',
  fullName: 'Demo Supervisor',
  role: DemoRole.supervisor,
);

/// Global store. Listen in root so nav and pages rebuild on role change.
CurrentUserStore get currentUserStore => _currentUserStore;
final CurrentUserStore _currentUserStore = CurrentUserStore();

