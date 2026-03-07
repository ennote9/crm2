// Sidebar v2: expanded (icon + text) / collapsed (icons only, tooltip), round toggle.

import 'package:flutter/material.dart';

import '../icons/ui_icons.dart';
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

    return Material(
      color: colorScheme.surfaceContainerHighest,
      child: Container(
        width: sideWidth,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
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

  static const double _horizontalPadding = 12;
  static const double _verticalPadding = 10;
  static const double _activeStripWidth = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = UiIcons.iconForNavItem(item);

    // Active: more contrast; default: standard
    final iconColor = isActive
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final textColor = isActive
        ? colorScheme.primary
        : colorScheme.onSurface;

    final content = collapsed
        ? Icon(
            iconData,
            size: UiIcons.sidebarIconSize,
            color: iconColor,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, size: UiIcons.sidebarIconSize, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );

    // Default (inactive): transparent — no card, merges with sidebar.
    // Active: subtle pill + accent strip. Hover: very light overlay (both modes).
    final activeBg = colorScheme.primaryContainer.withValues(alpha: 0.45);
    final hoverBg = colorScheme.onSurface.withValues(alpha: 0.05);

    final tile = Material(
      type: MaterialType.transparency,
      color: isActive ? activeBg : Colors.transparent,
      borderRadius: collapsed ? null : BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: collapsed ? null : BorderRadius.circular(8),
        hoverColor: hoverBg,
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.06),
        child: Stack(
          children: [
            if (isActive)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: _activeStripWidth,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: collapsed
                        ? null
                        : const BorderRadius.only(
                            topRight: Radius.circular(1),
                            bottomRight: Radius.circular(1),
                          ),
                  ),
                ),
              ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 0 : _horizontalPadding,
                vertical: _verticalPadding,
              ),
              alignment: collapsed ? Alignment.center : Alignment.centerLeft,
              child: collapsed
                  ? Tooltip(
                      message: item.label,
                      child: content,
                    )
                  : content,
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: tile,
    );
  }
}

/// Round button "<" / ">" at bottom of sidebar.
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
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Center(
        child: Material(
          color: colorScheme.surfaceContainerHigh,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(
                collapsed ? UiIcons.collapseRight : UiIcons.collapseLeft,
                size: 22,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
