import '../../models/customer/site_model.dart';

extension MasterControllerPermissionHelper on MasterControllerModel {
  bool getPermissionStatus(String permissionName) {
    if (userPermission.isEmpty) {
      return true;
    }

    try {
      final permission = userPermission.firstWhere(
            (p) => p.name.toLowerCase() == permissionName.toLowerCase(),
        orElse: () => UserPermission(sNo: 0, name: '', status: true),
      );
      return permission.status;
    } catch (_) {
      return true;
    }
  }
}