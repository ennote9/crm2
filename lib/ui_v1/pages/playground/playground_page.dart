// Dev page: component demos / examples. Not the production orders worklist.

import 'package:flutter/material.dart';

import '../../app_shell/app_shell.dart';
import '../../components/chips/index.dart';
import '../../theme/tokens.dart';
import '../../utils/nav_item.dart';
import 'orders_list_state.dart';

/// Dev-only page: demos of ui_v1 components. Production orders list lives in [OrdersWorklistPage].
class UiV1PlaygroundPage extends StatefulWidget {
  const UiV1PlaygroundPage({
    super.key,
    required this.listState,
    this.onThemeToggle,
    this.wrapWithShell = true,
  });

  final OrdersListState listState;
  final VoidCallback? onThemeToggle;
  final bool wrapWithShell;

  @override
  State<UiV1PlaygroundPage> createState() => _UiV1PlaygroundPageState();
}

class _UiV1PlaygroundPageState extends State<UiV1PlaygroundPage> {
  UiV1NavItem _currentNavId = UiV1NavItem.orders;

  @override
  Widget build(BuildContext context) {
    final content = _buildDevContent(context);
    if (!widget.wrapWithShell) {
      return content;
    }
    return UiV1AppShell(
      currentNavId: _currentNavId,
      onNavSelected: (id) => setState(() => _currentNavId = id),
      onThemeToggle: widget.onThemeToggle,
      onUserMenuTap: () {},
      child: content,
    );
  }

  Widget _buildDevContent(BuildContext context) {
    final theme = Theme.of(context);
    final s = UiV1SpacingTokens.standard;
    return Padding(
      padding: EdgeInsets.all(s.xl),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dev Playground',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: s.sm),
            Text(
              'Component demos and examples. Production orders list is on OrdersWorklistPage.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: s.lg),
            Text(
              'Status chips',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: s.xs),
            Wrap(
              spacing: s.xs,
              runSpacing: s.xs,
              children: [
                UiV1StatusChip(label: 'Draft', variant: UiV1StatusVariant.neutral),
                UiV1StatusChip(label: 'Packed', variant: UiV1StatusVariant.info),
                UiV1StatusChip(label: 'Shipped', variant: UiV1StatusVariant.success),
                UiV1StatusChip(label: 'On Hold', variant: UiV1StatusVariant.warning),
                UiV1StatusChip(label: 'Shortage', variant: UiV1StatusVariant.warning),
                UiV1StatusChip(label: 'Exception', variant: UiV1StatusVariant.danger),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
