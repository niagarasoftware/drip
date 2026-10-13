import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/views/customer/stand_alone/widgets/fertilizer_site_card.dart';
import 'package:oro_drip_irrigation/views/customer/stand_alone/widgets/filter_site_card.dart';
import 'package:oro_drip_irrigation/views/customer/stand_alone/widgets/irrigation_line_card.dart';
import 'package:oro_drip_irrigation/views/customer/stand_alone/widgets/irrigation_pump_card.dart';
import 'package:oro_drip_irrigation/views/customer/stand_alone/widgets/main_valve_card.dart';
import 'package:oro_drip_irrigation/views/customer/stand_alone/widgets/source_pump_card.dart';
import 'package:oro_drip_irrigation/views/customer/stand_alone/widgets/valve_card_table.dart';
import 'package:provider/provider.dart';

import '../../../models/customer/site_model.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../utils/constants.dart';
import '../../../view_models/customer/stand_alone_view_model.dart';

class StandAloneNarrow extends StatefulWidget {
  const StandAloneNarrow({super.key, required this.customerId, required this.siteId, required this.controllerId, required this.userId, required this.deviceId, required this.callbackFunction, required this.masterData});

  final int customerId, siteId, controllerId, userId;
  final String deviceId;
  final void Function(String msg) callbackFunction;
  final MasterControllerModel masterData;

  @override
  State<StandAloneNarrow> createState() => _StandAloneNarrowState();
}

