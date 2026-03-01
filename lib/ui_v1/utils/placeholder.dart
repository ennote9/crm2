// ui_v1 utils. Add helpers here.

import 'package:flutter/material.dart';

/// Simple placeholder body (e.g. for nav items not yet implemented).
class UiV1Placeholder extends StatelessWidget {
  const UiV1Placeholder({super.key, this.message = 'Placeholder'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
