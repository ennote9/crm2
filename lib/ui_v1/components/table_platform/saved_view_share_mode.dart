// Share/visibility mode for saved table views. v1: private / shared; extensible for role/warehouse later.

/// Who can see this saved view.
enum SavedViewShareMode {
  /// Only the owner.
  private_,
  /// Shared to all users (demo). Later: sharedToRole, sharedToWarehouse, etc.
  shared,
}

extension SavedViewShareModeExtension on SavedViewShareMode {
  String get label {
    switch (this) {
      case SavedViewShareMode.private_:
        return 'Private';
      case SavedViewShareMode.shared:
        return 'Shared';
    }
  }
}
