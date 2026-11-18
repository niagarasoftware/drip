import 'package:flutter/services.dart';

class PopUpItemModel{
  final dynamic sNo;
  final String title;
  final Color color;

  PopUpItemModel({
    required this.sNo,
    required this.title,
    required this.color,
  });

  factory PopUpItemModel.fromJson(data){
    return PopUpItemModel(
        sNo: data['sNo'],
        title: data['title'],
        color: Color(int.parse(data['color']))
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'sNo' : sNo,
      'title' : title,
      'color' : color,
    };
  }

}



