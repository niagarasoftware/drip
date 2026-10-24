class NutrientCategoryModel {
  String category;
  List<NutrientModel> list;

  NutrientCategoryModel({
    required this.category,
    required this.list,
  });

  factory NutrientCategoryModel.fromJson(Map<String, dynamic> json) {
    return NutrientCategoryModel(
      category: json['category'] ?? '',
      list: json['list'] != null
          ? (json['list'] as List<dynamic>)
              .map((item) => NutrientModel.fromJson(item as Map<String, dynamic>))
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

  factory NutrientModel.fromJson(Map<String, dynamic> json) {
    return NutrientModel(
      sNo: (json['sNo'] is num)
          ? (json['sNo'] as num).toDouble()
          : (double.tryParse(json['sNo'].toString()) ?? 0.0),
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sNo': sNo,
      'name': name,
    };
  }
}
