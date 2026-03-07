// Demo user and role model for permissions v1.

/// Demo roles for ui_v1. Permissions matrix in demo_permissions.dart.
enum DemoRole {
  admin,
  supervisor,
  picker,
  packer,
  viewer,
}

extension DemoRoleExt on DemoRole {
  String get label {
    switch (this) {
      case DemoRole.admin:
        return 'Admin';
      case DemoRole.supervisor:
        return 'Supervisor';
      case DemoRole.picker:
        return 'Picker';
      case DemoRole.packer:
        return 'Packer';
      case DemoRole.viewer:
        return 'Viewer';
    }
  }
}

/// Demo current user. Single source: [currentUserStore].
class DemoUser {
  const DemoUser({
    required this.userId,
    required this.fullName,
    required this.role,
  });
  final String userId;
  final String fullName;
  final DemoRole role;
}
