import 'package:flutter/material.dart';

import '../utils/nav_item.dart';
import 'sidebar.dart';
import 'topbar.dart';

// --- 4 responsive modes ---
// wide:   window >= 1000  → full sidebar + grid
// medium: 720..<1000      → collapsed sidebar + grid
// narrow: window < 720    → drawer + card list (content decides layout)
// ultra narrow: content < 360 (in page) → same drawer + ultra-compact card list

/// Width below which sidebar is forced collapsed (icons only).
const double kBreakpointSidebarCollapse = 1000;

/// Width below which sidebar is hidden and replaced by drawer.
const double kBreakpointSidebarHide = 720;

/// App shell layout: TopBar, Sidebar (expanded/collapsed or drawer), Content area.
class UiV1AppShell extends StatefulWidget {
  const UiV1AppShell({
    super.key,
    required this.child,
    this.initialCollapsed = false,
    this.currentNavId,
    this.onNavSelected,
    this.navItems,
    this.onThemeToggle,
    this.onUserMenuTap,
  });

  final Widget child;
  final bool initialCollapsed;
  final UiV1NavItem? currentNavId;
  final ValueChanged<UiV1NavItem>? onNavSelected;
  /// When null, uses [UiV1NavItem.all].
  final List<UiV1NavItem>? navItems;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onUserMenuTap;

  @override
  State<UiV1AppShell> createState() => _UiV1AppShellState();
}

class _UiV1AppShellState extends State<UiV1AppShell> {
  late bool _collapsed;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initialCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showSidebarInRow = width >= kBreakpointSidebarHide;
    final effectiveCollapsed = width < kBreakpointSidebarCollapse || _collapsed;

    final content = Material(
      color: Theme.of(context).colorScheme.surface,
      child: widget.child,
    );

    if (showSidebarInRow) {
      return Scaffold(
        body: Column(
          children: [
            UiV1Topbar(
              onThemeToggle: widget.onThemeToggle,
              onUserMenuTap: widget.onUserMenuTap,
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UiV1Sidebar(
                    collapsed: effectiveCollapsed,
                    onToggleCollapsed: () => setState(() => _collapsed = !_collapsed),
                    currentNavId: widget.currentNavId,
                    onNavSelected: widget.onNavSelected,
                    navItems: widget.navItems,
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: UiV1Sidebar(
            collapsed: false,
            onToggleCollapsed: () {},
            currentNavId: widget.currentNavId,
            onNavSelected: (id) {
              Navigator.of(context).pop();
              widget.onNavSelected?.call(id);
            },
            navItems: widget.navItems,
          ),
        ),
      ),
      body: Column(
        children: [
          UiV1Topbar(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onThemeToggle: widget.onThemeToggle,
            onUserMenuTap: widget.onUserMenuTap,
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
