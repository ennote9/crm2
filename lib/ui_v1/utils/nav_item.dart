// Nav item model for app shell sidebar.
// Icons: use UiIcons.iconForNavItem(item) from lib/ui_v1/icons/ui_icons.dart.

/// Sidebar navigation items (Orders, Picking, Packing, Products, Settings, optional Playground).
enum UiV1NavItem {
  orders,
  picking,
  packing,
  movements,
  replenishment,
  cycleCount,
  products,
  settings,
  /// Dev-only: component playground. Include in [allWithPlayground] when showDevMenu.
  playground;

  String get label {
    switch (this) {
      case UiV1NavItem.orders:
        return 'Orders';
      case UiV1NavItem.picking:
        return 'Picking';
      case UiV1NavItem.packing:
        return 'Packing';
      case UiV1NavItem.movements:
        return 'Movements';
      case UiV1NavItem.replenishment:
        return 'Replenishment';
      case UiV1NavItem.cycleCount:
        return 'Cycle Count';
      case UiV1NavItem.products:
        return 'Products';
      case UiV1NavItem.settings:
        return 'Settings';
      case UiV1NavItem.playground:
        return 'Dev/Playground';
    }
  }

  /// Main nav items (no dev).
  static const List<UiV1NavItem> all = [
    UiV1NavItem.orders,
    UiV1NavItem.picking,
    UiV1NavItem.packing,
    UiV1NavItem.movements,
    UiV1NavItem.replenishment,
    UiV1NavItem.cycleCount,
    UiV1NavItem.products,
    UiV1NavItem.settings,
  ];

  /// Main + Playground for dev menu.
  static const List<UiV1NavItem> allWithPlayground = [
    UiV1NavItem.orders,
    UiV1NavItem.picking,
    UiV1NavItem.packing,
    UiV1NavItem.movements,
    UiV1NavItem.replenishment,
    UiV1NavItem.cycleCount,
    UiV1NavItem.products,
    UiV1NavItem.settings,
    UiV1NavItem.playground,
  ];
}
