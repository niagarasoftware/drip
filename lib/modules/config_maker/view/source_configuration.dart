import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/device_object_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:oro_drip_irrigation/utils/Theme/smart_comm_theme.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../Constants/properties.dart';
import '../model/source_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/custom_drop_down_button.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';

class SourceConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const SourceConfiguration({super.key, required this.configPvd});

  @override
  State<SourceConfiguration> createState() => _SourceConfigurationState();
}

class _SourceConfigurationState extends State<SourceConfiguration> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(builder: (context, constraint) {
        return SizedBox(
          width: constraint.maxWidth,
          height: constraint.maxHeight,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ResponsiveGridList(
                  horizontalGridMargin: 0,
                  verticalGridMargin: 12,
                  minItemWidth: 480,
                  shrinkWrap: true,
                  listViewBuilderOptions: ListViewBuilderOptions(
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                  children: [
                    for (var source in widget.configPvd.source)
                      if (AppConstants.aquacultureModelList.contains(widget.configPvd.masterData['modelId']))
                        _buildAquacultureSourceCard(source)
                      else
                        _buildStandardSourceCard(source),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAquacultureSourceCard(SourceModel source) {
    String aeratorValue = source.aerator.isEmpty
        ? '-'
        : source.aerator.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', ');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double tileWidth = constraints.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: SizedImage(
                        imagePath: '${AppConstants.svgObjectPath}objectId_1.svg',
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${source.commonDetails.name}',
                      style: TextStyle(
                        color: primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildParameterTile(
                  title: 'Aerators',
                  imagePath: 'assets/png/aerators_o.png',
                  valueText: aeratorValue,
                  isAssigned: source.aerator.isNotEmpty,
                  cardWidth: tileWidth,
                  onTap: () {
                    setState(() {
                      widget.configPvd.listOfSelectedSno.clear();
                      widget.configPvd.listOfSelectedSno.addAll(source.aerator);
                    });
                    selectionDialogBox(
                      context: context,
                      title: 'Select Aerator',
                      singleSelection: false,
                      listOfObject: widget.configPvd.listOfGeneratedObject
                          .where((object) => (object.objectId == AppConstants.pumpObjectId))
                          .toList(),
                      onPressed: () {
                        setState(() {
                          source.aerator.clear();
                          source.aerator.addAll(widget.configPvd.listOfSelectedSno);
                          widget.configPvd.updateAssignObject(
                            sNo: source.commonDetails.sNo!,
                            objectId: AppConstants.pumpObjectId,
                            listOfSerialNo: widget.configPvd.listOfSelectedSno,
                          );
                          widget.configPvd.listOfSelectedSno.clear();
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStandardSourceCard(SourceModel source) {
    bool isFertilizerSource = [6, 7].contains(source.sourceType);
    bool isBoreOrPond = [4, 5].contains(source.sourceType);
    bool hasValves = widget.configPvd.listOfGeneratedObject.any((object) => object.objectId == AppConstants.valveObjectId);
    bool hasTankValves = widget.configPvd.listOfGeneratedObject.any((object) => object.objectId == AppConstants.tankValveObjectId);
    bool hasAgitators = widget.configPvd.listOfGeneratedObject.any((object) => object.objectId == AppConstants.agitatorObjectId);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: AppProperties.customBoxShadowLiteTheme,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: SizedImage(
                    imagePath: '${AppConstants.svgObjectPath}objectId_1.svg',
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    source.commonDetails.name!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1E293B),
                    ),
                  ),
                ),
                CustomDropDownButton(
                  value: getTankCodeToString(source.sourceType),
                  list: const [
                    'Tank',
                    'Sump',
                    'Well',
                    'Bore',
                    'Fertilizer Source',
                    'Fertilizer Tank',
                    'Others'
                  ],
                  onChanged: (value) {
                    setState(() {
                      source.sourceType = getTankStringToCode(value!);
                      if ([4, 5].contains(source.sourceType)) {
                        source.inletPump.clear();
                        source.level = 0.0;
                        source.topFloatForInletPump = 0.0;
                        source.bottomFloatForInletPump = 0.0;
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // Parameter Content Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double availableWidth = constraints.maxWidth;
                double tileWidth = availableWidth > 500 ? (availableWidth - 12) / 2 : availableWidth;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Pumps
                    _buildSectionHeader('Pumps', Icons.power_rounded),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (!isBoreOrPond)
                          _buildParameterTileForPump(source, 1, tileWidth), // Inlet Pump
                        _buildParameterTileForPump(source, 2, tileWidth), // Outlet Pump
                      ],
                    ),

                    // Section 2: Valves (if available and not bore/pond)
                    if (!isBoreOrPond && hasValves) ...[
                      const SizedBox(height: 20),
                      _buildSectionHeader('Valves', Icons.alt_route_rounded),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildParameterTileForValve(source, true, tileWidth), // Inlet Valve
                          _buildParameterTileForValve(source, false, tileWidth), // Outlet Valve
                        ],
                      ),
                    ],

                    // Section 3: Level & Sensors (if standard source, not bore/pond)
                    if (!isBoreOrPond && !isFertilizerSource) ...[
                      const SizedBox(height: 20),
                      _buildSectionHeader('Level & Sensors', Icons.sensors_rounded),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (var mode in [1, 2, 3, 4, 5, 6])
                            _buildParameterTileForSensor(source, mode, tileWidth),
                        ],
                      ),
                    ],

                    // Section 4: Fertilizer Source / Tank specific parameters
                    if (isFertilizerSource) ...[
                      if (hasTankValves || hasAgitators) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader('Tank Components', Icons.water_drop_rounded),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (hasTankValves) ...[
                              _buildParameterTileForTankValve(source, true, tileWidth), // Inlet Tank Valve
                              _buildParameterTileForTankValve(source, false, tileWidth), // Outlet Tank Valve
                            ],
                            if (hasAgitators)
                              _buildParameterTileForAgitator(source, tileWidth),
                          ],
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).primaryColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildParameterTile({
    required String title,
    required String imagePath,
    required String valueText,
    required bool isAssigned,
    required VoidCallback onTap,
    required double cardWidth,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isAssigned
                ? Theme.of(context).primaryColorLight.withOpacity(0.08)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAssigned
                  ? Theme.of(context).primaryColor.withOpacity(0.4)
                  : Colors.grey.shade300,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isAssigned
                      ? Theme.of(context).primaryColor.withOpacity(0.12)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: SizedImage(
                  imagePath: imagePath,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff334155),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAssigned ? valueText : 'Not assigned',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isAssigned ? FontWeight.bold : FontWeight.w400,
                        color: isAssigned ? Theme.of(context).primaryColor : Colors.grey.shade500,
                        fontStyle: isAssigned ? FontStyle.normal : FontStyle.italic,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isAssigned ? Icons.edit_outlined : Icons.add_circle_outline_rounded,
                color: isAssigned ? Theme.of(context).primaryColor : Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParameterTileForPump(SourceModel source, int pumpMode, double cardWidth) {
    List<double> currentParameter = pumpMode == 1 ? source.inletPump : source.outletPump;
    List<double> checkingParameter = pumpMode == 1 ? source.outletPump : source.inletPump;
    String valueText = currentParameter.isEmpty
        ? ''
        : currentParameter.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', ');

    return _buildParameterTile(
      title: '${pumpMode == 1 ? 'Inlet' : 'Outlet'} Pump',
      imagePath: '${AppConstants.svgObjectPath}objectId_5.svg',
      valueText: valueText,
      isAssigned: currentParameter.isNotEmpty,
      cardWidth: cardWidth,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(currentParameter);
        });
        selectionDialogBox(
          context: context,
          title: 'Select ${pumpMode == 1 ? 'Inlet' : 'Outlet'} Pump',
          singleSelection: false,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) => (object.objectId == 5 && !checkingParameter.contains(object.sNo)))
              .toList(),
          onPressed: () {
            setState(() {
              if (pumpMode == 1) {
                source.inletPump.clear();
                source.inletPump.addAll(widget.configPvd.listOfSelectedSno);
              } else {
                source.outletPump.clear();
                source.outletPump.addAll(widget.configPvd.listOfSelectedSno);
              }
              widget.configPvd.listOfSelectedSno.clear();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildParameterTileForValve(SourceModel source, bool isInlet, double cardWidth) {
    List<double> currentList = isInlet ? source.valves : source.outletValves;
    String valueText = currentList.isEmpty
        ? ''
        : currentList.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', ');

    return _buildParameterTile(
      title: isInlet ? 'Inlet Valve' : 'Outlet Valve',
      imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.valveObjectId}.svg',
      valueText: valueText,
      isAssigned: currentList.isNotEmpty,
      cardWidth: cardWidth,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(currentList);
        });
        selectionDialogBox(
          context: context,
          title: isInlet ? 'Select Inlet Valve' : 'Select Outlet Valve',
          singleSelection: false,
          listOfObject: widget.configPvd.listOfGeneratedObject.where((object) {
            if (object.objectId != AppConstants.valveObjectId) return false;
            if (isInlet) {
              return !widget.configPvd.source.any((src) => src.outletValves.contains(object.sNo));
            } else {
              return !widget.configPvd.source.any((src) => src.valves.contains(object.sNo));
            }
          }).toList(),
          onPressed: () {
            if (!isInlet && widget.configPvd.listOfSelectedSno.length > 1) {
              simpleDialogBox(
                context: context,
                title: 'Alert',
                message: 'Only single valve can be selected for outlet valve.',
              );
            } else {
              setState(() {
                if (isInlet) {
                  source.valves.clear();
                  source.valves.addAll(widget.configPvd.listOfSelectedSno);
                  widget.configPvd.updateAssignObject(
                    sNo: source.commonDetails.sNo!,
                    objectId: AppConstants.valveObjectId,
                    listOfSerialNo: widget.configPvd.listOfSelectedSno,
                  );
                } else {
                  source.outletValves.clear();
                  source.outletValves.addAll(widget.configPvd.listOfSelectedSno);
                  widget.configPvd.updateAssignObject(
                    sNo: source.commonDetails.sNo!,
                    objectId: AppConstants.valveObjectId,
                    listOfSerialNo: widget.configPvd.listOfSelectedSno,
                  );
                }
                widget.configPvd.listOfSelectedSno.clear();
              });
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }

  Widget _buildParameterTileForSensor(SourceModel source, int mode, double cardWidth) {
    int objectId = mode == 1
        ? AppConstants.levelObjectId
        : mode == 6
            ? AppConstants.waterMeterObjectId
            : AppConstants.floatObjectId;

    Map<int, String> currentObjectName = {
      1: 'Level Sensor',
      2: 'Top Float For Inlet Pumps',
      3: 'Bottom Float For Inlet Pumps',
      4: 'Top Float For Outlet Pumps',
      5: 'Bottom Float For Outlet Pumps',
      6: 'Outlet Water Meter',
    };

    Map<int, double> currentSno = {
      1: source.level,
      2: source.topFloatForInletPump,
      3: source.bottomFloatForInletPump,
      4: source.topFloatForOutletPump,
      5: source.bottomFloatForOutletPump,
      6: source.outletWaterMeter,
    };

    double activeSno = currentSno[mode] ?? 0.0;
    String valueText = activeSno == 0.0
        ? ''
        : getObjectName(activeSno, widget.configPvd).name ?? '';

    return _buildParameterTile(
      title: currentObjectName[mode]!,
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      valueText: valueText,
      isAssigned: activeSno != 0.0,
      cardWidth: cardWidth,
      onTap: () {
        List<double> validateSensorFromOtherSource = [];
        for (var src in widget.configPvd.source) {
          validateSensorFromOtherSource.add(src.level);
          validateSensorFromOtherSource.add(src.outletWaterMeter);
          validateSensorFromOtherSource.add(src.topFloatForInletPump);
          validateSensorFromOtherSource.add(src.bottomFloatForInletPump);
          validateSensorFromOtherSource.add(src.topFloatForOutletPump);
          validateSensorFromOtherSource.add(src.bottomFloatForOutletPump);
        }
        validateSensorFromOtherSource.remove(activeSno);

        setState(() {
          widget.configPvd.selectedSno = activeSno;
        });

        selectionDialogBox(
          context: context,
          title: 'Select ${currentObjectName[mode]}',
          singleSelection: true,
          listOfObject: widget.configPvd.listOfGeneratedObject.where((object) {
            if (object.objectId != objectId) {
              return false;
            }
            if (validateSensorFromOtherSource.contains(object.sNo)) {
              return false;
            }
            return true;
          }).toList(),
          onPressed: () {
            bool sensorRemovedInAnyPump = false;
            double oldSensorSno = activeSno;
            late DeviceObjectModel deviceObjectModel;
            List<String> sensorsRemovedFromPump = [];

            if (mode == 1) {
              oldSensorSno = source.level;
              source.level = widget.configPvd.selectedSno;
            } else if (mode == 2) {
              oldSensorSno = source.topFloatForInletPump;
              source.topFloatForInletPump = widget.configPvd.selectedSno;
            } else if (mode == 3) {
              oldSensorSno = source.bottomFloatForInletPump;
              source.bottomFloatForInletPump = widget.configPvd.selectedSno;
            } else if (mode == 4) {
              oldSensorSno = source.topFloatForOutletPump;
              source.topFloatForOutletPump = widget.configPvd.selectedSno;
            } else if (mode == 5) {
              oldSensorSno = source.bottomFloatForOutletPump;
              source.bottomFloatForOutletPump = widget.configPvd.selectedSno;
            } else {
              oldSensorSno = source.outletWaterMeter;
              source.outletWaterMeter = widget.configPvd.selectedSno;
            }

            widget.configPvd.selectedSno = 0.0;
            setState(() {});
            Navigator.pop(context);

            if (oldSensorSno != 0.0 && oldSensorSno != (currentSno[mode] ?? 0.0)) {
              deviceObjectModel = widget.configPvd.listOfGeneratedObject.firstWhere((object) => object.sNo == oldSensorSno);
              for (var pump in widget.configPvd.pump) {
                if ([...source.outletPump, ...source.inletPump].contains(pump.commonDetails.sNo)) {
                  if (mode == 1) {
                    if (pump.lowerLevel == oldSensorSno) {
                      pump.lowerLevel = 0.0;
                      sensorsRemovedFromPump.add(pump.commonDetails.name!);
                      sensorRemovedInAnyPump = true;
                    } else if (pump.upperLevel == oldSensorSno) {
                      pump.upperLevel = 0.0;
                      sensorRemovedInAnyPump = true;
                      sensorsRemovedFromPump.add(pump.commonDetails.name!);
                    }
                  } else if ([2, 3, 4, 5].contains(mode)) {
                    bool isFloatRemoved = false;
                    if (pump.topTankFloat == oldSensorSno) {
                      pump.topTankFloat = 0.0;
                      isFloatRemoved = true;
                    } else if (pump.bottomTankFloat == oldSensorSno) {
                      pump.bottomTankFloat = 0.0;
                      isFloatRemoved = true;
                    } else if (pump.topSumpFloat == oldSensorSno) {
                      pump.topSumpFloat = 0.0;
                      isFloatRemoved = true;
                    } else if (pump.bottomSumpFloat == oldSensorSno) {
                      pump.bottomSumpFloat = 0.0;
                      isFloatRemoved = true;
                    }
                    if (isFloatRemoved) {
                      sensorsRemovedFromPump.add(pump.commonDetails.name!);
                      sensorRemovedInAnyPump = true;
                    }
                  }
                }
              }
            }
            setState(() {});
            if (sensorRemovedInAnyPump) {
              simpleDialogBox(
                context: context,
                title: 'Alert',
                message: 'The ${deviceObjectModel.name} is removed from ${sensorsRemovedFromPump.join(',')} in the pump configuration',
              );
            }
          },
        );
      },
    );
  }

  Widget _buildParameterTileForTankValve(SourceModel source, bool isInlet, double cardWidth) {
    List<double> currentList = isInlet ? source.inletTankValve : source.outletTankValve;
    String valueText = currentList.isEmpty
        ? ''
        : currentList.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', ');

    return _buildParameterTile(
      title: isInlet ? 'Inlet Tank Valve' : 'Outlet Tank Valve',
      imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.tankValveObjectId}.svg',
      valueText: valueText,
      isAssigned: currentList.isNotEmpty,
      cardWidth: cardWidth,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(currentList);
        });
        selectionDialogBox(
          context: context,
          title: isInlet ? 'Select Inlet Tank Valve' : 'Select Outlet Tank Valve',
          singleSelection: false,
          listOfObject: widget.configPvd.listOfGeneratedObject.where((object) {
            if (object.objectId != AppConstants.tankValveObjectId) return false;
            if (isInlet) {
              return !widget.configPvd.source.any((src) => src.outletTankValve.contains(object.sNo));
            } else {
              return !widget.configPvd.source.any((src) => src.inletTankValve.contains(object.sNo));
            }
          }).toList(),
          onPressed: () {
            setState(() {
              if (isInlet) {
                source.inletTankValve.clear();
                source.inletTankValve.addAll(widget.configPvd.listOfSelectedSno);
              } else {
                source.outletTankValve.clear();
                source.outletTankValve.addAll(widget.configPvd.listOfSelectedSno);
              }
              widget.configPvd.updateAssignObject(
                sNo: source.commonDetails.sNo!,
                objectId: AppConstants.tankValveObjectId,
                listOfSerialNo: widget.configPvd.listOfSelectedSno,
              );
              widget.configPvd.listOfSelectedSno.clear();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildParameterTileForAgitator(SourceModel source, double cardWidth) {
    String valueText = source.agitator.isEmpty
        ? ''
        : source.agitator.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', ');

    return _buildParameterTile(
      title: 'Agitator',
      imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.agitatorObjectId}.svg',
      valueText: valueText,
      isAssigned: source.agitator.isNotEmpty,
      cardWidth: cardWidth,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(source.agitator);
        });
        selectionDialogBox(
          context: context,
          title: 'Select Agitator',
          singleSelection: false,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) => (object.objectId == AppConstants.agitatorObjectId))
              .toList(),
          onPressed: () {
            setState(() {
              source.agitator.clear();
              source.agitator.addAll(widget.configPvd.listOfSelectedSno);
              widget.configPvd.updateAssignObject(
                sNo: source.commonDetails.sNo!,
                objectId: AppConstants.agitatorObjectId,
                listOfSerialNo: widget.configPvd.listOfSelectedSno,
              );
              widget.configPvd.listOfSelectedSno.clear();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

List<Widget> getWaterMeterAndPressure(double pressureInSno, double waterMeterSno, ConfigMakerProvider configPvd){
  return [
    if(pressureInSno != 0.0)
      Positioned(
        right: 0,
        top: 15 * configPvd.ratio,
        child: Image.asset(
            'assets/Images/Png/objectId_24.png',
          width: 30,
          height: 30,
        ),
      ),
    if(waterMeterSno != 0.0)
      Positioned(
      right: 0,
      top: 50 * configPvd.ratio,
        child: Image.asset(
          'assets/Images/Png/objectId_22.png',
          width: 30,
          height: 30,
        ),
    ),
  ];
}

Widget singlePump(SourceModel source, bool fillingPump, ConfigMakerProvider configPvd, {bool dashboard = false}){
  List<double> currentParameter = fillingPump ? source.inletPump : source.outletPump;
  return Stack(
    children: [
      Positioned(
        left : fillingPump ? 40 : null,
        right : (!fillingPump && dashboard) ? 0 : (!fillingPump) ? 40 : null,
        bottom: 32 * configPvd.ratio,
        child: SvgPicture.asset(
          'assets/Images/Source/backside_pipe_1.svg',
          width: 120 ,
          height: 8.5 * configPvd.ratio,
        ),
      ),
      SvgPicture.asset(
        'assets/Images/Source/pump_1.svg',
        width: 120,
        height: 120 * configPvd.ratio,
      ),
      ...getWaterMeterAndPressure(
          configPvd.pump.firstWhere((pump) => pump.commonDetails.sNo == currentParameter[0]).pressureIn,
          configPvd.pump.firstWhere((pump) => pump.commonDetails.sNo == currentParameter[0]).waterMeter,
        configPvd
      ),
      Positioned(
        left : 5,
        top: 0,
        child: Text(getObjectName(currentParameter[0], configPvd).name!,style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),),
      )
    ],
  );
}

Widget multiplePump(SourceModel source, bool fillingPump, ConfigMakerProvider configPvd,
    {bool dashBoard = false, int? maxOutletPumpForTank}){
  List<double> currentParameter = fillingPump ? source.inletPump : source.outletPump;
  return Row(
    children: [
      for(var i = 0;i < currentParameter.length;i++)
        Stack(
          children: [
            Positioned(
              left: fillingPump ? (i == 0 ? 50 : null) : null,
              right: (!fillingPump && i == currentParameter.length -1 && !dashBoard) ? 40 : null,
              bottom: 32 * configPvd.ratio,
              child: SvgPicture.asset(
                'assets/Images/Source/backside_pipe_1.svg',
                width: 120,
                height: 8.5 * configPvd.ratio,
              ),
            ),
            SvgPicture.asset(
              'assets/Images/Source/pump_1.svg',
              width: 120,
              height: 120 * configPvd.ratio,
            ),
            ...getWaterMeterAndPressure(
                configPvd.pump.firstWhere((pump) => pump.commonDetails.sNo == currentParameter[i]).pressureIn,
                configPvd.pump.firstWhere((pump) => pump.commonDetails.sNo == currentParameter[i]).waterMeter,
              configPvd
            ),
            if(currentParameter.length > 1)
              Positioned(
              right: i == 0 ? 0 : null,
              left: i == 1 ? 0 : null,
              bottom: 16 * configPvd.ratio,
              child: SvgPicture.asset(
                'assets/Images/Source/${
                    i == 0
                        ? 'front_corner_left_radius_pipe_1'
                        : i == (currentParameter.length - 1)
                        ? 'front_corner_right_radius_pipe_1'
                        : 'backside_pipe_1'}.svg',
                width: 120,
                height: 8.5 * configPvd.ratio,
              ),
            ),
            Positioned(
              left : 5,
              top: 0,
              child: Text(getObjectName(currentParameter[i], configPvd).name!,style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),),
            )
          ],
        ),
      if(maxOutletPumpForTank != null)
        for(var i = 0;i < (maxOutletPumpForTank - currentParameter.length);i++)
          SizedBox(
            width: 94,
            height: 120 * configPvd.ratio,
            child: Stack(
              children: [
                Positioned(
                  bottom : 32 * configPvd.ratio,
                  child: SvgPicture.asset(
                    'assets/Images/Source/backside_pipe_1.svg',
                    width: 120,
                    height: 8.5 * configPvd.ratio,
                  ),
                )
              ],
            ),
          )
    ],
  );
}

Widget getTankImage(SourceModel source ,ConfigMakerProvider configPvd, {bool dashboard = false, bool inlet = true,}){
  bool levelAvailable = source.level != 0.0;
  bool topFloatAvailableForOutlet = source.topFloatForOutletPump != 0.0;
  bool bottomFloatAvailableForOutlet = source.bottomFloatForOutletPump != 0.0;
  bool topFloatAvailableForInlet = source.topFloatForInletPump != 0.0;
  bool bottomFloatAvailableForInlet = source.bottomFloatForInletPump != 0.0;
  bool outletWaterMeter = source.outletWaterMeter != 0.0;
  bool outletValve = source.outletValves.isNotEmpty;
  if(source.sourceType == 1){
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Images/Source/tank_${!inlet ? 'outlet_' : ''}1.svg',
          width: 120,
          height: 120 * configPvd.ratio,
        ),
        if(levelAvailable)
          Positioned(
            left: 52,
            bottom: 28,
            child: Container(
              width: 10,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.green
                ),
              ),
            ),
          ),
        if(topFloatAvailableForOutlet)
          Positioned(
            right: 40,
            bottom: 50,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 40,
            ),
          ),
        if(topFloatAvailableForInlet)
          Positioned(
            left: 40,
            bottom: 50,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 40,
            ),
          ),
        if(bottomFloatAvailableForOutlet)
          Positioned(
            right: 50,
            bottom: 25,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 70,
              height: 70,
            ),
          ),
        if(bottomFloatAvailableForInlet)
          Positioned(
            left: 50,
            bottom: 25,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 70,
              height: 70,
            ),
          ),
        if(outletWaterMeter)
          Positioned(
            right: 0,
            bottom: 20,
            child: Image.asset(
              'assets/Images/Png/objectId_${AppConstants.waterMeterObjectId}.png',
              width: 30,
              height: 30,
            ),
          )
      ],
    );
  }
  else if(source.sourceType == 2){
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Images/Source/sump_${!inlet ? 'outlet_' : ''}1.svg',
          width: 120,
          height: 120 * configPvd.ratio,
        ),
        if(levelAvailable)
          Positioned(
            left: 52,
            bottom: 35,
            child: Container(
              width: 10,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.green
                ),
              ),
            ),
          ),
        if(topFloatAvailableForOutlet)
          Positioned(
            right: 55,
            bottom: 55,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 30,
            ),
          ),
        if(bottomFloatAvailableForOutlet)
          Positioned(
            right: 70,
            bottom: 35,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 50,
              height: 50,
            ),
          ),
        if(outletWaterMeter)
          Positioned(
            right: 0,
            bottom: 20,
            child: Image.asset(
              'assets/Images/Png/objectId_${AppConstants.waterMeterObjectId}.png',
              width: 30,
              height: 30,
            ),
          )
      ],
    );
  }
  else if(source.sourceType == 3){
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Images/Source/well_${!inlet ? 'outlet_' : ''}1.svg',
          width: 120,
          height: 120 * configPvd.ratio,
        ),
        if(levelAvailable)
          Positioned(
            left: 45,
            bottom: 22,
            child: Container(
              width: 10,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.green
                ),
              ),
            ),
          ),
        if(topFloatAvailableForOutlet)
          Positioned(
            right: 55,
            bottom: 55,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 30,
            ),
          ),
        if(bottomFloatAvailableForOutlet)
          Positioned(
            right: 70,
            bottom: 35,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 50,
              height: 50,
            ),
          ),
        if(outletWaterMeter)
          Positioned(
            right: 0,
            bottom: 20,
            child: Image.asset(
              'assets/Images/Png/objectId_${AppConstants.waterMeterObjectId}.png',
              width: 30,
              height: 30,
            ),
          )
      ],
    );
  }
  else if(source.sourceType == 4){
    return SvgPicture.asset(
      'assets/Images/Source/bore_1.svg',
      width: 120,
      height: 120 * configPvd.ratio,
    );
  }
  else if(source.sourceType == 5){
    return SvgPicture.asset(
      'assets/Images/Source/pond_1.svg',
      width: 120,
      height: 120* configPvd.ratio,
    );
  }else if(source.sourceType == 6){
    return SvgPicture.asset(
      'assets/Images/Source/fertilizer_source.svg',
      width: 120,
      height: 120* configPvd.ratio,
    );
  }else{
    return SvgPicture.asset(
      'assets/Images/Source/fertilizer_tank.svg',
      width: 120,
      height: 120* configPvd.ratio,
    );
  }
}
