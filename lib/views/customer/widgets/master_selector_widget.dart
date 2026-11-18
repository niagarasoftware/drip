import 'package:flutter/material.dart';

import '../../../view_models/customer/customer_screen_controller_view_model.dart';

class MasterSelectorWidget extends StatelessWidget {
  final CustomerScreenControllerViewModel vm;
  final int sIndex;
  final int mIndex;

  const MasterSelectorWidget({
    super.key,
    required this.vm,
    required this.sIndex,
    required this.mIndex,
  });

  @override
  Widget build(BuildContext context) {
    final masterList = vm.mySiteList.data[sIndex].master;
    if (masterList.length <= 1) return const SizedBox();
    return PopupMenuButton<int>(
      color: Theme.of(context).primaryColorLight,
      tooltip: 'master controller',
      child: MaterialButton(
        onPressed: null,
        textColor: Colors.white,
        child: Row(
          children: [
            Text(masterList[mIndex].categoryName),
            const SizedBox(width: 3),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
      itemBuilder: (context) {
        return List.generate(masterList.length, (index) {
          final master = masterList[index];
          return PopupMenuItem<int>(
            value: index,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  master.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  master.modelName,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          );
        });
      },
      onSelected: (index) {
        vm.masterOnChanged(index);
      },
    );
  }
}