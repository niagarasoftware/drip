import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/app.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/fertigation_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/pump_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/source_configuration.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../Constants/properties.dart';
import '../model/device_object_model.dart';
import '../model/filtration_model.dart';
import '../model/irrigation_line_model.dart';
import '../model/source_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';
import 'config_object_name_editing.dart';
import 'fertilization_configuration.dart';
import 'filtration_configuration.dart';

class LineConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const LineConfiguration({super.key, required this.configPvd});

  @override
  State<LineConfiguration> createState() => _LineConfigurationState();
}

class _LineConfigurationState extends State<LineConfiguration> {
  double pumpExtendedWidth = 0.0;
  late ThemeData themeData;
  late bool themeMode;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    themeData = Theme.of(context);
    themeMode = themeData.brightness == Brightness.light;
  }

  @override
  Widget build(BuildContext context) {
    IrrigationLineModel? selectedIrrigationLine = widget.configPvd.line.cast<IrrigationLineModel?>().firstWhere((line)=> line!.commonDetails.sNo == widget.configPvd.selectedLineSno, orElse: ()=> null);
    print('selectedIrrigationLine ::: ${selectedIrrigationLine!.commonDetails.name}');
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(builder: (context, constraint){
        return Scaffold(
          body: SafeArea(
            child: Container(
              width: constraint.maxWidth,
              height: constraint.maxHeight,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).primaryColor == Colors.black ? Colors.white10 : Colors.white
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: getLineTabs(),
                  ),
                  const SizedBox(height: 10,),
                  Expanded(
                    child: Container(
                      // padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          spacing: 20,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  spacing: 10,
                                  children: [
                                    IconButton(
                                        onPressed: (){
                                          showModalBottomSheet(
                                              shape: Border.all(),
                                              isScrollControlled: true,
                                              context: context,
                                              builder: (context){
                                                return SizedBox(
                                                  width: 700,
                                                  child: ConfigObjectNameEditing(listOfObjectInLine: widget.configPvd.listOfGeneratedObject, configPvd: widget.configPvd,),
                                                );
                                              }
                                          );
                                        },
                                        icon: const Icon(Icons.dataset)
                                    ),
                                    if(availability(AppConstants.sourceObjectId) && !AppConstants.aquacultureModelList.contains(widget.configPvd.masterData['modelId']))
                                      getLineParameter(
                                          line: selectedIrrigationLine,
                                          currentParameterValue: selectedIrrigationLine.waterSource,
                                          parameterType: LineParameter.source,
                                          objectId: AppConstants.sourceObjectId,
                                          objectName: 'Source only for monitoring',
                                          listOfObject: widget.configPvd.listOfGeneratedObject.where((object){
                                            return object.objectId == AppConstants.sourceObjectId;
                                          }).toList(),
                                          validateAllLine: false
                                      ),
                                    if(widget.configPvd.pump.any((pump) => pump.pumpType == 1))
                                      getLineParameter(
                                          line: selectedIrrigationLine,
                                          currentParameterValue: selectedIrrigationLine.sourcePump,
                                          parameterType: LineParameter.sourcePump,
                                          objectId: AppConstants.pumpObjectId,
                                          objectName: 'Source Pump',
                                          validateAllLine: false,
                                          listOfObject: widget.configPvd.listOfGeneratedObject.where((pumpObject){
                                            return widget.configPvd.pump.any((pump) => pump.commonDetails.sNo == pumpObject.sNo && pump.pumpType == 1);
                                          }).toList()
                                      ),
                                    if(widget.configPvd.pump.any((pump) => pump.pumpType == 2))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.irrigationPump, parameterType: LineParameter.irrigationPump, objectId: AppConstants.pumpObjectId, objectName: 'Irrigation Pump', validateAllLine: false,
                                          listOfObject: widget.configPvd.listOfGeneratedObject.where((pumpObject){
                                            return widget.configPvd.pump.any((pump) => pump.commonDetails.sNo == pumpObject.sNo && pump.pumpType == 2);
                                          }).toList()
                                      ),
                                    if(widget.configPvd.pump.any((pump) => pump.pumpType == 3))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.aerator, parameterType: LineParameter.aerator, objectId: AppConstants.pumpObjectId, objectName: 'Aerator Pump', validateAllLine: false,
                                          listOfObject: widget.configPvd.listOfGeneratedObject.where((pumpObject){
                                            return widget.configPvd.pump.any((pump) => pump.commonDetails.sNo == pumpObject.sNo && pump.pumpType == 3);
                                          }).toList()
                                      ),
                                    if(availability(AppConstants.valveObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.valve, parameterType: LineParameter.valve, objectId: AppConstants.valveObjectId, objectName: 'Valve', validateAllLine: true),
                                    if(availability(AppConstants.flowControlValveObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.flowControlValve, parameterType: LineParameter.flowControlValve, objectId: AppConstants.flowControlValveObjectId, objectName: 'Flow Control Valve', validateAllLine: true),
                                    if(availability(AppConstants.mainValveObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.mainValve, parameterType: LineParameter.mainValve, objectId: AppConstants.mainValveObjectId, objectName: 'Main Valve', validateAllLine: true),
                                    if(availability(AppConstants.lightObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.light, parameterType: LineParameter.light, objectId: AppConstants.lightObjectId, objectName: 'Light', validateAllLine: true),
                                    if(availability(AppConstants.gateObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.gate, parameterType: LineParameter.gate, objectId: AppConstants.gateObjectId, objectName: 'Gate', validateAllLine: true),
                                    if(availability(AppConstants.fanObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.fan, parameterType: LineParameter.fan, objectId: AppConstants.fanObjectId, objectName: 'Fan', validateAllLine: true),
                                    if(availability(AppConstants.foggerObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.fogger, parameterType: LineParameter.fogger, objectId: AppConstants.foggerObjectId, objectName: 'Fogger', validateAllLine: true),
                                    if(availability(AppConstants.mistObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.mist, parameterType: LineParameter.mist, objectId: AppConstants.mistObjectId, objectName: 'Mist', validateAllLine: true),
                                    if(availability(AppConstants.heaterObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.heater, parameterType: LineParameter.heater, objectId: AppConstants.heaterObjectId, objectName: 'Heater', validateAllLine: true),
                                    if(availability(AppConstants.humidityObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.humidity, parameterType: LineParameter.humidity, objectId: AppConstants.humidityObjectId, objectName: 'Humidity', validateAllLine: true),
                                    if(availability(AppConstants.screenObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.screen, parameterType: LineParameter.screen, objectId: AppConstants.screenObjectId, objectName: 'Screen', validateAllLine: true),
                                    if(availability(AppConstants.co2ObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.co2, parameterType: LineParameter.co2, objectId: AppConstants.co2ObjectId, objectName: 'Co2', validateAllLine: true),
                                    if(availability(AppConstants.moistureObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.moisture, parameterType: LineParameter.moisture, objectId: AppConstants.moistureObjectId, objectName: 'Moisture', validateAllLine: true),
                                    if(availability(AppConstants.ventObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.vent, parameterType: LineParameter.vent, objectId: AppConstants.ventObjectId, objectName: 'Vent', validateAllLine: true),
                                    if(availability(AppConstants.pesticideObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.pesticides, parameterType: LineParameter.pesticides, objectId: AppConstants.pesticideObjectId, objectName: 'Pesticides', validateAllLine: true),
                                    if(availability(AppConstants.soilTemperatureObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.soilTemperature, parameterType: LineParameter.soilTemperature, objectId: AppConstants.soilTemperatureObjectId, objectName: 'Soil Temperature', validateAllLine: true),
                                    if(availability(AppConstants.temperatureObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: selectedIrrigationLine.temperature, parameterType: LineParameter.temperature, objectId: AppConstants.temperatureObjectId, objectName: 'Temperature', validateAllLine: true),
                                    if(availability(AppConstants.waterMeterObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: [selectedIrrigationLine.waterMeter], parameterType: LineParameter.waterMeter, objectId: AppConstants.waterMeterObjectId, objectName: 'Water Meter', validateAllLine: true, singleSelection: true),
                                    if(availability(AppConstants.analogWaterMeterObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: [selectedIrrigationLine.analogWaterMeter], parameterType: LineParameter.analogWaterMeter, objectId: AppConstants.analogWaterMeterObjectId, objectName: 'Analog Water Meter', validateAllLine: true, singleSelection: true),
                                    if(availability(AppConstants.powerSupplyObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: [selectedIrrigationLine.powerSupply], parameterType: LineParameter.powerSupply, objectId: AppConstants.powerSupplyObjectId, objectName: 'Power Supply', validateAllLine: true, singleSelection: true),
                                    if(availability(AppConstants.pressureSwitchObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: [selectedIrrigationLine.pressureSwitch], parameterType: LineParameter.pressureSwitch, objectId: AppConstants.pressureSwitchObjectId, objectName: 'Pressure Switch', validateAllLine: true, singleSelection: true,),
                                    if(availability(AppConstants.pressureSensorObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: [selectedIrrigationLine.pressureIn], parameterType: LineParameter.pressureIn, objectId: AppConstants.pressureSensorObjectId, objectName: 'Pressure In', validateAllLine: true, singleSelection: true,
                                          listOfObject: widget.configPvd.listOfGeneratedObject
                                              .where((object) => (object.objectId == AppConstants.pressureSensorObjectId && object.sNo != selectedIrrigationLine.pressureOut))
                                              // .where((object) => (!widget.configPvd.filtration.any((filterSite) => [filterSite.pressureIn,filterSite.pressureOut].contains(object.sNo)) && object.sNo != selectedIrrigationLine.pressureOut))
                                              .where((object) => (!widget.configPvd.line.any((line) => line.commonDetails.sNo != selectedIrrigationLine.commonDetails.sNo && [line.pressureIn,line.pressureOut].contains(object.sNo)) && object.sNo != selectedIrrigationLine.pressureOut))
                                              .toList()),
                                    if(availability(AppConstants.pressureSensorObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: [selectedIrrigationLine.pressureOut], parameterType: LineParameter.pressureOut, objectId: AppConstants.pressureSensorObjectId, objectName: 'Pressure Out', validateAllLine: true, singleSelection: true,
                                          listOfObject: widget.configPvd.listOfGeneratedObject
                                              .where((object) => (object.objectId == AppConstants.pressureSensorObjectId && object.sNo != selectedIrrigationLine.pressureIn))                                              // .where((object) => (!widget.configPvd.filtration.any((filterSite) => [filterSite.pressureIn,filterSite.pressureOut].contains(object.sNo)) && object.sNo != selectedIrrigationLine.pressureIn))
                                              .where((object) => (!widget.configPvd.line.any((line) => line.commonDetails.sNo != selectedIrrigationLine.commonDetails.sNo && [line.pressureIn,line.pressureOut].contains(object.sNo)) && object.sNo != selectedIrrigationLine.pressureIn))
                                              .toList()),
                                    if(availability(AppConstants.fertilizerSiteObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: [selectedIrrigationLine.centralFertilization], parameterType: LineParameter.centralFertilization, objectId: AppConstants.fertilizerSiteObjectId, objectName: 'Central Fertilization', validateAllLine: false, singleSelection: true, listOfObject: widget.configPvd.fertilization.where((site) => (site.siteMode == 1)).toList().map((site) => site.commonDetails).toList()),
                                    if(availability(AppConstants.fertilizerSiteObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: [selectedIrrigationLine.localFertilization], parameterType: LineParameter.localFertilization, objectId: AppConstants.fertilizerSiteObjectId, objectName: 'Local Fertilization', validateAllLine: false, singleSelection: true, listOfObject: widget.configPvd.fertilization.where((site) => (site.siteMode == 2)).toList().map((site) => site.commonDetails).toList()),
                                    if(availability(AppConstants.filterSiteObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: [selectedIrrigationLine.centralFiltration], parameterType: LineParameter.centralFiltration, objectId: AppConstants.filterSiteObjectId, objectName: 'Central Filtration', validateAllLine: false, singleSelection: true, listOfObject: widget.configPvd.filtration.where((site) => (site.siteMode == 1)).toList().map((site) => site.commonDetails).toList()),
                                    if(availability(AppConstants.filterSiteObjectId))
                                      getLineParameter(line: selectedIrrigationLine, currentParameterValue: [selectedIrrigationLine.localFiltration], parameterType: LineParameter.localFiltration, objectId: AppConstants.filterSiteObjectId, objectName: 'Local Filtration', validateAllLine: false, singleSelection: true, listOfObject: widget.configPvd.filtration.where((site) => (site.siteMode == 2)).toList().map((site) => site.commonDetails).toList()),
                                  ],
                                ),
                              ),
                            ),
                            Stack(
                              children: [
                                if(selectedIrrigationLine.aerator.isNotEmpty)
                                  Wrap(
                                    spacing: 10,
                                    children: List.generate(selectedIrrigationLine.aerator.length, (index){
                                      return Column(
                                        children: [
                                          Image.asset(
                                              width: 100,
                                              height: 100,
                                              'assets/png/aerators_o.png'
                                          ),
                                          Text('${getObjectName(selectedIrrigationLine.aerator[index], widget.configPvd).name}')
                                        ],
                                      );
                                    }),
                                  ),
                                diagramWidget(selectedIrrigationLine),
                                Positioned(
                                  right: 10,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    spacing: 10,
                                    children: [
                                      IconButton(
                                          onPressed: (){
                                            setState(() {
                                              if(widget.configPvd.ratio < 1){
                                                widget.configPvd.ratio += 0.1;
                                              }
                                            });
                                          },
                                          icon: const Icon(Icons.zoom_in)
                                      ),
                                      const Text('Zoom'),
                                      IconButton(
                                          onPressed: (){
                                            setState(() {
                                              if(widget.configPvd.ratio > 0){
                                                widget.configPvd.ratio -= 0.1;
                                              }
                                            });
                                          },
                                          icon: const Icon(Icons.zoom_out)
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            Row(
                              spacing: 20,
                              children: [
                                for(var device in widget.configPvd.listOfDeviceModel.where((device) => (device.masterId != null && device.categoryId == 4)).toList())
                                  Tooltip(
                                    verticalOffset: -80,
                                    message: 'Do you want weather station \n for ${selectedIrrigationLine.commonDetails.name}',
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 5),
                                      padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                                      width: 300,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.white,
                                          boxShadow: const [
                                            BoxShadow(color: Colors.grey, blurRadius: 5)
                                          ]
                                      ),
                                      child: Row(
                                        spacing: 20,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: themeData.primaryColor.withValues(alpha: 0.1),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10.0),
                                              child: Image.asset(
                                                'assets/Images/Png/weather_station.png',
                                                width: 60,
                                                height: 60,
                                              ),
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              Text(device.deviceName, style: themeData.textTheme.labelLarge,),
                                              Text(device.deviceId, style: themeData.textTheme.labelSmall),
                                            ],
                                          ),
                                          Checkbox(
                                              value: selectedIrrigationLine.weatherStation.contains(device.controllerId),
                                              onChanged: (value){
                                                setState(() {
                                                  if(value! == true){
                                                    selectedIrrigationLine.weatherStation.add(device.controllerId);
                                                  }else{
                                                    selectedIrrigationLine.weatherStation.remove(device.controllerId);
                                                  }
                                                });
                                              }
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                              ],
                            ),
                            checkingAnyParameterAvailableInLine(selectedIrrigationLine),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget externalSource(IrrigationLineModel selectedIrrigationLine){
    List<SourceModel> externalSource = [];
    for(var src in widget.configPvd.source){
      if(src.valves.any((valves) => selectedIrrigationLine.valve.contains(valves))){
        externalSource.add(src);
      }else if(
      (src.inletPump.isNotEmpty && src.inletPump.any((pump) => [...selectedIrrigationLine.sourcePump, ...selectedIrrigationLine.irrigationPump].contains(pump)))
          && src.outletPump.isEmpty
      ){
        externalSource.add(src);
      }else if(selectedIrrigationLine.waterSource.contains(src.commonDetails.sNo)){
        externalSource.add(src);
      }
    }
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: ResponsiveGridList(
        horizontalGridMargin: 0,
        verticalGridMargin: 10,
        minItemWidth: 400,
        shrinkWrap: true,
        listViewBuilderOptions: ListViewBuilderOptions(
          physics: const NeverScrollableScrollPhysics(),
        ),
        children: [
          for(var source in externalSource)
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(width: 0.5, color: const Color(0xff008CD7)),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        offset: const Offset(0, 4),
                        blurRadius: 4,
                        spreadRadius: 0,
                        color: const Color(0xff8B8282).withValues(alpha: 0.2)
                    )
                  ]
              ),
              height: 200,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        if(source.inletPump.isNotEmpty)
                          ...[
                            if(source.inletPump.length == 1)
                              singlePump(source, true, widget.configPvd)
                            else
                              multiplePump(source, true, widget.configPvd)
                          ],
                        Stack(
                          children: [
                            getTankImage(source, widget.configPvd),
                            Positioned(
                              left : 5,
                              top: 0,
                              child: Text(getObjectName(source.commonDetails.sNo!, widget.configPvd).name!,style: AppProperties.listTileBlackBoldStyle,),
                            ),
                          ],
                        ),
                        if(source.outletPump.isNotEmpty)
                          ...[
                            if(source.outletPump.length == 1)
                              singlePump(source, false, widget.configPvd)
                            else
                              multiplePump(source, false, widget.configPvd)
                          ],
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Inlet Valve : ', style: TextStyle(fontWeight: FontWeight.bold),),
                        Text(source.valves.map((valSno) => getObjectName(valSno, widget.configPvd).name).join(','), style: TextStyle(color: Theme.of(context).primaryColor),),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Outlet Valve : ', style: TextStyle(fontWeight: FontWeight.bold),),
                        Text(source.outletValves.map((valSno) => getObjectName(valSno, widget.configPvd).name).join(','), style: TextStyle(color: Theme.of(context).primaryColor),)
                      ],
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget checkingAnyParameterAvailableInLine(IrrigationLineModel selectedIrrigationLine){
    List<Widget> childrenWidget = [
      ...getObjectInLine(selectedIrrigationLine.mainValve, AppConstants.mainValveObjectId),
      if(selectedIrrigationLine.waterMeter != 0.0)
        ...getObjectInLine([selectedIrrigationLine.waterMeter], AppConstants.waterMeterObjectId),
      if(selectedIrrigationLine.analogWaterMeter != 0.0)
        ...getObjectInLine([selectedIrrigationLine.analogWaterMeter], AppConstants.analogWaterMeterObjectId),
      ...getObjectInLine(selectedIrrigationLine.valve, AppConstants.valveObjectId),
      ...getObjectInLine(selectedIrrigationLine.mainValve, AppConstants.mainValveObjectId),
      ...getObjectInLine(selectedIrrigationLine.flowControlValve, AppConstants.flowControlValveObjectId),
      ...getObjectInLine(selectedIrrigationLine.light, AppConstants.lightObjectId),
      ...getObjectInLine(selectedIrrigationLine.gate, AppConstants.gateObjectId),
      ...getObjectInLine(selectedIrrigationLine.fan, AppConstants.fanObjectId),
      ...getObjectInLine(selectedIrrigationLine.fogger, AppConstants.foggerObjectId),
      ...getObjectInLine(selectedIrrigationLine.mist, AppConstants.mistObjectId),
      ...getObjectInLine(selectedIrrigationLine.heater, AppConstants.heaterObjectId),
      ...getObjectInLine(selectedIrrigationLine.humidity, AppConstants.humidityObjectId),
      ...getObjectInLine(selectedIrrigationLine.screen, AppConstants.screenObjectId),
      ...getObjectInLine(selectedIrrigationLine.co2, AppConstants.co2ObjectId),
      ...getObjectInLine(selectedIrrigationLine.moisture, AppConstants.moistureObjectId),
      ...getObjectInLine(selectedIrrigationLine.vent, AppConstants.ventObjectId),
      ...getObjectInLine(selectedIrrigationLine.pesticides, AppConstants.pesticideObjectId),
      ...getObjectInLine(selectedIrrigationLine.soilTemperature, AppConstants.soilTemperatureObjectId),
      ...getObjectInLine(selectedIrrigationLine.temperature, AppConstants.temperatureObjectId),
      if(selectedIrrigationLine.pressureIn != 0.0)
        ...getObjectInLine([selectedIrrigationLine.pressureIn], AppConstants.pressureSensorObjectId),
      if(selectedIrrigationLine.pressureOut != 0.0)
        ...getObjectInLine([selectedIrrigationLine.pressureOut], AppConstants.pressureSensorObjectId),
      if(selectedIrrigationLine.pressureSwitch != 0.0)
        ...getObjectInLine([selectedIrrigationLine.pressureSwitch], AppConstants.pressureSwitchObjectId),
      if(selectedIrrigationLine.powerSupply != 0.0)
        ...getObjectInLine([selectedIrrigationLine.powerSupply], AppConstants.pressureSwitchObjectId),
    ];
    return childrenWidget.isEmpty ? Container() : Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: themeData.primaryColor.withValues(alpha: 0.3))
      ),
      child: ResponsiveGridList(
        horizontalGridMargin: 0,
        verticalGridMargin: 10,
        minItemWidth: 100,
        shrinkWrap: true,
        listViewBuilderOptions: ListViewBuilderOptions(
          physics: const NeverScrollableScrollPhysics(),
        ),
        children: childrenWidget,
      ),
    );
  }

  List<Widget> getObjectInLine(List<double> parameters, int objectId){
    return [
      for(var objectSno in parameters)
        Column(
          children: [
            Image.asset(
              'assets/Images/Png/objectId_$objectId.png',
              width: 30,
              height: 30,
            ),
            // SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg', color: themeMode ? Colors.black : Colors.white,),
            Text(getObjectName(objectSno, widget.configPvd).name!, style: AppProperties.listTileBlackBoldStyle,)
          ],
        )
    ];

  }

  bool availability(objectId){
    return widget.configPvd.listOfSampleObjectModel.any((object) => (object.objectId == objectId && object.count != '0'));
  }

  Widget getLineTabs(){
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for(var line in widget.configPvd.line)
            ...[
              InkWell(
                onTap: (){
                  setState(() {
                    widget.configPvd.selectedLineSno = line.commonDetails.sNo!;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: widget.configPvd.selectedLineSno == line.commonDetails.sNo! ? const Color(0xff1C863F) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(line.commonDetails.name!.toString(),style: TextStyle(color: widget.configPvd.selectedLineSno == line.commonDetails.sNo! ? Colors.white : Colors.black, fontSize: 13),),
                ),
              ),
              const SizedBox(width: 10,)
            ]
        ],
      ),
    );
  }

  Widget diagramWidget(IrrigationLineModel selectedIrrigationLine){
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1700,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getSuitableSourceConnection(selectedIrrigationLine),
            Expanded(
                child: externalSource(selectedIrrigationLine)
            )
          ],
        ),
      ),
    );
  }

  Widget getLineParameter({
    required IrrigationLineModel line,
    required List<double> currentParameterValue,
    required LineParameter parameterType,
    required int objectId,
    required String objectName,
    required bool validateAllLine,
    bool singleSelection = false,
    List<DeviceObjectModel>? listOfObject
  }){

    if(listOfObject != null){
      print("${parameterType.name}  ===== ${listOfObject.map((object) => object.toJson()).toList()}");
      if(listOfObject.isEmpty){
        return Container();
      }
    }

    return InkWell(
      onTap: (){
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(currentParameterValue);
          if(currentParameterValue.isNotEmpty){
            widget.configPvd.selectedSno = currentParameterValue[0];
          }
        });
        selectionDialogBox(
            context: context,
            title: 'Select $objectName',
            singleSelection: singleSelection,
            listOfObject: listOfObject ??
                getUnselectedLineParameterObject(
                  currentParameterList: currentParameterValue,
                  objectId: objectId,
                  parameter: parameterType,
                  validateAllLine: validateAllLine,
                ),
            onPressed: (){
              setState(() {
                widget.configPvd.updateSelectionInLine(line.commonDetails.sNo!, parameterType);
              });
              Navigator.pop(context);
            }
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.onSurface,
        ),
        child: Row(
          spacing: 10,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg', color: themeMode ? Colors.black : Colors.white,),
            Text(objectName, style: AppProperties.listTileBlackBoldStyle,),
          ],
        ),
      ),
    );
  }

  List<DeviceObjectModel> getUnselectedLineParameterObject({
    required List<double> currentParameterList,
    required int objectId,
    required LineParameter parameter,
    required bool validateAllLine
  }){
    List<DeviceObjectModel> listOfObject = widget.configPvd.listOfGeneratedObject
        .where((object) => object.objectId == objectId)
        .toList();
    List<double> assigned = [];
    if(validateAllLine){
      for(var line in widget.configPvd.line){
        List<double> lineParameter = parameter == LineParameter.sourcePump
            ? line.sourcePump
            : parameter == LineParameter.irrigationPump
            ? line.irrigationPump
            : parameter == LineParameter.valve
            ? line.valve
            : parameter == LineParameter.flowControlValve
            ? line.flowControlValve
            : parameter == LineParameter.mainValve
            ? line.mainValve
            : parameter == LineParameter.fan
            ? line.fan
            : parameter == LineParameter.fogger
            ? line.fogger
            : parameter == LineParameter.pesticides
            ? line.pesticides
            : parameter == LineParameter.heater
            ? line.heater
            : parameter == LineParameter.screen
            ? line.screen
            : parameter == LineParameter.vent
            ? line.vent
            : parameter == LineParameter.moisture
            ? line.moisture
            : parameter == LineParameter.temperature
            ? line.temperature
            : parameter == LineParameter.soilTemperature
            ? line.soilTemperature
            : parameter == LineParameter.humidity
            ? line.humidity
            : parameter == LineParameter.waterMeter
            ? [line.waterMeter]
            : parameter == LineParameter.analogWaterMeter
            ? [line.analogWaterMeter]
            : parameter == LineParameter.powerSupply
            ? [line.powerSupply]
            : parameter == LineParameter.pressureSwitch
            ? [line.pressureSwitch]
            : parameter == LineParameter.pressureIn
            ? [line.pressureIn]
            : parameter == LineParameter.pressureOut
            ? [line.pressureOut]
            : line.co2;
        assigned.addAll(lineParameter);
      }
    }

    listOfObject = listOfObject
        .where((object) => (!assigned.contains(object.sNo!) || currentParameterList.contains(object.sNo))).toList();
    return listOfObject;
  }

  //Todo :: getSuitableSourceConnection
  Widget getSuitableSourceConnection(IrrigationLineModel selectedIrrigationLine){
    List<FiltrationModel> filterSite = [];
    for(var site in widget.configPvd.filtration){
      if(site.commonDetails.sNo == selectedIrrigationLine.centralFiltration){
        filterSite.add(site);
      }if(site.commonDetails.sNo == selectedIrrigationLine.localFiltration){
        filterSite.add(site);
      }
    }
    List<FertilizationModel> fertilizerSite = [];
    for(var site in widget.configPvd.fertilization){
      if(site.commonDetails.sNo == selectedIrrigationLine.centralFertilization){
        fertilizerSite.add(site);
      }if(site.commonDetails.sNo == selectedIrrigationLine.localFertilization){
        fertilizerSite.add(site);
      }
    }
    List<SourceModel> suitableSource = widget.configPvd.source
        .where(
            (source){
          print("source.sourceType :: ${source.sourceType}");
          bool sourcePumpAvailability = selectedIrrigationLine.sourcePump.any((pump) => (source.outletPump.contains(pump) || source.inletPump.contains(pump)));
          bool irrigationPumpAvailability = selectedIrrigationLine.irrigationPump.any((pump) => (source.outletPump.contains(pump) || source.inletPump.contains(pump)));
          return ((sourcePumpAvailability || irrigationPumpAvailability));
        }
    )
        .map((source) => source.copy())
        .toList();

    print("Suitable source :: ${widget.configPvd.source.map((e) => e.toJson()).toList()}");

    for(var src in suitableSource){
      src.inletPump = src.inletPump.where((pumpSno) => selectedIrrigationLine.sourcePump.contains(pumpSno) || selectedIrrigationLine.irrigationPump.contains(pumpSno)).toList();
      src.outletPump = src.outletPump.where((pumpSno) => selectedIrrigationLine.sourcePump.contains(pumpSno) || selectedIrrigationLine.irrigationPump.contains(pumpSno)).toList();
      print('source name : ${src.commonDetails.name}  ${src.sourceType}');
    }

    List<SourceModel> boreOrOthers = suitableSource.where((source) => source.outletPump.any((pumpSno) => widget.configPvd.pump.cast<PumpModel>().firstWhere((pump) => pump.commonDetails.sNo == pumpSno).pumpType == 1)).toList();
    List<SourceModel> wellSumpTank = suitableSource.where((source) => source.outletPump.any((pumpSno) => widget.configPvd.pump.cast<PumpModel>().firstWhere((pump) => pump.commonDetails.sNo == pumpSno).pumpType == 2)).toList();
    print('boreOrOthers: ${boreOrOthers.length}');
    print('wellSumpTank: ${wellSumpTank.length}');

    if(boreOrOthers.length == 1 && wellSumpTank.isEmpty){
      return oneSource(suitableSource, selectedIrrigationLine, filterSite: filterSite, fertilizerSite: fertilizerSite);
    }else if(boreOrOthers.isEmpty && wellSumpTank.length == 1){
      return oneTank(suitableSource[0],selectedIrrigationLine, inlet: false , filterSite: filterSite, fertilizerSite: fertilizerSite);
    }else if(boreOrOthers.length == 1 && wellSumpTank.length == 1){
      return oneSourceAndOneTank(boreOthers: boreOrOthers[0],sumpTankWell: wellSumpTank[0], selectedIrrigationLine: selectedIrrigationLine, filterSite: filterSite, fertilizerSite: fertilizerSite);
    }else{
      return multipleSourceAndMultipleTank(multipleSource: boreOrOthers, multipleTank: wellSumpTank, selectedIrrigationLine: selectedIrrigationLine);
    }
  }

  Widget oneSource(List<SourceModel> suitableSource, IrrigationLineModel selectedIrrigationLine,
      {
        required List<FiltrationModel> filterSite,
        required List<FertilizationModel> fertilizerSite
      }){
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...oneSourceList(suitableSource[0]),
        ...filtrationAndFertilization(maxLength: 1, fertilizerSite: fertilizerSite, filterSite: filterSite)
      ],
    );
  }

  // Todo :: oneTank
  Widget oneTank(SourceModel source, IrrigationLineModel selectedIrrigationLine, {bool inlet = true, int? maxOutletPumpForTank, required List<FiltrationModel> filterSite, required List<FertilizationModel> fertilizerSite}){
    print('oneTank maxOutletPumpForTank : $maxOutletPumpForTank');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...oneTankList(source, inlet: inlet, maxOutletPumpForTank: maxOutletPumpForTank),
        if(fertilizerSite.isNotEmpty || filterSite.isNotEmpty)
          ...filtrationAndFertilization(maxLength: 1, filterSite: filterSite, fertilizerSite: fertilizerSite)
      ],
    );
  }

  Widget oneSourceAndOneTank({required SourceModel boreOthers, required SourceModel sumpTankWell, required IrrigationLineModel selectedIrrigationLine, required List<FiltrationModel> filterSite, required List<FertilizationModel> fertilizerSite}){
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...oneSourceList(boreOthers),
      ...oneTankList(sumpTankWell),
      ...filtrationAndFertilization(maxLength: 1, filterSite: filterSite, fertilizerSite: fertilizerSite)
    ],
  );
  }

  Widget multipleSourceAndMultipleTank({
    required List<SourceModel> multipleSource,
    required List<SourceModel> multipleTank,
    required IrrigationLineModel selectedIrrigationLine
  }){
    print("${selectedIrrigationLine.commonDetails.name} == multipleSourceAndMultipleTank");
    List<FiltrationModel> filterSite = [];
    for(var site in widget.configPvd.filtration){
      if(site.commonDetails.sNo == selectedIrrigationLine.centralFiltration){
        filterSite.add(site);
      }if(site.commonDetails.sNo == selectedIrrigationLine.localFiltration){
        filterSite.add(site);
      }
    }
    List<FertilizationModel> fertilizerSite = [];
    for(var site in widget.configPvd.fertilization){
      if(site.commonDetails.sNo == selectedIrrigationLine.centralFertilization){
        fertilizerSite.add(site);
      }if(site.commonDetails.sNo == selectedIrrigationLine.localFertilization){
        fertilizerSite.add(site);
      }
    }
    print('filterSite : $filterSite');
    print('fertilizerSite : $fertilizerSite');
    print('multipleTank : $multipleTank');
    int maxLength = multipleSource.length > multipleTank.length ? multipleSource.length : multipleTank.length;
    int maxOutletPumpForTank = 0;
    int maxOutletPumpForSource = 0;
    for(var tank in multipleTank){
      maxOutletPumpForTank = maxOutletPumpForTank < tank.outletPump.length ? tank.outletPump.length : maxOutletPumpForTank;
    }
    for(var tank in multipleSource){
      maxOutletPumpForSource = maxOutletPumpForSource < tank.outletPump.length ? tank.outletPump.length : maxOutletPumpForSource;
    }
    print('multipleSourceAndMultipleTank maxOutletPumpForTank : $maxOutletPumpForTank');
    print('multipleSourceAndMultipleTank maxOutletPumpForSource : $maxOutletPumpForSource');
    return LayoutBuilder(builder: (context, constraint){
      if(maxOutletPumpForTank == 0 && maxOutletPumpForSource == 0){
        return Container();
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for(var src in multipleSource)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  // padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      ...oneSourceList(src, maxOutletPumpForTank: maxOutletPumpForTank, maxOutletPumpForSource: maxOutletPumpForSource)
                    ],
                  ),
                )
            ],
          ),
          if(maxOutletPumpForTank != 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for(var srcOrTank = 0;srcOrTank < maxLength;srcOrTank++)
                  SizedBox(
                    width: 8 * widget.configPvd.ratio,
                    height: 160 * widget.configPvd.ratio,
                    child: Stack(
                      children: [
                        if(srcOrTank == 0)
                          Positioned(
                              left: 0,
                              bottom: 0,
                              child: Container(
                                width: 8,
                                height: 80  * widget.configPvd.ratio,
                                decoration: const BoxDecoration(
                                    gradient: RadialGradient(
                                        radius: 2,
                                        colors: [
                                          Color(0xffC0E3EE),
                                          Color(0xff67B1C1),
                                        ]
                                    )
                                ),
                              )
                          ),
                        if(maxLength - 1 == srcOrTank)
                          Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 68,
                                decoration: const BoxDecoration(
                                    gradient: RadialGradient(
                                        radius: 3,
                                        colors: [
                                          Color(0xffC0E3EE),
                                          Color(0xff67B1C1),
                                        ]
                                    )
                                ),
                              )
                          ),
                        if(maxLength > 2 && ![0, maxLength - 1].contains(srcOrTank))
                          Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 160,
                                decoration: const BoxDecoration(
                                    gradient: RadialGradient(
                                        radius: 3,
                                        colors: [
                                          Color(0xffC0E3EE),
                                          Color(0xff67B1C1),
                                        ]
                                    )
                                ),
                              )
                          ),
                      ],
                    ),
                  )
              ],
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for(var tank = 0;tank < multipleTank.length;tank++)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  // padding: const EdgeInsets.symmetric(vertical: 20),
                  child: oneTank(multipleTank[tank], selectedIrrigationLine, maxOutletPumpForTank: maxOutletPumpForTank, fertilizerSite: [], filterSite: []),
                ),
            ],
          ),
          ...filtrationAndFertilization(maxLength: maxLength, fertilizerSite: fertilizerSite, filterSite: filterSite),
        ],
      );
    });
  }

  List<Widget> filtrationAndFertilization({
    required List<FertilizationModel> fertilizerSite,
    required List<FiltrationModel> filterSite,
    required int maxLength
  }){
    double connectionPipeHeight = maxLength * 160;
    double connectingHeight = filterSite.isEmpty ? 198 : 400;
    return [
      if(fertilizerSite.isNotEmpty)
        SizedBox(
          width: 50,
          height: (connectionPipeHeight > connectingHeight ? connectionPipeHeight : connectingHeight) * widget.configPvd.ratio,
          child: Stack(
            children: [
              Positioned(
                top: 80 * widget.configPvd.ratio,
                child: Container(
                  width: 8 * widget.configPvd.ratio,
                  height: (maxLength == 1 ? 200 : (connectionPipeHeight - 123)) * widget.configPvd.ratio,
                  decoration: const BoxDecoration(
                      gradient: RadialGradient(
                          radius: 2,
                          colors: [
                            Color(0xffC0E3EE),
                            Color(0xff67B1C1),
                          ]
                      )
                  ),
                ),
              ),
              Positioned(
                top: 190 * widget.configPvd.ratio,
                child: Container(
                  width: 50,
                  height: 8  * widget.configPvd.ratio,
                  decoration: const BoxDecoration(
                      gradient: RadialGradient(
                          radius: 2,
                          colors: [
                            Color(0xffC0E3EE),
                            Color(0xff67B1C1),
                          ]
                      )
                  ),
                ),
              ),
              if(filterSite.isNotEmpty)
                Positioned(
                  top: 277  * widget.configPvd.ratio,
                  child: Container(
                    width: 50,
                    height: 8 * widget.configPvd.ratio,
                    decoration: const BoxDecoration(
                        gradient: RadialGradient(
                            radius: 2,
                            colors: [
                              Color(0xffC0E3EE),
                              Color(0xff67B1C1),
                            ]
                        )
                    ),
                  ),
                ),
            ],
          ),
        ),
      Stack(
        children: [
          if(fertilizerSite.isNotEmpty && filterSite.isNotEmpty)
            Positioned(
              right: 0,
              top: 98 * widget.configPvd.ratio,
              child: Container(
                width: (filterSite[0].filters.length * 150 - 50) * widget.configPvd.ratio,
                height: 7 * widget.configPvd.ratio,
                decoration: const BoxDecoration(
                    gradient: RadialGradient(
                        radius: 2,
                        colors: [
                          Color(0xffC0E3EE),
                          Color(0xff67B1C1),
                        ]
                    )
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if(fertilizerSite.isNotEmpty)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if(fertilizerSite[0].channel.length == 1)
                      FertilizationDashboardFormation(fertilizationFormation: FertilizationFormation.singleChannel, fertilizationSite: fertilizerSite[0]),
                    if(fertilizerSite[0].channel.length > 1)
                      FertilizationDashboardFormation(fertilizationFormation: FertilizationFormation.multipleChannel, fertilizationSite: fertilizerSite[0]),
                  ],
                ),
              if(filterSite.isNotEmpty)
                ...[
                  SizedBox(height: 80 * widget.configPvd.ratio,),
                  Row(
                    children: [
                      if(filterSite[0].filters.length == 1)
                        FiltrationDashboardFormation(filtrationFormation: FiltrationFormation.singleFilter, filtrationSite: filterSite[0]),
                      if(filterSite[0].filters.length > 1)
                        FiltrationDashboardFormation(filtrationFormation: FiltrationFormation.multipleFilter, filtrationSite: filterSite[0]),
                    ],
                  ),
                ]
            ],
          ),
          if(fertilizerSite.isNotEmpty && filterSite.isNotEmpty)
            Positioned(
              right: 0,
              bottom: 8 * widget.configPvd.ratio,
              child: Container(
                width: 8 * widget.configPvd.ratio ,
                height: 320 * widget.configPvd.ratio,
                decoration: const BoxDecoration(
                    gradient: RadialGradient(
                        radius: 2,
                        colors: [
                          Color(0xffC0E3EE),
                          Color(0xff67B1C1),
                        ]
                    )
                ),
              ),
            ),
        ],
      ),
      if(fertilizerSite.length > 1 || filterSite.length > 1)
        Column(
          children: [
            if(fertilizerSite.length > 1)
              Container(
                margin: const EdgeInsets.only(left: 30),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.circular(10)
                ),
                child: FertilizationDashboardFormation(fertilizationFormation: fertilizerSite[1].channel.length == 1 ? FertilizationFormation.singleChannel : FertilizationFormation.multipleChannel, fertilizationSite: fertilizerSite[1]),
              ),
            const SizedBox(height: 20,),
            if(filterSite.length > 1)
              Container(
                margin: const EdgeInsets.only(left: 30),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.circular(10)
                ),
                child: FiltrationDashboardFormation(filtrationFormation: filterSite[1].filters.length == 1 ? FiltrationFormation.singleFilter : FiltrationFormation.multipleFilter, filtrationSite: filterSite[1]) ,
              ),
          ],
        ),
    ];
  }

  // Todo :: oneSourceList
  List<Widget> oneSourceList(SourceModel source,{ int? maxOutletPumpForTank, int? maxOutletPumpForSource} ){
    print("oneSourceList maxOutletPumpForTank : $maxOutletPumpForTank");
    pumpExtendedWidth += (120 * 2);
    return [
      getSource(source,widget.configPvd , inlet: false, dashboard: true),
      if(source.outletPump.length == 1)
        Row(
          children: [
            singlePump(source, false, widget.configPvd, dashboard: true),
            if(maxOutletPumpForSource != null)
              for(var i = 0;i < (maxOutletPumpForSource - source.outletPump.length);i++)
                SizedBox(
                  width: 94,
                  height: 120 * widget.configPvd.ratio,
                  child: Stack(
                    children: [
                      Positioned(
                        bottom : 32 * widget.configPvd.ratio,
                        child: SvgPicture.asset(
                          'assets/Images/Source/backside_pipe_1.svg',
                          width: 120,
                          height: 8.5 * widget.configPvd.ratio,
                        ),
                      )
                    ],
                  ),
                )
          ],
        )
      else
        multiplePump(source, false, widget.configPvd, dashBoard: true, maxOutletPumpForTank: maxOutletPumpForTank)
    ];
  }

  List<Widget> oneTankList(SourceModel source, {bool inlet = true, int? maxOutletPumpForTank}){
    pumpExtendedWidth += 120 + (source.outletPump.length * 120);
    return [
      getSource(source, widget.configPvd, inlet: inlet),
      multiplePump(source, false, widget.configPvd, dashBoard: true, maxOutletPumpForTank: maxOutletPumpForTank),
    ];
  }

  Widget lJointPipeConnectionForPumps(){
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(-1.0, 1.0),
      child: SvgPicture.asset(
        'assets/Images/Source/pump_joint_1.svg',
        width: 120,
        height: 154,
      ),
    );
  }

  Widget getSource(SourceModel source,ConfigMakerProvider configPvd, {bool dashboard = false, bool inlet = true}){
    return Stack(
      children: [
        getTankImage(source, configPvd, dashboard: dashboard, inlet: inlet),
        Positioned(
          left : 5,
          top: 0,
          child: Text(getObjectName(source.commonDetails.sNo!, widget.configPvd).name!,style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),),
        ),
      ],
    );
  }

}