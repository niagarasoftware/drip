class StockModel
{
  int productId, warranty, modelId;
  String categoryName, model, dtOfMnf, imeiNo;

  StockModel({
    this.productId = 0,
    this.categoryName = '',
    this.model = '',
    this.modelId = 0,
    this.imeiNo = '',
    this.dtOfMnf = '',
    this.warranty = 0,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      productId: int.tryParse(json['productId'].toString()) ?? 0,
      categoryName: json['categoryName'],
      model: json['modelDescription'],
      modelId: int.tryParse(json['modelId'].toString()) ?? 0,
      imeiNo: json['deviceId'],
      dtOfMnf: json['dateOfManufacturing'],
      warranty: int.tryParse(json['warrantyMonths'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'categoryName': categoryName,
      'modelName': model,
      'modelId': modelId,
      'deviceId': imeiNo,
      'dateOfManufacturing': dtOfMnf,
      'warrantyMonths': warranty,
    };
  }

}