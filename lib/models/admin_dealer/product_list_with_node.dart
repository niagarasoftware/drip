class ProductListWithNode {
  final int userGroupId;
  final String groupName;
  final String groupAddress;
  final String active;
  final List<Master> master;

  ProductListWithNode({
    required this.userGroupId,
    required this.groupName,
    required this.groupAddress,
    required this.active,
    required this.master,
  });

  factory ProductListWithNode.fromJson(Map<String, dynamic> json) {
    List<Master> masters = [];
    if (json['master'] != null) {
      masters = List<Master>.from(json['master'].map((masterJson) => Master.fromJson(masterJson)));
    }
    return ProductListWithNode(
      userGroupId: json['userGroupId'],
      groupName: json['groupName'],
      groupAddress: json['groupAddress'],
      active: json['active'],
      master: masters,
    );
  }
}

class Master {
  final int controllerId;
  final int dealerId;
  final int productId;
  final String deviceId;
  final String deviceName;
  final int productStatus;
  final int categoryId;
  final String categoryName;
  final int modelId;
  final String modelName;
  final String modelDescription;
  final String inputObjectId;
  final String outputObjectId;



  Master({
    required this.controllerId,
    required this.dealerId,
    required this.productId,
    required this.deviceId,
    required this.deviceName,
    required this.productStatus,
    required this.categoryId,
    required this.categoryName,
    required this.modelId,
    required this.modelName,
    required this.modelDescription,
    required this.inputObjectId,
    required this.outputObjectId,
  });

  factory Master.fromJson(Map<String, dynamic> json) {

    return Master(
      controllerId: json['controllerId'],
      dealerId: json['dealerId'],
      productId: json['productId'],
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      productStatus: json['productStatus'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      modelId: json['modelId'],
      modelName: json['modelName'],
      modelDescription: json['modelDescription'],
      inputObjectId: json['inputObjectId'],
      outputObjectId: json['outputObjectId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "controllerId": controllerId,
      "dealerId": dealerId,
      "productId": productId,
      "deviceId": deviceId,
      "deviceName": deviceName,
      "productStatus": productStatus,
      "categoryId": categoryId,
      "categoryName": categoryName,
      "modelId": modelId,
      "modelName": modelName,
      "modelDescription": modelDescription,
      "inputObjectId": inputObjectId,
      "outputObjectId": outputObjectId,
    };
  }
}
