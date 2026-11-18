import 'package:flutter/material.dart';

import '../../../../view_models/customer/condition_library_view_model.dart';

class ConditionLabelsColumn extends StatelessWidget {
  const ConditionLabelsColumn({super.key, required this.vm, required this.index});
  final ConditionLibraryViewModel vm;
  final int index;

  @override
  Widget build(BuildContext context) {

    final component = vm.clData.cnLibrary.condition[index].component;

    return SizedBox(
      width: 125,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Component', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          const Text('Parameter', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          const Text('Value/Threshold', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Text((component == "Any irrigation program" || component == "Any fertilizer program"
              || component == "Any Pre(Time/Qty) program") ?
          'Where ?' : 'Reason', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 15),
          const Text('Delay Time', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}