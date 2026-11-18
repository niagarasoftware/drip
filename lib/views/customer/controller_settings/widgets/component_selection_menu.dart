import 'package:flutter/material.dart';

import '../../../../view_models/customer/condition_library_view_model.dart';
import 'component_selection.dart';

class ComponentSelectionMenu extends StatelessWidget {
  final int index;
  final ConditionLibraryViewModel vm;
  const ComponentSelectionMenu({super.key, required this.index, required this.vm});

  @override
  Widget build(BuildContext context) {
    final condition = vm.clData.cnLibrary.condition[index];

    if(condition.type == 'Combined'){
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              height: 27,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(12),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(width: 0.5, color: Colors.grey.shade400),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 5, top: 3),
                child: PopupMenuButton<String>(
                  tooltip: 'Select exactly 2 conditions',
                  onSelected: (String cName) {
                    final selectedCondition = vm.clData.cnLibrary.condition
                        .firstWhere((c) => c.name == cName);
                    int sNo = selectedCondition.sNo;
                    vm.combinedTO(index, cName, sNo);
                  },
                  itemBuilder: (BuildContext context) {
                    return vm.getAvailableCondition(index).map((String source) {
                      return CheckedPopupMenuItem<String>(
                        value: source,
                        height: 30,
                        checked: vm.connectedTo[index].contains(source),
                        child: Text(source),
                      );
                    }).toList();
                  },
                  child: Text(condition.component),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'remove combined condition',
              iconSize: 20,
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(),
              onPressed: () {
                vm.clearCombined(index);
              }, icon: const Icon(Icons.remove_circle_outline, color: Colors.red))
        ],
      );
    }

    return Container(
      width: double.infinity,
      height: 27,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(width: 0.5, color: Colors.grey.shade400),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 5, top: 3),
        child: PopupMenuButton<ComponentSelection>(
          tooltip: condition.type == 'Sensor'? 'Select your sensor': 'Select your program',
          onSelected: (ComponentSelection selected) {
            vm.componentOnChange(selected.name, index, selected.sNo);
          },
          itemBuilder: (BuildContext context) {
            if (condition.type == 'Sensor') {
              return vm.clData.defaultData.sensors.map<PopupMenuEntry<ComponentSelection>>((sensor) {
                return PopupMenuItem<ComponentSelection>(
                  value: ComponentSelection(
                    name: sensor.name,
                    sNo: sensor.sNo.toString(),
                  ),
                  height: 35,
                  child: Text(sensor.name),
                );
              }).toList();
            } else {
              return vm.clData.defaultData.program.map<PopupMenuEntry<ComponentSelection>>((program) {
                return PopupMenuItem<ComponentSelection>(
                  value: ComponentSelection(
                    name: program.name,
                    sNo: program.sNo.toString(),
                  ),
                  height: 35,
                  child: Text(program.name),
                );
              }).toList();
            }
          },
          child: Text(condition.component),
        ),
      ),
    );
  }
}