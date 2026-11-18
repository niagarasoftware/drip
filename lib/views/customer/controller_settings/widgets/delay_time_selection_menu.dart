import 'package:flutter/material.dart';

import '../../../../view_models/customer/condition_library_view_model.dart';

class DelayTimeSelectionMenu extends StatelessWidget {
  final int index;
  final ConditionLibraryViewModel vm;
  const DelayTimeSelectionMenu({super.key, required this.index, required this.vm,});

  static const List<String> delayTimes = [
    '--',
    '3 Sec',
    '5 Sec',
    '10 Sec',
    '20 Sec',
    '30 Sec'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 27,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          width: 0.5,
          color: Colors.grey.shade400,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 5, top: 3),
        child: PopupMenuButton<String>(
          onSelected: (String selectedValue) {
            vm.delayTimeOnChange(selectedValue, index);
          },
          itemBuilder: (BuildContext context) {
            return delayTimes.map((String value) {
              return PopupMenuItem<String>(
                value: value,
                height: 30,
                child: Text(value),
              );
            }).toList();
          },
          child: Text(
            vm.clData.cnLibrary.condition[index].delayTime,
          ),
        ),
      ),
    );
  }
}