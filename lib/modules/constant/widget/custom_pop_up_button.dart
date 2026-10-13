import 'package:flutter/material.dart';
import '../model/constant_setting_type_Model.dart';

class CustomPopUpButton extends StatelessWidget {
  final List<PopUpItemModel> popUpItemModelList;
  final dynamic selectedItemSno;
  final void Function(dynamic) onSelected;
  const CustomPopUpButton({super.key, required this.popUpItemModelList, required this.selectedItemSno,required this.onSelected});

  @override
  Widget build(BuildContext context) {
    if (popUpItemModelList.isEmpty) {
      return const SizedBox();
    }
    PopUpItemModel selectedPopUpItemModel = popUpItemModelList.firstWhere(
      (item) => item.sNo == selectedItemSno,
      orElse: () => popUpItemModelList.first,
    );
    return PopupMenuButton(
      tooltip: '',
      initialValue: selectedPopUpItemModel.sNo,
        onSelected: onSelected,
        itemBuilder: (context){
          return popUpItemModelList.map((item){
            return PopupMenuItem(
              value: item.sNo,
              child: Text(item.title, style: TextStyle(fontSize: 11, color: item.color,),softWrap: true,textAlign: TextAlign.center,),
            );
          }).toList();
        },
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selectedPopUpItemModel.color),
              color: (selectedPopUpItemModel.color).withOpacity(0.1)
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(selectedPopUpItemModel.title, style: TextStyle(fontSize: 11, color: selectedPopUpItemModel.color),softWrap: true,textAlign: TextAlign.center),
        )
    );
  }
}
