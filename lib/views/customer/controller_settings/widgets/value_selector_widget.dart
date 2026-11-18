import 'package:flutter/cupertino.dart';
import 'package:oro_drip_irrigation/views/customer/controller_settings/widgets/sensor_value_button.dart';

import '../../../../models/customer/condition_library_model.dart';
import '../../../../utils/my_function.dart';
import '../../../../view_models/customer/condition_library_view_model.dart';
import 'condition_boolean_selector.dart';

class ValueSelectorWidget extends StatelessWidget {
  final int index;
  final ConditionLibraryViewModel vm;

  const ValueSelectorWidget({super.key, required this.index, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isSensor = vm.clData.cnLibrary.condition[index].type == 'Sensor';
    final cSNo = vm.clData.cnLibrary.condition[index].componentSNo;

    return (isSensor && !(cSNo.toString().startsWith('23.') || cSNo.toString().startsWith('40.'))) ?
    SensorValueButton(index: index, vm: vm, controller: vm.vtTEVControllers[index], onValueChanged: (newValue) {

      final sensor = vm.clData.defaultData.sensors.firstWhere((sensor) =>
      sensor.name == vm.clData.cnLibrary.condition[index].component,
        orElse: () => Sensor(objectId: 0, sNo: 0.0, name: '', objectName: ''),
      );

      if (sensor.objectName.isNotEmpty) {
        if(sensor.objectName=='Level Sensor'){
          bool hasPercentage = newValue.contains('%');
          if (hasPercentage) {
            vm.valueOnChange(newValue, index);
          }else{
            vm.valueOnChange('$newValue%', index);
          }
        }else{
          String unit = MyFunction().getUnitValue(context, sensor.objectName, newValue) ?? '';
          vm.valueOnChange('$newValue $unit', index);
        }
      }

    }) :
    ConditionBooleanSelector(index: index, vm : vm);
  }
}