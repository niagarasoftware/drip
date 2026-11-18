class DeviceListModel
{
  int productId, productStatus;
  String categoryName, model, deviceId, siteName, modifyDate;

  DeviceListModel({
    this.productId = 0,
    this.productStatus = 0,
    this.categoryName ='',
    this.model = '',
    this.deviceId = '',
    this.siteName = '',
    this.modifyDate = '',
  });

  factory DeviceListModel.fromJson(Map<String, dynamic> json) => DeviceListModel(
    productId: json['productId'],
    productStatus: json['productStatus'],
    categoryName: json['categoryName'],
    model: json['modelDescription'],
    deviceId: json['deviceId'],
    siteName: json['siteName'] ?? '',
    modifyDate: json['modifyDate'],
  );

}