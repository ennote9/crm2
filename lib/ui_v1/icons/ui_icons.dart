// Unified thin-outline icon set for ui_v1 shell and navigation (Lucide).
// Single weight, geometric, premium app-like look.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../utils/nav_item.dart' as nav;

/// Registry of thin outline icons for ui_v1. Use for sidebar, topbar, and shell.
abstract class UiIcons {
  UiIcons._();

  static const double sidebarIconSize = 22;

  static IconData iconForNavItem(nav.UiV1NavItem item) {
    switch (item) {
      case nav.UiV1NavItem.orders:
        return orders;
      case nav.UiV1NavItem.picking:
        return picking;
      case nav.UiV1NavItem.packing:
        return packing;
      case nav.UiV1NavItem.movements:
        return movements;
      case nav.UiV1NavItem.replenishment:
        return replenishment;
      case nav.UiV1NavItem.cycleCount:
        return cycleCount;
      case nav.UiV1NavItem.products:
        return products;
      case nav.UiV1NavItem.settings:
        return settings;
      case nav.UiV1NavItem.playground:
        return playground;
    }
  }

  static const IconData orders = LucideIcons.fileText;
  static const IconData picking = LucideIcons.clipboardList;
  static const IconData packing = LucideIcons.package;
  static const IconData movements = LucideIcons.arrowLeftRight;
  static const IconData replenishment = LucideIcons.packagePlus;
  static const IconData cycleCount = LucideIcons.clipboardCheck;
  static const IconData products = LucideIcons.layoutGrid;
  static const IconData settings = LucideIcons.settings;
  static const IconData playground = LucideIcons.flaskConical;

  static const IconData collapseLeft = LucideIcons.chevronLeft;
  static const IconData collapseRight = LucideIcons.chevronRight;

  static const IconData arrowBack = LucideIcons.arrowLeft;
  static const IconData info = LucideIcons.info;
  static const IconData moreHoriz = LucideIcons.moreHorizontal;
  static const IconData moreVert = LucideIcons.moreVertical;
  static const IconData menu = LucideIcons.menu;
  static const IconData clear = LucideIcons.x;
  static const IconData close = LucideIcons.x;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData arrowDropDown = LucideIcons.chevronDown;
  static const IconData lightMode = LucideIcons.sun;
  static const IconData person = LucideIcons.user;
  static const IconData check = LucideIcons.check;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData search = LucideIcons.search;
  static const IconData filterList = LucideIcons.filter;
  static const IconData view = LucideIcons.slidersHorizontal;
  static const IconData arrowForward = LucideIcons.arrowRight;
}
