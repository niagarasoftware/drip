import 'package:flutter/material.dart';

import '../../../view_models/customer/customer_screen_controller_view_model.dart';

class IrrigationLineSelectorWidget extends StatelessWidget {
  final CustomerScreenControllerViewModel vm;

  const IrrigationLineSelectorWidget({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final master = vm.mySiteList.data[vm.sIndex].master[vm.mIndex];
    if (master.categoryId != 1 || master.irrigationLine.length <= 1) {
      return const SizedBox();
    }
    return DropdownButton<int>(
      underline: Container(),
      items: List.generate(master.irrigationLine.length, (index) {
        final line = master.irrigationLine[index];
        return DropdownMenuItem<int>(
          value: index,
          child: Text(
            line.name,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      }),
      onChanged: (selectedIndex) {
        if (selectedIndex != null) {
          vm.lineOnChanged(selectedIndex);
        }
      },
      value: vm.lIndex,
      dropdownColor: Theme.of(context).primaryColorLight,
      iconEnabledColor: Colors.white,
      iconDisabledColor: Colors.white,
      focusColor: Colors.transparent,
    );
  }
}