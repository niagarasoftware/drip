import 'package:flutter/material.dart';

import '../../../../view_models/customer/condition_library_view_model.dart';

class ThresholdSelectorWidget extends StatelessWidget {
  final int index;
  final ConditionLibraryViewModel vm;

  const ThresholdSelectorWidget({super.key, required this.index, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 27,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(width: 0.5, color: Colors.grey.shade400),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 5, top: 3),
          child: PopupMenuButton<String>(
            onSelected: (String selectedValue) {
              vm.thresholdOnChange(selectedValue, index);
            },
            itemBuilder: (BuildContext context) {
              final type = vm.clData.cnLibrary.condition[index].type;
              final cSno = vm.clData.cnLibrary.condition[index].componentSNo;

              final options = type == 'Sensor'
                  ? (cSno.toString().startsWith('23.') || cSno.toString().startsWith('40.')) ?
                    ['is'] : ['Below', 'Above', 'Equal to']
                  : type == 'Program'
                  ? ['is Running', 'is Starting', 'is Ending']
                  : ['Anyone is', 'Both are'];

              return options.map((String value) {
                return PopupMenuItem<String>(
                  value: value,
                  height: 30,
                  child: Text(value),
                );
              }).toList();
            },
            child: Text(vm.clData.cnLibrary.condition[index].threshold),
          ),
        ),
      ),
    );
  }
}