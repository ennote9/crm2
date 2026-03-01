import 'package:flutter/material.dart';

/// Top bar: theme toggle placeholder, user menu placeholder.
class UiV1Topbar extends StatelessWidget {
  const UiV1Topbar({
    super.key,
    this.onMenuTap,
    this.onThemeToggle,
    this.onUserMenuTap,
  });

  /// When set, shows a leading menu icon (e.g. for opening drawer on narrow layout).
  final VoidCallback? onMenuTap;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onUserMenuTap;

  static const double height = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (onMenuTap != null)
              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
              )
            else
              const SizedBox(width: 8),
            Expanded(child: Container()),
            IconButton(
              onPressed: onThemeToggle,
              icon: const Icon(Icons.brightness_6_outlined),
              tooltip: 'Theme (placeholder)',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onUserMenuTap,
              icon: const Icon(Icons.person_outline),
              tooltip: 'User menu (placeholder)',
            ),
          ],
        ),
      ),
    );
  }
}