class _StandAloneNarrowState extends State<StandAloneNarrow> with SingleTickerProviderStateMixin {

  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StandAloneViewModel(Repository(HttpService()),
          widget.masterData, widget.userId, widget.customerId, widget.controllerId, widget.deviceId)
        ..getProgramList(),
      child: Consumer<StandAloneViewModel>(
        builder: (context, viewModel, _) {

          final bool isNova = [...AppConstants.ecoGemModelList].contains(widget.masterData.modelId);

          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: const Text('Manual'),
              actions : !isNova ? [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Row(
                    children: [
                      const Text('Select by :', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 175,
                        child: DropdownButtonFormField(
                          dropdownColor: Theme.of(context).primaryColorLight,
                          value: viewModel.programList.isNotEmpty ?
                          viewModel.programList[viewModel.ddCurrentPosition] : null,
                          items: viewModel.programList.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(
                                item.programName,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            viewModel.fetchStandAloneSelection(
                              value!.serialNumber,
                              viewModel.programList.indexOf(value),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ] : null,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: isNova? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Row(
                      children: [
                        const Text('Select by : ', style: TextStyle(color: Colors.white, fontSize: 17)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField(
                            dropdownColor: Theme.of(context).primaryColorLight,
                            iconEnabledColor: Colors.white,
                            iconDisabledColor: Colors.white,
                            value: viewModel.programList.isNotEmpty
                                ? viewModel.programList[viewModel.ddCurrentPosition]
                                : null,
                            items: viewModel.programList.map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(
                                  item.programName,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              viewModel.fetchStandAloneSelection(
                                value!.serialNumber,
                                viewModel.programList.indexOf(value),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ) :
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<SegmentWithFlow>(
                          style: ButtonStyle(
                            backgroundColor:
                            WidgetStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).primaryColorLight;
                              }
                              return Colors.white;
                            }),
                            foregroundColor:
                            WidgetStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.white;
                              }
                              return Colors.black;
                            }),
                            overlayColor: WidgetStateProperty.all(
                              Theme.of(context).primaryColorLight.withOpacity(0.1),
                            ),
                            surfaceTintColor: WidgetStateProperty.all(Colors.white),
                            side: WidgetStateProperty.all(
                              BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          segments: viewModel.ddCurrentPosition == 0
                              ? const <ButtonSegment<SegmentWithFlow>>[
                            ButtonSegment<SegmentWithFlow>(
                                value: SegmentWithFlow.manual,
                                label: Text('Timeless'),
                                icon: Icon(Icons.pan_tool_alt_outlined)),
                            ButtonSegment<SegmentWithFlow>(
                                value: SegmentWithFlow.duration,
                                label: Text('Duration'),
                                icon: Icon(Icons.timer_outlined)),
                          ]
                              : const <ButtonSegment<SegmentWithFlow>>[
                            ButtonSegment<SegmentWithFlow>(
                                value: SegmentWithFlow.manual,
                                label: Text('Timeless'),
                                icon: Icon(Icons.pan_tool_alt_outlined)),
                            ButtonSegment<SegmentWithFlow>(
                                value: SegmentWithFlow.duration,
                                label: Text('Duration'),
                                icon: Icon(Icons.timer_outlined)),
                            ButtonSegment<SegmentWithFlow>(
                                value: SegmentWithFlow.flow,
                                label: Text('Liters'),
                                icon: Icon(Icons.water_drop_outlined)),
                          ],
                          selected: <SegmentWithFlow>{viewModel.segmentWithFlow},
                          onSelectionChanged: (Set<SegmentWithFlow> newSelection) {
                            viewModel.segmentWithFlow = newSelection.first;
                            viewModel.segmentSelectionCallbackFunction(
                              viewModel.segmentWithFlow.index,
                              viewModel.durationValue,
                              viewModel.selectedIrLine,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (viewModel.segmentWithFlow.index == 1)
                        SizedBox(
                          width: 100,
                          child: TextButton(
                            onPressed: () =>
                                viewModel.showDurationInputDialog(context),
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                              ),
                              backgroundColor:
                              WidgetStateProperty.all<Color>(Colors.white),
                              shape: WidgetStateProperty.all<OutlinedBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2)),
                              ),
                            ),
                            child: Text(
                              viewModel.durationValue,
                              style: const TextStyle(color: Colors.black, fontSize: 17),
                            ),
                          ),
                        ),
                      if (viewModel.segmentWithFlow.index == 2)
                        Container(
                          width: 90,
                          height: 40,
                          color: Colors.white,
                          child: TextField(
                            maxLength: 7,
                            controller: viewModel.flowLiter,
                            onChanged: (value) =>
                                viewModel.segmentSelectionCallbackFunction(
                                  viewModel.segmentWithFlow.index,
                                  value,
                                  viewModel.selectedIrLine,
                                ),
                            keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.black),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                            ],
                            decoration: const InputDecoration(
                              hintText: 'Liters',
                              counterText: '',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: displayLineOrSequence(
                        widget.masterData,
                        viewModel,
                        viewModel.ddCurrentPosition,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MaterialButton(
                            color: Colors.redAccent,
                            textColor: Colors.white,
                            onPressed: () =>
                                viewModel.stopAllManualOperation(context),
                            child: const Text('Stop Manually'),
                          ),
                          const SizedBox(width: 8),
                          MaterialButton(
                            color: Colors.green,
                            textColor: Colors.white,
                            onPressed: () =>
                                viewModel.startManualOperation(context),
                            child: const Text('Start Manually'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget displayLineOrSequence(MasterControllerModel masterData, StandAloneViewModel vm, int ddPosition){

    bool isNova = [...AppConstants.ecoGemModelList].contains(masterData.modelId);

    final sourcePumps = masterData.irrigationLine
        .expand((line) => line.inletSources)
        .expand((ws) => ws.outletPump)
        .toList();

    final allSourcePumps = sourcePumps.fold<Map<double, PumpModel>>({}, (map, pump) {
      map[pump.sNo] = pump;
      return map;
    }).values.toList();

    final irrigationPumps = masterData.irrigationLine
        .expand((line) => line.outletSources)
        .expand((ws) => ws.outletPump)
        .toList();

    final allIrrigationPumps = irrigationPumps.fold<Map<double, PumpModel>>({}, (map, pump) {
      map[pump.sNo] = pump;
      return map;
    }).values.toList();

    final cFilterSites = masterData.irrigationLine
        .map((line) => line.centralFilterSite)
        .whereType<FilterSiteModel>()
        .toList();

    final cFertilizerSite = masterData.irrigationLine
        .map((line) => line.centralFertilizerSite)
        .whereType<FertilizerSiteModel>()
        .toList();

    final lFilterSites = masterData.irrigationLine
        .map((line) => line.localFilterSite)
        .whereType<FilterSiteModel>()
        .toList();

    final lFertilizerSite = masterData.irrigationLine
        .map((line) => line.localFertilizerSite)
        .whereType<FertilizerSiteModel>()
        .toList();

    final mainValve = masterData.irrigationLine
        .expand((line) => line.mainValveObjects)
        .toList();

    final allMainValve = mainValve.fold<Map<double, MainValveModel>>({}, (map, mValve) {
      map[mValve.sNo] = mValve;
      return map;
    }).values.toList();

    return Column(
      children: [
        if (!isNova && vm.ddCurrentPosition == 0)
          SourcePumpCard(
            pumps: allSourcePumps,
            onChanged: (pump, val) => setState(() => pump.selected = val),
          ),
        IrrigationPumpCard(
          pumps: allIrrigationPumps,
          onChanged: (pump, val) => setState(() => pump.selected = val),
        ),

        FilterSiteCard(
          sites: cFilterSites,
          onChanged: (filter, val) => setState(() => filter.selected = val),
        ),
        FilterSiteCard(
          sites: lFilterSites,
          onChanged: (filter, val) => setState(() => filter.selected = val),
        ),
        FertilizerSiteCard(
          sites: cFertilizerSite,
          onChanged: (item, val) => setState(() => item.selected = val),
        ),
        FertilizerSiteCard(
          sites: lFertilizerSite,
          onChanged: (item, val) => setState(() => item.selected = val),
        ),

        MainValveCard(
          mainValve: allMainValve,
          onChanged: (item, val) => setState(() => item.selected = val),
        ),

        (!isNova && ddPosition == 0) ? Column(
          children: masterData.irrigationLine.map((line) {
            return IrrigationLineCard(
              line: line,
              showSwitch: vm.ddCurrentPosition != 0,
              onToggleValve: (valve, value) {
                setState(() => valve.isOn = value);
              },
              onToggleFogger: (FoggerModel fogger, bool value) {
                setState(() => fogger.isOn = value);
              },
            );
          }).toList(),
        ) : vm.standAloneData != null ? Column(
          children: vm.standAloneData!.sequence.map((sequence) {
            final rows = sequence.valve.map((valve) {
              return DataRow(cells: [
                DataCell(Image.asset('assets/png/m_valve_grey.png', width: 40, height: 40)),
                DataCell(Text(valve.name)),
                const DataCell(SizedBox()),
              ]);
            }).toList();

            return ValveCardTable(
              title: sequence.name,
              showSwitch: !isNova ? vm.ddCurrentPosition != 0 : true,
              switchValue: sequence.selected,
              onSwitchChanged: (value) {
                setState(() {
                  for (var seq in vm.standAloneData!.sequence) {
                    seq.selected = false;
                  }
                  sequence.selected = value;
                });
              },
              rows: rows,
            );
          }).toList(),
        ) : const SizedBox(),
      ],
    );
  }
}