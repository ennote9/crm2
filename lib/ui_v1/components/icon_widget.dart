// Unified icon component for ui_v1: consistent size, stroke, and active/inactive states.
// Use with Material Symbols (outline) for sidebar, topbar, and actions.

import 'package:flutter/material.dart';

/// Default icon size for shell and actions (matches sidebar).
const double kUiV1IconSize = 24;

/// Unified outline icon: single size and visual weight; active state uses accent.
class UiV1Icon extends StatelessWidget {
  const UiV1Icon({
    super.key,
    required this.icon,
    this.size = kUiV1IconSize,
    this.isActive = false,
    this.color,
  });

  final IconData icon;
  final double size;
  final bool isActive;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolved = color ??
        (isActive ? colorScheme.primary : colorScheme.onSurfaceVariant);
    return Icon(
      icon,
      size: size,
      color: resolved,
    );
  }
}
