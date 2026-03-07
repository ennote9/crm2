// Sidebar v2: expanded (icon + text) / collapsed (icons only, tooltip), round toggle.
// v2.1: no left stripe; active = rounded pill only (slightly lighter than sidebar), soft contrast.

import 'package:flutter/material.dart';

import '../components/icon_widget.dart';
import '../icons/ui_icons.dart';
import '../theme/tokens.dart';
import '../utils/nav_item.dart';

/// Sidebar v2: two modes (expanded/collapsed), round collapse button, active item as background pill.
class UiV1SidebarV2 extends StatelessWidget {
  const UiV1SidebarV2({
    super.key,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.currentNavId,
    required this.onNavSelected,
    this.navItems,
  });

  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final UiV1NavItem? currentNavId;
  final ValueChanged<UiV1NavItem>? onNavSelected;
  final List<UiV1NavItem>? navItems;

  static const double widthExpanded = 220;
  static const double widthCollapsed = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sideWidth = collapsed ? widthCollapsed : widthExpanded;
    final items = navItems ?? UiV1NavItem.all;
    final hasPlayground = items.contains(UiV1NavItem.playground);
    final mainItems = hasPlayground
        ? items.where((e) => e != UiV1NavItem.playground).toList()
        : items;

    final colors = Theme.of(context).brightness == Brightness.dark
        ? UiV1ColorTokens.dark
        : UiV1ColorTokens.light;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? colorScheme.surfaceContainerHighest : colors.surfaceAlt;
    return Material(
      color: sidebarBg,
      child: Container(
        width: sideWidth,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: colors.border),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shrinkWrap: true,
                children: [
                  for (final item in mainItems)
                    _SidebarV2Tile(
                      item: item,
                      collapsed: collapsed,
                      isActive: currentNavId == item,
                      onTap: onNavSelected != null ? () => onNavSelected!(item) : null,
                    ),
                  if (hasPlayground) ...[
                    const Divider(height: 1),
                    _SidebarV2Tile(
                      item: UiV1NavItem.playground,
                      collapsed: collapsed,
                      isActive: currentNavId == UiV1NavItem.playground,
                      onTap: onNavSelected != null
                          ? () => onNavSelected!(UiV1NavItem.playground)
                          : null,
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            _CollapseButtonV2(
              collapsed: collapsed,
              onPressed: onToggleCollapsed,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarV2Tile extends StatelessWidget {
  const _SidebarV2Tile({
    required this.item,
    required this.collapsed,
    required this.isActive,
    required this.onTap,
  });

  final UiV1NavItem item;
  final bool collapsed;
  final bool isActive;
  final VoidCallback? onTap;

  static const double _horizontalPadding = 14;
  static const double _verticalPadding = 11;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = theme.brightness == Brightness.dark
        ? UiV1ColorTokens.dark
        : UiV1ColorTokens.light;
    final radius = UiV1RadiusTokens.standard;

    // Inactive: transparent. Active: rounded pill (readable contrast). Hover: subtle overlay.
    final isDark = theme.brightness == Brightness.dark;
    final activeBg = isDark
        ? colors.surfaceAlt.withValues(alpha: 0.9)
        : colors.surfaceAlt.withValues(alpha: 0.95);
    final hoverBg = colors.hoverBg;
    // Active: readable contrast (onSurface), no accent fill
    final iconColor = isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant;
    final labelColor = isActive ? colorScheme.onSurface : colorScheme.onSurface;

    final contentResolved = collapsed
        ? UiV1Icon(
            icon: UiIcons.iconForNavItem(item),
            size: UiIcons.sidebarIconSize,
            isActive: false,
            color: iconColor,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UiV1Icon(
                icon: UiIcons.iconForNavItem(item),
                size: UiIcons.sidebarIconSize,
                isActive: false,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: labelColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );

    final tile = Material(
      type: MaterialType.transparency,
      color: isActive ? activeBg : Colors.transparent,
      borderRadius: BorderRadius.circular(radius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius.lg),
        hoverColor: hoverBg,
        splashColor: colorScheme.primary.withValues(alpha: 0.06),
        highlightColor: colorScheme.primary.withValues(alpha: 0.04),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : _horizontalPadding,
            vertical: _verticalPadding,
          ),
          alignment: collapsed ? Alignment.center : Alignment.centerLeft,
          child: collapsed
              ? Tooltip(
                  message: item.label,
                  child: contentResolved,
                )
              : contentResolved,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: tile,
    );
  }
}

/// Collapse button: same visual language as nav pills, at bottom of sidebar.
class _CollapseButtonV2 extends StatelessWidget {
  const _CollapseButtonV2({
    required this.collapsed,
    required this.onPressed,
  });

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.brightness == Brightness.dark
        ? UiV1ColorTokens.dark
        : UiV1ColorTokens.light;
    final radius = UiV1RadiusTokens.standard;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      child: Center(
        child: Material(
          color: colors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.lg),
          ),
          elevation: 0,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(radius.lg),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: UiV1Icon(
                icon: collapsed ? UiIcons.collapseRight : UiIcons.collapseLeft,
                size: UiIcons.sidebarIconSize,
                isActive: false,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
