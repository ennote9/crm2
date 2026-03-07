// Shared section card for object pages: unified padding, radius, border.
// Use for Summary, Stock, Traceability, Events blocks, etc.

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Section with title and card-wrapped body. Same design language as shell.
class UiV1SectionCard extends StatelessWidget {
  const UiV1SectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark
        ? UiV1Tokens.dark
        : UiV1Tokens.light;
    final s = tokens.spacing;
    final r = UiV1RadiusTokens.standard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        SizedBox(height: s.xs),
        Container(
          padding: EdgeInsets.all(s.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(r.md),
            border: Border.all(color: tokens.colors.border),
          ),
          child: child,
        ),
      ],
    );
  }
}
