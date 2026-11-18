import 'package:flutter/cupertino.dart';

import '../widget/arrow_tab.dart';

class ConstantMenuModel{
  final int dealerDefinitionId;
  final String parameter;
  ValueNotifier<ArrowTabState> arrowTabState;

  ConstantMenuModel({
    required this.dealerDefinitionId,
    required this.parameter,
    required this.arrowTabState,
  });

  factory ConstantMenuModel.fromJson(data){
    return ConstantMenuModel(
        dealerDefinitionId: data['dealerDefinitionId'],
        parameter: data['parameter'],
        arrowTabState: ValueNotifier(ArrowTabState.inComplete)
    );
  }
}