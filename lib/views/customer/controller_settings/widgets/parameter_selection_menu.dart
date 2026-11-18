import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/view_models/create_account_view_model.dart';
import '../../../../view_models/customer/condition_library_view_model.dart';

class ParameterSelectionMenu extends StatelessWidget {
  final int index;
  final ConditionLibraryViewModel vm;

  const ParameterSelectionMenu({ super.key,
    required this.index,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final condition = vm.clData.cnLibrary.condition[index];

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
            vm.parameterOnChange(selectedValue, index);
          },
          itemBuilder: (BuildContext context) {
            if (condition.type == 'Sensor') {
              final selectedSensor = vm.clData.defaultData.sensors.firstWhereOrNull((sensor) =>
              sensor.name == condition.component);

              final filteredParameters = vm
                  .clData.defaultData.sensorParameter
                  .where((param) => param.objectId == selectedSensor?.objectId)
                  .toList();

              return filteredParameters.map<PopupMenuEntry<String>>((param) {
                return PopupMenuItem<String>(
                  value: param.parameter,
                  height: 35,
                  child: Text(param.parameter),
                );
              }).toList();
            } else {
              return ['Status'].map((String value) {
                return PopupMenuItem<String>(
                  value: value,
                  height: 30,
                  child: Text(value),
                );
              }).toList();
            }
          },
          child: Text(condition.parameter),
        ),
      ),
    );
  }
}