import 'package:flutter/material.dart';

import '../../../../view_models/customer/condition_library_view_model.dart';
import 'build_alert_message_field.dart';
import 'build_selection_menus.dart';
import 'condition_tile.dart';
import 'condition_type_selector.dart';


Widget buildConditionCard(
    BuildContext context, ConditionLibraryViewModel vm, int index) {
  return Card(
    color: Colors.white,
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConditionTile(
            name: vm.clData.cnLibrary.condition[index].name,
            rule: vm.clData.cnLibrary.condition[index].rule,
            status: vm.clData.cnLibrary.condition[index].status,
            onStatusChanged: (value) => vm.switchStateOnChange(value, index),
            onRemove: () => vm.removeCondition(index),
            onNameChanged: (newName) => vm.updateConditionName(index, newName),
          ),
          const Divider(height: 0),
          ConditionTypeSelector(
            selectedType: vm.clData.cnLibrary.condition[index].type,
            onTypeChanged: (value) => vm.conTypeOnChange(value, index),
          ),
          const Divider(height: 0),
          buildSelectionMenus(context, vm, index),
          const SizedBox(height: 10),
          buildAlertMessageField(context, vm, index),
        ],
      ),
    ),
  );
}