// Main ui_v1 screen: AppShell + body by nav. Orders -> OrdersWorklistPage; row opens OrderDetailsPage (Back returns).

import 'package:flutter/material.dart';

import '../../app_shell/app_shell.dart';
import '../../utils/nav_item.dart';
import '../orders/orders_worklist_page.dart';
import '../packing/packing_worklist_page.dart';
import '../picking/picking_worklist_page.dart';
import '../playground/orders_list_state.dart';
import '../playground/playground_page.dart';
import '../products/products_worklist_page.dart';
import '../settings/settings_page.dart';

/// Main page when kUseUiV1: shell + Orders worklist (or Playground / placeholders).
/// Worklist state lives in OrdersWorklistPage and is preserved when opening details and Back.
class UiV1MainPage extends StatefulWidget {
  const UiV1MainPage({
    super.key,
    required this.listState,
    this.onThemeToggle,
    this.showDevMenu = false,
  });

  final OrdersListState listState;
  final VoidCallback? onThemeToggle;
  /// When true, sidebar includes Playground.
  final bool showDevMenu;

  @override
  State<UiV1MainPage> createState() => _UiV1MainPageState();
}

class _UiV1MainPageState extends State<UiV1MainPage> {
  UiV1NavItem _currentNavId = UiV1NavItem.orders;

  Widget _bodyForNav() {
    switch (_currentNavId) {
      case UiV1NavItem.orders:
        return const OrdersWorklistPage();
      case UiV1NavItem.playground:
        return UiV1PlaygroundPage(
          listState: widget.listState,
          onThemeToggle: widget.onThemeToggle,
          wrapWithShell: false,
        );
      case UiV1NavItem.settings:
        return const SettingsPage();
      case UiV1NavItem.picking:
        return const PickingWorklistPage();
      case UiV1NavItem.packing:
        return const PackingWorklistPage();
      case UiV1NavItem.products:
        return const ProductsWorklistPage();
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
