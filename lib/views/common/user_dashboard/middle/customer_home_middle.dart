import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/utils/helpers/mc_permission_helper.dart';
import 'package:provider/provider.dart';

import '../../../../models/customer/site_model.dart';
import '../../../../providers/user_provider.dart';
import '../../../../utils/constants.dart';
import '../../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../../../customer/home_sub_classes/current_program.dart';
import '../../../customer/home_sub_classes/next_schedule.dart';
import '../../../customer/scheduled_program/scheduled_program_wide.dart';
import '../../../customer/widgets/my_material_button.dart';
import '../widgets/aquaculture_line.dart';
import '../widgets/irrigation_line_wide.dart';
import '../widgets/valve_status_legend.dart';

class CustomerHomeMiddle extends StatelessWidget {
  const CustomerHomeMiddle({super.key});

  @override
  Widget build(BuildContext context) {

    final userData = context.read<UserProvider>().loggedInUser;
    final viewModel = Provider.of<CustomerScreenControllerViewModel>(context);
    int customerId = viewModel.mySiteList.data[viewModel.sIndex].customerId;
    final cM = viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex];

    bool isNova = [...AppConstants.ecoGemModelList].contains(cM.modelId);
    bool isAquaculture = [...AppConstants.aquacultureModelList].contains(
        cM.modelId);

