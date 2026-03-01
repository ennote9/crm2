// Nav item model for app shell sidebar.

import 'package:flutter/material.dart';

/// Sidebar navigation items (Orders, Picking, Packing, Products, Settings).
enum UiV1NavItem {
  orders,
  picking,
  packing,
  products,
  settings;

  String get label {
    switch (this) {
      case UiV1NavItem.orders:
        return 'Orders';
      case UiV1NavItem.picking:
        return 'Picking';
      case UiV1NavItem.packing:
        return 'Packing';
      case UiV1NavItem.products:
        return 'Products';
      case UiV1NavItem.settings:
        return 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case UiV1NavItem.orders:
        return Icons.receipt_long;
      case UiV1NavItem.picking:
        return Icons.inventory_2;
      case UiV1NavItem.packing:
        return Icons.inventory;
      case UiV1NavItem.products:
        return Icons.category;
      case UiV1NavItem.settings:
        return Icons.settings;
    }
  }

  /// All items in display order.
  static const List<UiV1NavItem> all = [
    UiV1NavItem.orders,
    UiV1NavItem.picking,
    UiV1NavItem.packing,
    UiV1NavItem.products,
    UiV1NavItem.settings,
  ];
}
