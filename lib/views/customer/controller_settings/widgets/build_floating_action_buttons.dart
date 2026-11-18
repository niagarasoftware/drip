import 'package:flutter/material.dart';

import '../../../../view_models/customer/condition_library_view_model.dart';

Widget buildFloatingActionButtons(BuildContext context,
    ConditionLibraryViewModel vm, int customerId, int controllerId, int userId, String deviceId) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
          'Total: ${vm.clData.cnLibrary.condition.length} of ${vm.clData.defaultData.conditionLimit}'),
      const SizedBox(width: 10),
      MaterialButton(
        color: Theme.of(context).primaryColorLight,
        textColor: Colors.white,
        onPressed: vm.clData.cnLibrary.condition.length !=
            vm.clData.defaultData.conditionLimit
            ? () => vm.createNewCondition()
            : null,
        child: const Text('Create condition'),
      ),
      const SizedBox(width: 10),
      MaterialButton(
        color: Colors.green,
        textColor: Colors.white,
        onPressed: () => vm.saveConditionLibrary(
            context, customerId, controllerId, userId, deviceId),
        child: const Text('Save'),
      ),
    ],
  );
}