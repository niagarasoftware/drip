import 'package:oro_drip_irrigation/models/customer/site_model.dart';

class ControllerContext {
  final int userId;
  final int customerId;
  final int controllerId;
  final int categoryId, modelId;
  final String categoryName, imeiNo, deviceName;
  final bool isSubUser;
  final MasterControllerModel master;

  ControllerContext({
    required this.userId,
    required this.customerId,
    required this.controllerId,
    required this.categoryId,
    required this.modelId,
    required this.categoryName,
    required this.imeiNo,
    required this.deviceName,
    required this.master,
    required this.isSubUser,
  });
}