    final irrigationLines = viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex].irrigationLine;
    final scheduledProgram = viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex].programList;

    final linesToDisplay = (viewModel.myCurrentIrrLine == "All irrigation line" ||
        viewModel.myCurrentIrrLine == "All Aquaculture line" || viewModel.myCurrentIrrLine.isEmpty)
        ? irrigationLines.where((line) => line.name != viewModel.myCurrentIrrLine).toList()
        : irrigationLines.where((line) => line.name == viewModel.myCurrentIrrLine).toList();

    return _buildWebLayout(context, userData.id, customerId, cM.controllerId, cM.modelId, cM.deviceId,
        linesToDisplay, scheduledProgram, viewModel, isNova, isAquaculture);
  }

  Widget displayLinearProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 3, right: 3),
      child: LinearProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        backgroundColor: Colors.grey[200],
        minHeight: 4,
        borderRadius: BorderRadius.circular(5.0),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context, int userId, int customerId, int controllerId, int modelId,
      String deviceId, List<IrrigationLineModel> irrigationLine,
      scheduledProgram, CustomerScreenControllerViewModel viewModel, bool isNova, bool isAquaculture) {

    return Consumer<CustomerScreenControllerViewModel>(
      builder: (context, viewModel, _) {

        final cM = viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex];
        final scheduledProgram = cM.programList;

        final hasProgramOnOff = cM.getPermissionStatus("Program On/Off Manually");
        final hasLinePP = cM.getPermissionStatus("Irrigation Line Pause/Resume Manually");

        return Column(
          children: [
            buildValveStatusLegend(isAquaculture),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [

                    ...irrigationLine.map((line) => Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8, top:8, bottom: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 0.5,
                          ),
                          borderRadius: const BorderRadius.all(Radius.circular(5)),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width,
                              height: 40,
                              child: Card(
                                color: Colors.white,
                                elevation: 0.6,
                                surfaceTintColor: Colors.white,
                                margin: EdgeInsets.zero,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 16),
                                    Text(
                                      line.name.toUpperCase(),
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),

                                    if(!isNova)...[
                                      if(hasLinePP)...[
                                        const Spacer(),
                                        SizedBox(
                                          height: 27,
                                          child: MyMaterialButton(
                                            buttonId: 'line_${line.sNo}_4900',
                                            label: line.linePauseFlag == 0 ? 'Pause the line' : 'Resume the line',
                                            payloadKey: "4900",
                                            payloadValue: "${line.sNo},${line.linePauseFlag == 0 ? 1 : 0}",
                                            color: line.linePauseFlag == 0 ? Colors.orangeAccent : Colors.green,
                                            textColor: Colors.white,
                                            serverMsg: line.linePauseFlag == 0 ? 'Paused the ${line.name}'
                                                : 'Resumed the ${line.name}',
                                          ),
                                        ),
                                        const SizedBox(width: 10)
                                      ]
                                    ]
                                  ],
                                ),
                              ),
                            ),
                            isAquaculture ? AquacultureLine(irrLine: line, customerId: customerId,
                                controllerId: controllerId, modelId: modelId, deviceId: deviceId) :
                            buildIrrigationLine(context, line, customerId, controllerId, modelId, deviceId),
                          ],
                        ),
                      ),
                    )),

                    CurrentProgram(
                      scheduledPrograms: scheduledProgram,
                      deviceId: viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex].deviceId,
                      customerId: customerId,
                      controllerId: controllerId,
                      currentLineSNo: viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex].
                      irrigationLine[viewModel.lIndex].sNo,
                      modelId: viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex].modelId,
                      skipPermission: hasProgramOnOff,
                    ),

                    if (scheduledProgram.isNotEmpty)
                      NextSchedule(scheduledPrograms: scheduledProgram),

                    if (scheduledProgram.isNotEmpty)
                      ScheduledProgramWide(
                        userId: userId,
                        scheduledPrograms: scheduledProgram,
                        controllerId: viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex].controllerId,
                        deviceId: viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex].deviceId,
                        customerId: customerId,
                        currentLineSNo: viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex].irrigationLine[viewModel.lIndex].sNo,
                        groupId: viewModel.mySiteList.data[viewModel.sIndex].groupId,
                        categoryId: viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex].categoryId,
                        modelId: viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex].modelId,
                        deviceName: viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex].deviceName,
                        categoryName: viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex].categoryName,
                        prgOnOffPermission: hasProgramOnOff,
                      ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildIrrigationLine(BuildContext context, IrrigationLineModel irrLine,
      int customerId, int controllerId, int modelId, String deviceId){

    final inletWaterSources = {
      for (var source in irrLine.inletSources) source.sNo: source
    }.values.toList();

    final outletWaterSources = {
      for (var source in irrLine.outletSources) source.sNo: source
    }.values.toList();

    final cFilterSite = {
      if (irrLine.centralFilterSite != null) irrLine.centralFilterSite!.sNo : irrLine.centralFilterSite!
    }.values.toList();

    final cFertilizerSite = {
      if (irrLine.centralFertilizerSite != null) irrLine.centralFertilizerSite!.sNo : irrLine.centralFertilizerSite!
    }.values.toList();

    final lFilterSite = {
      if (irrLine.localFilterSite != null) irrLine.localFilterSite!.sNo : irrLine.localFilterSite!
    }.values.toList();

    final lFertilizerSite = {
      if (irrLine.localFertilizerSite != null) irrLine.localFertilizerSite!.sNo : irrLine.localFertilizerSite!
    }.values.toList();

    return IrrigationLineWide(
      inletWaterSources: inletWaterSources,
      outletWaterSources: outletWaterSources,
      cFilterSite: cFilterSite,
      cFertilizerSite: cFertilizerSite,
      lFilterSite: lFilterSite,
      lFertilizerSite: lFertilizerSite,
      valves: irrLine.valveObjects,
      mainValves: irrLine.mainValveObjects,
      lights:irrLine.lightObjects,
      fans:irrLine.fanObjects,
      gates:irrLine.gateObjects,
      fogger: irrLine.foggerObjects,
      prsSwitch: irrLine.prsSwitch,
      pressureIn: irrLine.pressureIn,
      pressureOut: irrLine.pressureOut,
      waterMeter: irrLine.waterMeter,
      humidity: irrLine.humiditySensor,
      co2: irrLine.co2Sensor,
      temperature: irrLine.temperature,
      soilTemperature: irrLine.soilTemperature,
      customerId: customerId,
      controllerId: controllerId,
      containerWidth: MediaQuery.sizeOf(context).width,
      deviceId: deviceId,
      modelId: modelId,
      isNava: false,
    );
  }

}