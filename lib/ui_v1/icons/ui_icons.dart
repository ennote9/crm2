// Unified outline icon set for ui_v1 (Material Symbols Outline).
// Single weight/optical size for sidebar and shell.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../utils/nav_item.dart' as nav;

/// Registry of outline-style icons for ui_v1. Use for sidebar, shell, etc.
/// Style: thin outline, same weight/optical size everywhere.
abstract class UiIcons {
  UiIcons._();

  /// Default icon size for sidebar (expanded and collapsed).
  static const double sidebarIconSize = 24;

  /// Icon for nav item. Use in sidebar (v1/v2) and any nav that shows UiV1NavItem.
  /// Mapping: document, checklist, box, apps, settings, lab — unambiguous in collapsed mode.
  static IconData iconForNavItem(nav.UiV1NavItem item) {
    switch (item) {
      case nav.UiV1NavItem.orders:
        return orders;
      case nav.UiV1NavItem.picking:
        return picking;
      case nav.UiV1NavItem.packing:
        return packing;
      case nav.UiV1NavItem.products:
        return products;
      case nav.UiV1NavItem.settings:
        return settings;
      case nav.UiV1NavItem.playground:
        return playground;
    }
  }

  /// Orders — document/table style.
  static const IconData orders = Symbols.description;

  /// Picking — checklist/task.
  static const IconData picking = Symbols.checklist;

  /// Packing — package/box.
  static const IconData packing = Symbols.inventory;

  /// Products — grid/catalog.
  static const IconData products = Symbols.apps;

  /// Settings.
  static const IconData settings = Symbols.settings;

  /// Dev/Playground — lab/science.
  static const IconData playground = Symbols.science;

  /// Collapse sidebar (show expand state): chevron left.
  static const IconData collapseLeft = Symbols.chevron_left;

  /// Expand sidebar (show collapse state): chevron right.
  static const IconData collapseRight = Symbols.chevron_right;

  // --- Shell / toolbar / actions (outline, same weight) ---

  /// Back navigation.
  static const IconData arrowBack = Symbols.arrow_back;

  /// Info (outline).
  static const IconData info = Symbols.info;

  /// More actions (horizontal ellipsis).
  static const IconData moreHoriz = Symbols.more_horiz;

  /// More actions (vertical).
  static const IconData moreVert = Symbols.more_vert;

  /// Menu (hamburger).
  static const IconData menu = Symbols.menu;

  /// Clear / close input.
  static const IconData clear = Symbols.close;

  /// Close / dismiss.
  static const IconData close = Symbols.close;

  /// Refresh / retry.
  static const IconData refresh = Symbols.refresh;

  /// Dropdown arrow.
  static const IconData arrowDropDown = Symbols.arrow_drop_down;

  /// Light theme / brightness.
  static const IconData lightMode = Symbols.light_mode;

  /// Person / account.
  static const IconData person = Symbols.person;

  /// Check / done (small, e.g. stepper).
  static const IconData check = Symbols.check;

  /// Chevron right (e.g. stepper).
  static const IconData chevronRight = Symbols.chevron_right;

  /// Search (toolbar).
  static const IconData search = Symbols.search;

  /// Filters (filter list).
  static const IconData filterList = Symbols.filter_list;

  /// View / tune / sort (toolbar view selector).
  static const IconData view = Symbols.tune;

  /// Next step (forward action).
  static const IconData arrowForward = Symbols.arrow_forward;
}
