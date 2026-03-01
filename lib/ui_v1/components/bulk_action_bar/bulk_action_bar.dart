import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sticky bottom overlay shown when selection count > 0.
/// Left: "Selected: N", center: primary actions, right: Clear selection.
/// Tab-reachable; uses theme tokens (surface, border); Dense height.
class UiV1BulkActionBar extends StatelessWidget {
  const UiV1BulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onClearSelection,
    this.primaryActions,
  });

  final int selectedCount;
  final VoidCallback onClearSelection;
  /// Optional action buttons for the center (e.g. Hold, Unhold).
  final List<Widget>? primaryActions;

  static const double _barHeight = 48;

  @override
  Widget build(BuildContext context) {
    if (selectedCount <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
      child: Container(
        height: _barHeight,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              onClearSelection();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Selected: $selectedCount',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 24),
                if (primaryActions != null && primaryActions!.isNotEmpty) ...[
                  ...primaryActions!,
                  const SizedBox(width: 16),
                ],
                const Spacer(),
                TextButton(
                  onPressed: onClearSelection,
                  child: const Text('Clear selection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
