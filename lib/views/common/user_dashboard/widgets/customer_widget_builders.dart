import 'package:flutter/cupertino.dart';
import 'package:oro_drip_irrigation/views/common/user_dashboard/widgets/sensor_widget.dart';
import 'package:oro_drip_irrigation/views/common/user_dashboard/widgets/valve_widget.dart';

import '../../../../models/customer/site_model.dart';
import '../../../customer/widgets/fan_widget.dart';
import '../../../customer/widgets/fogger_widget.dart';
import '../../../customer/widgets/gate_widget.dart';
import '../../../customer/widgets/light_widget.dart';
import '../../../customer/widgets/main_valve_widget.dart';
import '../../../customer/widgets/sensor_widget_mobile.dart';
import '../../../customer/widgets/valve_widget_mobile.dart';

List<Widget> mapWidgets<T>({
  required List<T> list,
  required Widget Function(T item, int index) builder,
}) {
  return list.asMap().entries.map((entry) {
    return builder(entry.value, entry.key);
  }).toList();
}

List<Widget> sensorList({
  required List<SensorModel> sensors,
  required String type,
  required String imagePath,
  required int customerId,
  required int controllerId,
  EdgeInsets padding = EdgeInsets.zero,
  bool isMobile = true,
}) {
  return sensors.map((sensor) {
    return Padding(
      padding: padding,
      child: isMobile ?
      SensorWidgetMobile(
        sensor: sensor,
        sensorType: type,
        imagePath: imagePath,
        customerId: customerId,
        controllerId: controllerId,
      ) :
      SensorWidget(
        sensor: sensor,
        sensorType: type,
        imagePath: imagePath,
        customerId: customerId,
        controllerId: controllerId,
      ),
    );
  }).toList();
}

List<Widget> valveList({
  required List<ValveModel> valves,
  required int customerId,
  required int controllerId,
  required int modelId,
  required bool prsOutIsAval,
  bool isNarrow = false,
}) {
  return mapWidgets(
    list: valves,
    builder: (valve, index) {
      return isNarrow ?
      ValveWidgetMobile(
        valve: valve,
        customerId: customerId,
        controllerId: controllerId,
        modelId: modelId,
      ) :
      ValveWidget(
        valve: valve,
        customerId: customerId,
        controllerId: controllerId,
        modelId: modelId,
        isLastValve: prsOutIsAval ? false : index == valves.length - 1,
      );
    },
  );
}

List<Widget> mainValveList({
  required List<MainValveModel> list,
  required int customerId,
  required int controllerId,
  required int modelId,
  required bool isNarrow,
}) {
  return mapWidgets(
    list: list,
    builder: (valve, _) {
      return BuildMainValve(
        valve: valve,
        customerId: customerId,
        controllerId: controllerId,
        modelId: modelId,
        isNarrow: isNarrow,
      );
    },
  );
}

List<Widget> lightList({required List<LightModel> list, required bool isWide}) {
  return mapWidgets(
    list: list,
    builder: (light, _) => LightWidget(objLight: light, isWide: isWide),
  );
}

List<Widget> fanList({required List<FanModel> list, required bool isWide}) {
  return mapWidgets(
    list: list,
    builder: (fan, _) => FanWidget(objFan: fan, isWide: isWide),
  );
}

List<Widget> gateList(List<GateModel> gates) {
  return mapWidgets(
    list: gates,
    builder: (gate, _) => GateWidget(objGate: gate),
  );
}

List<Widget> foggerList({required List<FoggerModel> list, required bool isWide}) {
  return mapWidgets(
    list: list,
    builder: (fog, _) => FoggerWidget(objFogger: fog, isWide: isWide),
  );
}
