enum UserRole { admin, staff, parent }

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
      case UserRole.parent:
        return 'Parent';
    }
  }
}
