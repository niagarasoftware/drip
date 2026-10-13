import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/view_models/customer/stand_alone_view_model.dart';
import 'package:oro_drip_irrigation/views/customer/stand_alone/widgets/fert_main_source_card.dart';
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

class StandAloneWide extends StatefulWidget {
  const StandAloneWide({super.key, required this.customerId, required this.siteId, required this.controllerId, required this.userId, required this.deviceId, required this.callbackFunction, required this.masterData});

  final int customerId, siteId, controllerId, userId;
  final String deviceId;
  final void Function(String msg) callbackFunction;
  final MasterControllerModel masterData;

  @override
  State<StandAloneWide> createState() => _StandAloneWideState();
}

class _StandAloneWideState extends State<StandAloneWide> with SingleTickerProviderStateMixin {

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
            return Container(
              width: 400,
              height: MediaQuery.sizeOf(context).height,
              color: Colors.white,
              child: Column(
                children: [
                  SizedBox(
                    width: 400,
                    height: ([...AppConstants.ecoGemModelList].contains(widget.masterData.modelId)) ? 50 :
                    viewModel.ddCurrentPosition != 0 && viewModel.segmentWithFlow.index!=0 ? 133 : viewModel.programList.length > 1? 90:60,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          viewModel.programList.length > 1 ? Row(
                            children: [
                              const Text(
                                'Select by:',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 200,
                                child: DropdownButtonFormField(
                                  value: viewModel.programList.isNotEmpty
                                      ? viewModel.programList[viewModel.ddCurrentPosition]
                                      : null,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                  ),
                                  items: viewModel.programList.map((item) {
                                    return DropdownMenuItem(
                                      value: item,
                                      child: Text(item.programName),
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
                          ) :
                          const SizedBox(height: 8),

                          if(![...AppConstants.ecoGemModelList].contains(widget.masterData.modelId))...[
                            viewModel.ddCurrentPosition==0 ? Row(
                              children: [
                                SizedBox(
                                  width: 275,
                                  child: SegmentedButton<SegmentWithFlow>(
                                    segments: const <ButtonSegment<SegmentWithFlow>>[
                                      ButtonSegment<SegmentWithFlow>(
                                          value: SegmentWithFlow.manual,
                                          label: Text('Timeless'),
                                          icon: Icon(Icons.pan_tool_alt_outlined)),
                                      ButtonSegment<SegmentWithFlow>(
                                          value: SegmentWithFlow.duration,
                                          label: Text('Duration'),
                                          icon: Icon(Icons.timer_outlined)),
                                    ],
                                    selected: <SegmentWithFlow>{viewModel.segmentWithFlow},
                                    onSelectionChanged: (Set<SegmentWithFlow> newSelection) {
                                      viewModel.segmentWithFlow = newSelection.first;
                                      viewModel.segmentSelectionCallbackFunction(viewModel.segmentWithFlow.index, viewModel.durationValue, viewModel.selectedIrLine);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 5,),
                                viewModel.segmentWithFlow.index == 1 ? SizedBox(
                                  width: 85,
                                  child: TextButton(
                                    onPressed: () => viewModel.showDurationInputDialog(context),
                                    style: ButtonStyle(
                                      padding: WidgetStateProperty.all(
                                        const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                      ),
                                      backgroundColor: WidgetStateProperty.all<Color>(Theme.of(context).primaryColor.withOpacity(0.3)),
                                      shape: WidgetStateProperty.all<OutlinedBorder>(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                      ),
                                    ),
                                    child: Text(viewModel.durationValue, style: const TextStyle(color: Colors.black, fontSize: 17)),
                                  ),
                                ) :
                                Container(),
                                viewModel.segmentWithFlow.index == 2 ? SizedBox(
                                  width: 85,
                                  child: TextField(
                                    maxLength: 7,
                                    controller: viewModel.flowLiter,
                                    onChanged: (value) => viewModel.segmentSelectionCallbackFunction(viewModel.segmentWithFlow.index, value, viewModel.selectedIrLine),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Liters',
                                      counterText: '',
                                    ),
                                  ),
                                ):
                                Container(),
                              ],
                            ) :
                            Column(
                              children: [
                                SizedBox(
                                  width: 350,
                                  child: SegmentedButton<SegmentWithFlow>(
                                    segments: const <ButtonSegment<SegmentWithFlow>>[
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
                                          label: Text('Flow-Liters'),
                                          icon: Icon(Icons.water_drop_outlined)),
                                    ],
                                    selected: <SegmentWithFlow>{viewModel.segmentWithFlow},
                                    onSelectionChanged: (Set<SegmentWithFlow> newSelection) {
                                      viewModel.segmentWithFlow = newSelection.first;
                                      viewModel.segmentSelectionCallbackFunction(viewModel.segmentWithFlow.index, viewModel.durationValue, viewModel.selectedIrLine);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 5),
                                viewModel.segmentWithFlow.index == 1 ? SizedBox(
                                  width: 85,
                                  child: TextButton(
                                    onPressed: () => viewModel.showDurationInputDialog(context),
                                    style: ButtonStyle(
                                      padding: WidgetStateProperty.all(
                                        const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                      ),
                                      backgroundColor: WidgetStateProperty.all<Color>(Theme.of(context).primaryColor.withOpacity(0.3)),
                                      shape: WidgetStateProperty.all<OutlinedBorder>(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                      ),
                                    ),
                                    child: Text(viewModel.durationValue, style: const TextStyle(color: Colors.black, fontSize: 17)),
                                  ),
                                ) :
                                Container(),
                                viewModel.segmentWithFlow.index == 2 ? SizedBox(
                                  width: 85,
                                  child: TextField(
                                    maxLength: 7,
                                    controller: viewModel.flowLiter,
                                    onChanged: (value) => viewModel.segmentSelectionCallbackFunction(
                                        viewModel.segmentWithFlow.index, value, viewModel.selectedIrLine),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Liters',
                                      counterText: '',
                                    ),
                                  ),
                                ):
                                Container(),
                              ],
                            )
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 0),
                  Expanded(
                    child: SingleChildScrollView(
                      child: displayLineOrSequence(widget.masterData, viewModel, viewModel.ddCurrentPosition),
                    ),
                  ),
                  ListTile(
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 10),
                        MaterialButton(
                          color: Colors.redAccent,
                          textColor: Colors.white,
                          onPressed:() => viewModel.stopAllManualOperation(context),
                          child: const Text('Stop Manually'),
                        ),
                        const SizedBox(width: 16),
                        MaterialButton(
                          color: Colors.green,
                          textColor: Colors.white,
                          onPressed:() => viewModel.startManualOperation(context),
                          child: const Text('Start Manually'),
                        ),
                        const SizedBox(width: 15),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
    );
  }

  Widget displayLineOrSequence(MasterControllerModel masterData, StandAloneViewModel vm, int ddPosition){

    bool isNova = [...AppConstants.ecoGemModelList].contains(masterData.modelId);
    bool isAerator = [...AppConstants.aquacultureModelList].contains(masterData.modelId);


    if(isAerator) {
      final aerator = masterData.irrigationLine
          .expand((line) => line.aeratorSources)
          .expand((ws) => ws.aeratorPump)
          .toList();

      final allAerator = aerator.fold<Map<double, PumpModel>>({}, (map, pump) {
        map[pump.sNo] = pump;
        return map;
      }).values.toList();

      return AeratorCard(
        pumps: allAerator,
        onChanged: (pump, val) => setState(() => pump.selected = val),
      );
    }

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

    // NEW fertilizer tank concept: main source pumps + tank valves (deduped)
    final fertMainSources = <double, FertMainSource>{};
    final fertTanks = <double, FertTank>{};
    for (final site in [...cFertilizerSite, ...lFertilizerSite]) {
      if (!site.hasTankSystem) continue;
      for (final m in site.tankSystem!.mainSources) {
        fertMainSources.putIfAbsent(m.source.sNo, () => m);
      }
      for (final t in site.tankSystem!.tanks) {
        fertTanks.putIfAbsent(t.sNo, () => t);
      }
    }



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

            final valveRows = sequence.valve.map((valve) {

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
              rows: valveRows,
            );

          }).toList(),
        ) : const SizedBox(),

        FertMainSourceCard(
          sources: fertMainSources.values.toList(),
          onChanged: (pump, val) => setState(() => pump.selected = val),
        ),
        FertTankValveCard(
          tanks: fertTanks.values.toList(),
          onChanged: (valve, val) => setState(() => valve.selected = val),
        ),
      ],
    );
  }
}
