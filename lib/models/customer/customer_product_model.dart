class CustomerProductModel
{
  int productId, productStatus;
  String categoryName, model, deviceId, siteName, modifyDate;

  CustomerProductModel({
    this.productId = 0,
    this.productStatus = 0,
    this.categoryName ='',
    this.model = '',
    this.deviceId = '',
    this.siteName = '',
    this.modifyDate = '',
  });

  factory CustomerProductModel.fromJson(Map<String, dynamic> json) => CustomerProductModel(
    productId: json['productId'],
    productStatus: json['productStatus'],
    categoryName: json['categoryName'],
    model: json['modelName'],
    deviceId: json['deviceId'],
    siteName: json['siteName'] ?? '--',
    modifyDate: json['dateOfManufacturing'],
  );

}