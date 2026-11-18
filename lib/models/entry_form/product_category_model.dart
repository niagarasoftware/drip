class ProductCategoryModel
{
  ProductCategoryModel({
    this.categoryId = 0,
    this.categoryName = '',
    this.active = '',
  });

  int categoryId;
  String categoryName, active;

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) => ProductCategoryModel(
    categoryId: json['categoryId'],
    categoryName: json['categoryName'],
    active: json['active'],
  );

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'categoryName': categoryName,
    'active': active,
  };
}