class InventoryModel
{
  int productId, categoryId, modelId, productStatus, warrantyMonths, buyerId;
  String categoryName, modelName, modelDescription, productDescription, dateOfManufacturing, latestBuyer,deviceId, active;

  InventoryModel({
    this.productId = 0,
    this.categoryId = 0,
    this.categoryName ='',
    this.modelId = 0,
    this.modelName ='',
    this.modelDescription = '',
    this.deviceId = '',
    this.productDescription = '',
    this.dateOfManufacturing = '',
    this.warrantyMonths = 0,
    this.productStatus = 0,
    this.latestBuyer = '',
    this.buyerId = 0,
    this.active = '',
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) => InventoryModel(
    productId: json['productId'],
    categoryId: json['categoryId'],
    categoryName: json['categoryName'],
    modelId: json['modelId'],
    modelName: json['modelName'],
    modelDescription: json['modelDescription'],
    deviceId: json['deviceId'],
    productDescription: json['productDescription'],
    dateOfManufacturing: json['dateOfManufacturing'],
    warrantyMonths: json['warrantyMonths'],
    productStatus: json['productStatus'],
    latestBuyer: json['latestBuyer'],
    buyerId: json['buyerId'],
    active: json['active'],
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'modelId': modelId,
    'modelName': modelName,
    'modelDescription':modelDescription,
    'deviceId': deviceId,
    'productDescription': productDescription,
    'dateOfManufacturing': dateOfManufacturing,
    'warrantyMonths': warrantyMonths,
    'productStatus': productStatus,
    'latestBuyer': latestBuyer,
    'buyerId': buyerId,
    'active': active,
  };
}
