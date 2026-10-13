import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/constant/model/alarm_in_constant_model.dart';
import 'package:oro_drip_irrigation/modules/constant/model/constant_setting_model.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';

import '../../../StateManagement/overall_use.dart';
import '../state_management/constant_provider.dart';
import '../widget/find_suitable_widget.dart';

class CommonAlarmInConstant extends StatefulWidget {
  final ConstantProvider constPvd;
  final OverAllUse overAllPvd;
  const CommonAlarmInConstant({
    super.key,
    required this.constPvd,
    required this.overAllPvd,
  });

  @override
  State<CommonAlarmInConstant> createState() => _CommonAlarmInConstantState();
}

class _CommonAlarmInConstantState extends State<CommonAlarmInConstant> {
  double cellWidth = 180;
  ValueNotifier<int> selectedIrrigationLine = ValueNotifier(0);

  void _syncWithNormalCritical(
      int lineIndex, int rowIndex, ConstantSettingModel setting, dynamic value) {
    if (lineIndex < widget.constPvd.commonAlarm.length &&
        rowIndex < widget.constPvd.commonAlarm[lineIndex].alarmList.length) {
      final alarm = widget.constPvd.commonAlarm[lineIndex].alarmList[rowIndex];
      if (setting.title.toLowerCase().contains('on/off')) {
        for (var g in widget.constPvd.globalAlarm) {
          if (g.sNo == alarm.sNo) {
            g.value.value = value;
            break;
          }
        }
        return;
      }
    }

    if (lineIndex < widget.constPvd.normalCriticalAlarm.length) {
      final normalCriticalLine = widget.constPvd.normalCriticalAlarm[lineIndex];
      if (rowIndex < normalCriticalLine.normal.length) {
        for (var s in normalCriticalLine.normal[rowIndex].setting) {
          if (s.title.toLowerCase() == setting.title.toLowerCase()) {
            s.value.value = value;
            break;
          }
        }
      }
      if (rowIndex < normalCriticalLine.critical.length) {
        for (var s in normalCriticalLine.critical[rowIndex].setting) {
          if (s.title.toLowerCase() == setting.title.toLowerCase()) {
            s.value.value = value;
            break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isGem =
        AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']);
    bool isNova = AppConstants.ecoGemModelList
        .contains(widget.constPvd.userData['modelId']);

    if (widget.constPvd.commonAlarm.isEmpty) {
      return const Center(child: Text('No common alarm settings available.'));
    }

    List<ConstantSettingModel> visibleSettings =
        widget.constPvd.defaultCommonAlarmSetting.where((defaultSetting) {
      bool display =
          isGem ? defaultSetting.gemDisplay : defaultSetting.ecoGemDisplay;
      if (isNova && display) {
        String titleLower = defaultSetting.title.toLowerCase();
        if (titleLower.contains('alarm on status') ||
            titleLower.contains('auto reset') ||
            titleLower.contains('reset after irrigation') ||
            titleLower.contains('active')) {
          display = false;
        }
      }
      return display;
    }).toList();

    if (visibleSettings.isEmpty) {
      return const Center(child: Text('No common alarm settings available.'));
    }

    double minWidth =
        (cellWidth * 1) + (visibleSettings.length * cellWidth) + 50;
    Color borderColor = const Color(0xffE1E2E3);

    return Column(
      children: [
        _buildIrrigationLineTabs(),
        Expanded(
          child: AnimatedBuilder(
            animation: selectedIrrigationLine,
            builder: (context, child) {
              if (selectedIrrigationLine.value >=
                  widget.constPvd.commonAlarm.length) {
                selectedIrrigationLine.value = 0;
              }
              final currentLine =
                  widget.constPvd.commonAlarm[selectedIrrigationLine.value];

              return DataTable2(
                border: TableBorder(
                  top: BorderSide(color: borderColor, width: 1),
                  bottom: BorderSide(color: borderColor, width: 1),
                  left: BorderSide(color: borderColor, width: 1),
                  right: BorderSide(color: borderColor, width: 1),
                ),
                minWidth: minWidth,
                fixedLeftColumns: minWidth < screenWidth ? 0 : 1,
                columns: [
                  DataColumn2(
                    headingRowAlignment: MainAxisAlignment.center,
                    fixedWidth: cellWidth,
                    label: Text(
                      'Alarm',
                      style: Theme.of(context).textTheme.labelLarge,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                  ...visibleSettings.map((defaultSetting) {
                    return DataColumn2(
                      headingRowAlignment: MainAxisAlignment.center,
                      fixedWidth: cellWidth,
                      label: Text(
                        defaultSetting.title,
                        style: Theme.of(context).textTheme.labelLarge,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    );
                  }),
                ],
                rows: List.generate(currentLine.alarmList.length, (row) {
                  AlarmInConstantModel alarm = currentLine.alarmList[row];

                  return DataRow2(
                    specificRowHeight: 50,
                    color: WidgetStatePropertyAll(
                      row.isOdd ? Colors.white : const Color(0xffF8F8F8),
                    ),
                    cells: [
                      DataCell(
                        Center(
                          child: Text(
                            alarm.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      for (var index = 0;
                          index <
                              widget.constPvd.defaultCommonAlarmSetting.length;
                          index++)
                        if (visibleSettings.contains(
                            widget.constPvd.defaultCommonAlarmSetting[index]))
                          DataCell(
                            Builder(
                              builder: (context) {
                                ConstantSettingModel? foundSetting;
                                for (var s in alarm.setting) {
                                  if (s.sNo ==
                                      widget
                                          .constPvd
                                          .defaultCommonAlarmSetting[index]
                                          .sNo) {
                                    foundSetting = s;
                                    break;
                                  }
                                }
                                if (foundSetting == null) {
                                  return SizedBox(
                                    height: 40,
                                    width: cellWidth,
                                    child: const Center(child: Text('-')),
                                  );
                                }
                                final alarmSetting = foundSetting;

                                if (isNova &&
                                    widget.constPvd
                                        .defaultCommonAlarmSetting[index].title
                                        .toLowerCase()
                                        .contains('scan time') &&
                                    !(alarm.title
                                            .toLowerCase()
                                            .contains('low flow') ||
                                        alarm.title
                                            .toLowerCase()
                                            .contains('high flow') ||
                                        alarm.title
                                            .toLowerCase()
                                            .contains('no flow'))) {
                                  return SizedBox(
                                    height: 40,
                                    width: cellWidth,
                                    child: const Center(child: Text('-')),
                                  );
                                }

                                return AnimatedBuilder(
                                  animation: alarmSetting.value,
                                  builder: (context, child) {
                                    return SizedBox(
                                      height: 40,
                                      width: cellWidth,
                                      child: FindSuitableWidget(
                                        constantSettingModel: alarmSetting,
                                        onUpdate: (value) {
                                          alarmSetting.value.value = value;
                                          _syncWithNormalCritical(
                                            selectedIrrigationLine.value,
                                            row,
                                            alarmSetting,
                                            value,
                                          );
                                        },
                                        onOk: () {
                                          alarmSetting.value.value =
                                              widget.overAllPvd.getTime();
                                          _syncWithNormalCritical(
                                            selectedIrrigationLine.value,
                                            row,
                                            alarmSetting,
                                            widget.overAllPvd.getTime(),
                                          );
                                          Navigator.pop(context);
                                        },
                                        popUpItemModelList: alarmSetting.title
                                                .toLowerCase()
                                                .contains('status')
                                            ? widget.constPvd.alarmOnStatus
                                            : widget.constPvd
                                                .alarmResetAfterIrrigation,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                    ],
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIrrigationLineTabs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var line = 0;
                  line < widget.constPvd.commonAlarm.length;
                  line++)
                AnimatedBuilder(
                  animation: selectedIrrigationLine,
                  builder: (context, child) {
                    final isSelected = selectedIrrigationLine.value == line;
                    return InkWell(
                      onTap: () {
                        selectedIrrigationLine.value = line;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: isSelected ? 12 : 10,
                        ),
                        decoration: BoxDecoration(
                          border: const Border(
                            top: BorderSide(width: 0.5),
                            left: BorderSide(width: 0.5),
                            right: BorderSide(width: 0.5),
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5),
                          ),
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade100,
                        ),
                        child: Text(
                          widget.constPvd.commonAlarm[line].name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          height: 3,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
