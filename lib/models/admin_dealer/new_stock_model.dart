class ProductModel
{
  ProductModel({
    this.categoryId = 0,
    this.modelId = 0,
    this.categoryName = '',
    this.modelName = '',
    this.modelDescription = '',
    this.active = '',
  });

  int categoryId, modelId;
  String categoryName, modelName, modelDescription, active;

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    categoryId: json['categoryId'],
    modelId: json['modelId'],
    categoryName: json['categoryName'],
    modelName: json['modelName'],
    modelDescription: json['modelDescription'],
    active: json['active'],
  );

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'modelId': modelId,
    'categoryName': categoryName,
    'modelName': modelName,
    'modelDescription': modelDescription,
    'active': active,
  };
}