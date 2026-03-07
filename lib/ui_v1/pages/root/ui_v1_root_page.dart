// Root ui_v1 screen: AppShell + nav. Orders worklist by default; Playground (dev) in menu.

import 'package:flutter/material.dart';

import '../../app_shell/app_shell.dart';
import '../../demo_data/demo_data.dart';
import '../../utils/nav_item.dart';
import '../orders/orders_worklist_page.dart';
import '../packing/packing_worklist_page.dart';
import '../picking/picking_worklist_page.dart';
import '../playground/orders_list_state.dart';
import '../playground/playground_page.dart';
import '../products/products_worklist_page.dart';
import '../settings/settings_page.dart';

/// Main screen when kUseUiV1: shell + content by nav. Seeds demo repo once on first build.
class UiV1RootPage extends StatefulWidget {
  const UiV1RootPage({
    super.key,
    required this.listState,
    this.onThemeToggle,
    this.showDevMenu = false,
  });

  final OrdersListState listState;
  final VoidCallback? onThemeToggle;
  final bool showDevMenu;

  @override
  State<UiV1RootPage> createState() => _UiV1RootPageState();
}

class _UiV1RootPageState extends State<UiV1RootPage> {
  static bool _seeded = false;

  UiV1NavItem _currentNavId = UiV1NavItem.orders;

  @override
  void initState() {
    super.initState();
    if (!_seeded) {
      demoRepository.seed();
      _seeded = true;
    }
  }

  Widget _bodyForNav() {
    switch (_currentNavId) {
      case UiV1NavItem.orders:
        return const OrdersWorklistPage();
      case UiV1NavItem.picking:
        return const PickingWorklistPage();
      case UiV1NavItem.packing:
        return const PackingWorklistPage();
      case UiV1NavItem.products:
        return const ProductsWorklistPage();
      case UiV1NavItem.settings:
        return const SettingsPage();
      case UiV1NavItem.playground:
        return UiV1PlaygroundPage(
          listState: widget.listState,
          onThemeToggle: widget.onThemeToggle,
          wrapWithShell: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = widget.showDevMenu ? UiV1NavItem.allWithPlayground : UiV1NavItem.all;
    return UiV1AppShell(
      currentNavId: _currentNavId,
      onNavSelected: (id) => setState(() => _currentNavId = id),
      navItems: navItems,
      onThemeToggle: widget.onThemeToggle,
      onUserMenuTap: () {},
      child: _bodyForNav(),
    );
  }
}
