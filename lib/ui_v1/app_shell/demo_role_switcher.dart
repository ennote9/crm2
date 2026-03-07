// Demo role switcher for topbar: switch current user role to test permissions.

import 'package:flutter/material.dart';

import '../demo_data/demo_data.dart';
import '../icons/ui_icons.dart';

/// Button for topbar: shows current user/role, popup to switch role (demo).
class DemoRoleSwitcherButton extends StatelessWidget {
  const DemoRoleSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: currentUserStore,
      builder: (context, _) {
        final user = currentUserStore.currentUser;
        return PopupMenuButton<DemoRole>(
          tooltip: '${user.fullName} (${user.role.label}) — tap to switch role',
          icon: const Icon(UiIcons.person),
          onSelected: (role) => currentUserStore.setRole(role),
          itemBuilder: (context) => DemoRole.values.map((role) {
            final isCurrent = role == user.role;
            return PopupMenuItem<DemoRole>(
              value: role,
              child: Row(
                children: [
                  if (isCurrent) Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
                  if (isCurrent) const SizedBox(width: 8),
                  Text(role.label),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
