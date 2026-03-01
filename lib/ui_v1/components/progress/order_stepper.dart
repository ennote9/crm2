// Order progress stepper v1: compact horizontal stages. Dense, enterprise-style.

import 'package:flutter/material.dart';

import '../../icons/ui_icons.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';

/// Order flow stages (no Cancelled in stepper).
const List<String> kOrderStepperStages = [
  'Draft',
  'Released',
  'Allocated',
  'Picking',
  'Picked',
  'Packing',
  'Packed',
  'Shipped',
  'Closed',
];

/// Maps order status string to current step index (0..8). Returns -1 for Cancelled.
/// On Hold / Shortage map to a step (e.g. last known); stepper still shown, badge shown separately.
int orderStatusToStepIndex(String status) {
  final s = status.toLowerCase();
  if (s == 'cancelled') return -1;
  if (s == 'draft') return 0;
  if (s == 'released') return 1;
  if (s == 'allocated') return 2;
  if (s == 'allocating' || s == 'picking') return 3;
  if (s == 'picked') return 4;
  if (s == 'packing') return 5;
  if (s == 'packed') return 6;
  if (s == 'shipped') return 7;
  if (s == 'closed') return 8;
  if (s == 'on hold') return 2;
  if (s == 'shortage') return 6;
  return 0;
}

/// Compact horizontal stepper: completed (check), current (highlighted), future (muted).
/// Single line with wrap or horizontal scroll on narrow. Cancelled: pass currentStepIndex -1 to show dimmed/empty.
class UiV1OrderStepper extends StatelessWidget {
  const UiV1OrderStepper({
    super.key,
    required this.currentStepIndex,
    this.density = UiV1Density.dense,
  });

  final int currentStepIndex;
  final UiV1Density density;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final colors = Theme.of(context).brightness == Brightness.dark ? UiV1ColorTokens.dark : UiV1ColorTokens.light;
    final s = tokens.spacing;
    final isCancelled = currentStepIndex < 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < kOrderStepperStages.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: s.xxs),
                        child: Icon(
                          UiIcons.chevronRight,
                          size: 14,
                          color: _stepColor(i, isCancelled, colors),
                        ),
                      ),
                    _StepChip(
                      label: kOrderStepperStages[i],
                      isCompleted: !isCancelled && i < currentStepIndex,
                      isCurrent: !isCancelled && i == currentStepIndex,
                      isFuture: isCancelled || i > currentStepIndex,
                      isCancelled: isCancelled,
                      theme: theme,
                      colors: colors,
                      s: s,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Color _stepColor(int index, bool isCancelled, UiV1ColorTokens colors) {
    if (isCancelled) return colors.textMuted.withValues(alpha: 0.4);
    return colors.textMuted.withValues(alpha: 0.6);
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
    required this.isFuture,
    required this.isCancelled,
    required this.theme,
    required this.colors,
    required this.s,
  });

  final String label;
  final bool isCompleted;
  final bool isCurrent;
  final bool isFuture;
  final bool isCancelled;
  final ThemeData theme;
  final UiV1ColorTokens colors;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Widget? trailing;
    if (isCancelled) {
      bg = colors.surfaceAlt;
      fg = colors.textMuted.withValues(alpha: 0.7);
    } else if (isCompleted) {
      bg = colors.success.withValues(alpha: 0.15);
      fg = colors.success;
      trailing = Icon(UiIcons.check, size: 12, color: colors.success);
    } else if (isCurrent) {
      bg = colors.accentSubtle;
      fg = colors.accent;
    } else {
      bg = colors.surfaceAlt;
      fg = colors.textMuted;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(UiV1RadiusTokens.standard.lg),
        border: Border.all(color: fg.withValues(alpha: isCurrent ? 0.6 : 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (trailing != null) ...[
            SizedBox(width: s.xxs),
            trailing,
          ],
        ],
      ),
    );
  }
}
