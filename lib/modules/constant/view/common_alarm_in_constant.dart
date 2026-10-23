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

  bool _isTitleMatch(String t1, String t2) {
    String clean(String s) => s
        .toLowerCase()
        .replaceAll('comminication', 'communication')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return clean(t1) == clean(t2);
  }

  void _syncWithNormalCritical(
      int rowIndex, ConstantSettingModel setting, dynamic value) {
    if (widget.constPvd.commonAlarm.isEmpty) return;
    if (rowIndex >= widget.constPvd.commonAlarm[0].alarmList.length) return;

    final alarm = widget.constPvd.commonAlarm[0].alarmList[rowIndex];

    // Update in all commonAlarm lines
    for (var line in widget.constPvd.commonAlarm) {
      if (rowIndex < line.alarmList.length) {
        for (var s in line.alarmList[rowIndex].setting) {
          if (s.sNo == setting.sNo || _isTitleMatch(s.title, setting.title)) {
            s.value.value = value;
          }
        }
      }
    }

    if (setting.title.toLowerCase().contains('on/off')) {
      for (var g in widget.constPvd.globalAlarm) {
        if (_isTitleMatch(g.title, alarm.title)) {
          g.value.value = value;
          break;
        }
      }
      return;
    }

    // Sync across ALL normalCriticalAlarm lines
    for (var normalCriticalLine in widget.constPvd.normalCriticalAlarm) {
      for (var normalAlarm in normalCriticalLine.normal) {
        if (_isTitleMatch(normalAlarm.title, alarm.title)) {
          for (var s in normalAlarm.setting) {
            if (s.title.toLowerCase() == setting.title.toLowerCase()) {
              s.value.value = value;
              break;
            }
          }
        }
      }
      for (var criticalAlarm in normalCriticalLine.critical) {
        if (_isTitleMatch(criticalAlarm.title, alarm.title)) {
          for (var s in criticalAlarm.setting) {
            if (s.title.toLowerCase() == setting.title.toLowerCase()) {
              s.value.value = value;
              break;
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    var rawModelId = widget.constPvd.userData['modelId'] ??
        widget.constPvd.userData['modelid'] ??
        (widget.constPvd.userData['masterData'] is Map
            ? (widget.constPvd.userData['masterData']['modelId'] ??
                widget.constPvd.userData['masterData']['modelid'])
            : null);
    int? modelId = rawModelId is int
        ? rawModelId
        : int.tryParse(rawModelId?.toString() ?? '');

    bool isGem = AppConstants.gemModelList.contains(modelId);
    bool isNova = AppConstants.ecoGemAndPlusModelList.contains(modelId);

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
    final currentLine = widget.constPvd.commonAlarm[0];

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
                index < widget.constPvd.defaultCommonAlarmSetting.length;
                index++)
              if (visibleSettings.contains(
                  widget.constPvd.defaultCommonAlarmSetting[index]))
                DataCell(
                  Builder(
                    builder: (context) {
                      ConstantSettingModel? foundSetting;
                      for (var s in alarm.setting) {
                        if (s.sNo ==
                            widget.constPvd.defaultCommonAlarmSetting[index]
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
                          widget.constPvd.defaultCommonAlarmSetting[index].title
                              .toLowerCase()
                              .contains('scan time') &&
                          !(alarm.title.toLowerCase().contains('low flow') ||
                              alarm.title.toLowerCase().contains('high flow') ||
                              alarm.title.toLowerCase().contains('no flow'))) {
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
                                  row,
                                  alarmSetting,
                                  value,
                                );
                              },
                              onOk: () {
                                alarmSetting.value.value =
                                    widget.overAllPvd.getTime();
                                _syncWithNormalCritical(
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
                                  : widget.constPvd.alarmResetAfterIrrigation,
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
  }
}
