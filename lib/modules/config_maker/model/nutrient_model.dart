import 'irrigation_line_model.dart';

class NutrientCategoryModel {
  String category;
  List<NutrientModel> list;

  NutrientCategoryModel({
    required this.category,
    required this.list,
  });

  factory NutrientCategoryModel.fromJson(dynamic data) {
    return NutrientCategoryModel(
      category: data['category'] ?? '',
      list: data['list'] != null
          ? (data['list'] as List<dynamic>)
              .map((item) => NutrientModel.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'list': list.map((item) => item.toJson()).toList(),
    };
  }
}

class NutrientModel {
  double sNo;
  String name;

  NutrientModel({
    required this.sNo,
    required this.name,
  });

  factory NutrientModel.fromJson(dynamic data) {
    return NutrientModel(
      sNo: intOrDoubleValidate(data['sNo']),
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sNo': sNo,
      'name': name,
    };
  }
}
