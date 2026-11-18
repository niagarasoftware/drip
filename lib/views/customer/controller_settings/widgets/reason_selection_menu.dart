import 'package:flutter/material.dart';

import '../../../../view_models/customer/condition_library_view_model.dart';

class ReasonSelectionMenu extends StatelessWidget {
  final int index;
  final ConditionLibraryViewModel vm;
  const ReasonSelectionMenu({super.key, required this.index, required this.vm,});

  static const List<String> reasons = [
    '--',
    'Low flow',
    'High flow',
    'No flow',
    'High pressure',
    'Low pressure',
    'Over heating',
    'Low level',
    'High level',
    'Time limit',
    'Dry run'
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
          onSelected: (String selectedValue) =>
              vm.reasonOnChange(selectedValue, index),
          itemBuilder: (BuildContext context) {
            return reasons.map((String value) {
              return PopupMenuItem<String>(
                value: value,
                height: 30,
                child: Text(value),
              );
            }).toList();
          },
          child: Text(
            vm.clData.cnLibrary.condition[index].reason,
          ),
        ),
      ),
    );
  }
}