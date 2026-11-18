import 'package:flutter/material.dart';

import '../../../../view_models/customer/condition_library_view_model.dart';

class ConditionBooleanSelector extends StatelessWidget {
  final int index;
  final ConditionLibraryViewModel vm;

  const ConditionBooleanSelector({super.key, required this.index, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(width: 0.5, color: Colors.grey.shade400),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 5, top: 3),
        child: PopupMenuButton<String>(
          onSelected: (String selectedValue) {
            vm.valueOnChange(selectedValue, index);
          },
          itemBuilder: (BuildContext context) {
            final type = vm.clData.cnLibrary.condition[index].type;
            final cSNo = vm.clData.cnLibrary.condition[index].componentSNo;

            final options = type == 'Combined'
                ? ['True']
                : cSNo.toString().startsWith('23.') || cSNo.toString().startsWith('40.') ?
            ['High', 'Low'] : ['True', 'False'];

            return options.map((String value) {
              return PopupMenuItem<String>(
                value: value,
                height: 30,
                child: Text(value),
              );
            }).toList();

          },
          child: Text(vm.clData.cnLibrary.condition[index].value),
        ),
      ),
    );
  }
}