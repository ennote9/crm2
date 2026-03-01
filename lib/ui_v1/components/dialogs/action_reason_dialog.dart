// Action reason dialogs: E_* = info (OK only), W_* = confirm (OK/Cancel). Per DialogsNotifications_Spec.

import 'package:flutter/material.dart';

/// Shows a modal for a disabled action reason. E_* → info (OK only); W_* → confirm (OK/Cancel).
/// Returns true if user confirmed (OK), false if cancelled, null if dismissed.
Future<bool?> showOrderActionReasonDialog(
  BuildContext context, {
  required String code,
  required String message,
}) {
  final isWarning = code.startsWith('W_');
  final theme = Theme.of(context);

  if (isWarning) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(code),
        content: SizedBox(
          width: 360,
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(code),
      content: SizedBox(
        width: 360,
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
