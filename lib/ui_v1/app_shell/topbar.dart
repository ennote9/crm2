import 'package:flutter/material.dart';

import '../components/icon_widget.dart';
import '../demo_data/demo_data.dart';
import '../icons/ui_icons.dart';
import '../theme/tokens.dart';

/// Top bar: theme toggle, user/role switcher (demo).
/// On narrow width (< 350) replaces theme/user buttons with one "More" PopupMenuButton.
class UiV1Topbar extends StatelessWidget {
  const UiV1Topbar({
    super.key,
    this.onMenuTap,
    this.onThemeToggle,
    this.onUserMenuTap,
    this.userMenuWidget,
  });

  /// When set, shows a leading menu icon (e.g. for opening drawer on narrow layout).
  final VoidCallback? onMenuTap;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onUserMenuTap;
  /// When set, shown instead of the default user icon button (e.g. demo role switcher).
  final Widget? userMenuWidget;

  static const double height = 48;

  /// Width below which theme + user buttons are replaced by one "More" menu.
  static const double _kBreakpointNarrow = 350;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < _kBreakpointNarrow;

    final colors = theme.brightness == Brightness.dark
        ? UiV1ColorTokens.dark
        : UiV1ColorTokens.light;
    return Material(
      color: colorScheme.surface,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.border),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (onMenuTap != null)
              IconButton(
                onPressed: onMenuTap,
                icon: const UiV1Icon(icon: UiIcons.menu),
                tooltip: 'Menu',
              )
            else
              const SizedBox(width: 8),
            Expanded(child: Container()),
            if (narrow)
              PopupMenuButton<void>(
                icon: const UiV1Icon(icon: UiIcons.moreVert),
                tooltip: 'More',
                padding: EdgeInsets.zero,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => onThemeToggle?.call(),
                    child: const Row(
                      children: [
                        UiV1Icon(icon: UiIcons.lightMode, size: 20),
                        SizedBox(width: 12),
                        Text('Theme'),
                      ],
                    ),
                  ),
                  if (userMenuWidget != null) ...[
                    PopupMenuItem(
                      enabled: false,
                      child: Text('Role: ${currentUserStore.currentUser.role.label}'),
                    ),
                    ...DemoRole.values.map((role) => PopupMenuItem(
                      onTap: () => currentUserStore.setRole(role),
                      child: Text('Switch to ${role.label}'),
                    )),
                  ] else
                    PopupMenuItem(
                      onTap: () => onUserMenuTap?.call(),
                      child: const Row(
                        children: [
                          UiV1Icon(icon: UiIcons.person, size: 20),
                          SizedBox(width: 12),
                          Text('User menu'),
                        ],
                      ),
                    ),
                ],
              )
            else ...[
              IconButton(
                onPressed: onThemeToggle,
                icon: const UiV1Icon(icon: UiIcons.lightMode),
                tooltip: 'Theme',
              ),
              const SizedBox(width: 8),
              if (userMenuWidget != null)
                userMenuWidget!
              else
                IconButton(
                  onPressed: onUserMenuTap,
                  icon: const UiV1Icon(icon: UiIcons.person),
                  tooltip: 'User menu',
                ),
            ],
          ],
        ),
      ),
    );
  }
}
