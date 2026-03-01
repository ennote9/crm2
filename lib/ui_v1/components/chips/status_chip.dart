import 'package:flutter/material.dart';

import '../../theme/density.dart';
import '../../theme/tokens.dart';

/// Semantic status for StatusChip (StatusChips_Spec v1.0).
enum UiV1StatusVariant {
  neutral,   // Draft
  info,      // Released, Allocated, Picked, Packed
  inProgress,// Allocating, Picking, Packing
  warning,   // Partial Alloc, Shortage
  blocked,   // On Hold
  success,   // Shipped, Closed
  danger,    // Cancelled
}

/// Compact pill chip for order/object status. Text mandatory; not clickable by default.
class UiV1StatusChip extends StatelessWidget {
  const UiV1StatusChip({
    super.key,
    required this.label,
    required this.variant,
    this.density = UiV1Density.dense,
  });

  final String label;
  final UiV1StatusVariant variant;
  final UiV1Density density;

  static UiV1StatusVariant variantFromStatus(String status) {
    final s = status.toLowerCase();
    if (s == 'draft') return UiV1StatusVariant.neutral;
    if (s == 'released' || s == 'allocated' || s == 'picked' || s == 'packed') return UiV1StatusVariant.info;
    if (s == 'allocating' || s == 'picking' || s == 'packing') return UiV1StatusVariant.inProgress;
    if (s.contains('partial') || s == 'shortage') return UiV1StatusVariant.warning;
    if (s == 'on hold') return UiV1StatusVariant.blocked;
    if (s == 'shipped' || s == 'closed') return UiV1StatusVariant.success;
    if (s == 'cancelled') return UiV1StatusVariant.danger;
    return UiV1StatusVariant.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = brightness == Brightness.dark ? UiV1ColorTokens.dark : UiV1ColorTokens.light;
    final densityTokens = UiV1DensityTokens.forDensity(density);
    final (bg, fg) = _colorsForVariant(colors);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Container(
            height: densityTokens.chipHeight,
            padding: EdgeInsets.symmetric(horizontal: densityTokens.chipPaddingX),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(UiV1RadiusTokens.standard.lg),
              border: Border.all(color: fg.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  (Color, Color) _colorsForVariant(UiV1ColorTokens c) {
    switch (variant) {
      case UiV1StatusVariant.neutral:
        return (c.surfaceAlt, c.textSecondary);
      case UiV1StatusVariant.info:
        return (c.accentSubtle, c.accent);
      case UiV1StatusVariant.inProgress:
        return (c.info.withValues(alpha: 0.15), c.info);
      case UiV1StatusVariant.warning:
        return (c.warning.withValues(alpha: 0.15), c.warning);
      case UiV1StatusVariant.blocked:
        return (c.warning.withValues(alpha: 0.2), c.warning);
      case UiV1StatusVariant.success:
        return (c.success.withValues(alpha: 0.15), c.success);
      case UiV1StatusVariant.danger:
        return (c.danger.withValues(alpha: 0.15), c.danger);
    }
  }
}
