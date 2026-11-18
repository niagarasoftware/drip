import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';

import '../../models/customer/constant_model.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../view_models/customer/constant_view_model.dart';

class Constant extends StatelessWidget {
  const Constant(
      {super.key,
      required this.customerId,
      required this.controllerId,
      required this.userId});

  final int customerId, controllerId, userId;

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (_) => ConstantViewModel(context, Repository(HttpService()))
        ..getConstantData(customerId, controllerId),
      child: Consumer<ConstantViewModel>(
        builder: (context, vm, _) {

          return vm.isLoading?
          Padding(
                  padding: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width / 2 - 95,
                      right: MediaQuery.of(context).size.width / 2 - 95),
                  child: const LoadingIndicator(
                    indicatorType: Indicator.ballPulse,
                    strokeWidth: 100,
                  ),
                ):
          Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: DefaultTabController(
              length: vm.filteredMenu.length,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.label,
                      isScrollable: true,
                      indicatorColor: Colors.transparent,
                      dividerColor: Colors.transparent,
                      overlayColor: WidgetStateProperty.all<Color>(Colors.transparent),
                      //labelPadding: EdgeInsets.zero,
                      tabs: vm.filteredMenu.map((filteredItem) {
                        return Tab(
                          child: SizedBox(
                            width: 170,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    filteredItem.isSelected
                                        ? const Color(0xFF005B8D)
                                        : const Color(0xFFFFFFFF),
                                    BlendMode.srcIn,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/svg_images/white_arrow.svg',
                                    width: 250,
                                    height: 35,
                                  ),
                                ),
                                Positioned(
                                  child: Text(
                                    filteredItem.parameter, // Set tab text dynamically
                                    style: TextStyle(
                                      color: filteredItem.isSelected ? Colors.white : Colors.black,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onTap: (index) {
                        vm.menuOnChange(index); // Correct way to call the function
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TabBarView(
                        children: vm.filteredMenu.map((filteredItem) {
                          switch (filteredItem.parameter) {
                            case "General":
                              return Padding(
                                padding: const EdgeInsets.only(left: 10, right: 10),
                                child: GridView.builder(
                                  itemCount: vm.userConstant.constant.generalMenu.length,
                                  gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                    MediaQuery.sizeOf(context).width > 1350? 3 : 2,
                                    crossAxisSpacing: 5.0,
                                    mainAxisSpacing: 5.0,
                                    childAspectRatio:
                                    MediaQuery.sizeOf(context).width > 1350?
                                    MediaQuery.sizeOf(context).width /250:
                                    MediaQuery.sizeOf(context).width /175,
                                  ),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return Card(
                                      color: Colors.white,
                                      elevation: 1,
                                      child: Padding(
                                        padding:
                                        const EdgeInsets.only(top: 10),
                                        child: ListTile(
                                          title: Text(vm
                                              .userConstant
                                              .constant
                                              .generalMenu[index]
                                              .title),
                                          trailing: vm
                                              .userConstant
                                              .constant
                                              .generalMenu[index]
                                              .widgetTypeId ==
                                              1
                                              ? SizedBox(
                                            width: 75,
                                            child: TextField(
                                              controller:
                                              vm.txtEdControllers[
                                              index],
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                              keyboardType:
                                              TextInputType
                                                  .number,
                                              textAlign:
                                              TextAlign.right,
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight
                                                      .bold),
                                              decoration:
                                              const InputDecoration(
                                                border:
                                                InputBorder.none,
                                                hintText: "value",
                                              ),
                                              onChanged: (value) {
                                                vm.updateGeneralValve(
                                                    index,
                                                    value,
                                                    'general');
                                              },
                                            ),
                                          )
                                              : vm
                                              .userConstant
                                              .constant
                                              .generalMenu[
                                          index]
                                              .widgetTypeId ==
                                              2
                                              ? Transform.scale(
                                            scale: 0.8,
                                            child: Tooltip(
                                              message: vm.userConstant.constant.generalMenu[index].value
                                                  ? 'Disable': 'Enable',
                                              child: Switch(
                                                hoverColor: Theme.of(context).primaryColor,
                                                activeColor: Theme.of(context).primaryColorLight,
                                                value: vm.userConstant.constant.generalMenu[index].value,
                                                onChanged:
                                                    (value) {
                                                  vm.updateGeneralSwitch(index,
                                                      !(vm.userConstant.constant.generalMenu[index].value as bool), 'general');
                                                },
                                              ),
                                            ),
                                          )
                                              : TextButton(
                                              onPressed: () {
                                                vm.showDurationInputDialog(
                                                    context,
                                                    vm.userConstant.constant.generalMenu[index].value, index, 'general');
                                              },
                                              child: Text(vm.userConstant.constant.generalMenu[index].value)),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );

                            case "Valve":
                              return vm.userConstant.constant.valveList!.isNotEmpty?
                              DataTable2(
                                border: const TableBorder(
                                  top: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  bottom: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  left: BorderSide(
                                      color: Color(0xFFDFE0E1),
                                      width: 1),
                                  right: BorderSide(
                                      color: Color(0xFFDFE0E1),
                                      width: 1),
                                ),
                                columnSpacing: 12,
                                minWidth: 1020,
                                dataRowHeight: 45.0,
                                headingRowHeight: 40,
                                headingRowColor:
                                WidgetStateProperty.all(
                                    const Color(0xFFFDFDFD)),
                                columns: const [
                                  DataColumn(
                                      label: Center(child: Text('Valve Name'))),
                                  DataColumn(label: Center(child: Text('Nominal Flow (I/hr)'))),
                                  DataColumn(label: Center(child: Text('Fill Up Delay'))),
                                ],
                                rows: List.generate(
                                    vm.userConstant.constant.valveList!.length, (index) {
                                  return DataRow(
                                    color: WidgetStateProperty
                                        .resolveWith<Color?>(
                                          (Set<WidgetState> states) {
                                        return index.isEven
                                            ? const Color(0xFFF6F6F6) : const Color(0xFFFDFDFD);
                                      },
                                    ),
                                    cells: [
                                      DataCell(Center(
                                        child: Text(
                                          vm.userConstant.constant.valveList![index].name,
                                          style: const TextStyle(
                                              color: Color(0xFF005B8D)),
                                        ),
                                      )),
                                      DataCell(Center(child: SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: vm.txtEdControllersNF[index],
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly
                                          ],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: "Enter value",
                                              hintStyle: TextStyle(color: Colors.grey)),
                                          onChanged: (value) {
                                            vm.updateGeneralValve(index, value, 'value');
                                          },
                                        ),
                                      ))),
                                      DataCell(Center(
                                          child: TextButton(
                                              onPressed: () {
                                                vm.showDurationInputDialog(
                                                    context,
                                                    vm.userConstant.constant.valveList![index].duration, index, 'valve');
                                              },
                                              child: Text(vm.userConstant.constant.valveList![index].duration)))),
                                    ],
                                  );
                                }),
                              ):
                              const Center(child: Text("Valve Data not available"));

                            case "Pump":
                              return vm.userConstant.constant.pumpList!.isNotEmpty?
                              DataTable2(
                                border: const TableBorder(
                                  top: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  bottom: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  left: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  right: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                ),
                                columnSpacing: 12,
                                minWidth: 1020,
                                dataRowHeight: 45.0,
                                headingRowHeight: 40,
                                headingRowColor:
                                WidgetStateProperty.all(const Color(0xFFFDFDFD)),
                                columns: const [
                                  DataColumn(
                                      label: Center(child: Text('Pump Name'))),
                                  DataColumn(label: Center(child: Text('Pump Station'))),
                                  DataColumn(label: Center(child: Text('Control Gem'))),
                                ],
                                rows: List.generate(
                                    vm.userConstant.constant.pumpList!.length, (index) {
                                  return DataRow(
                                    color: WidgetStateProperty
                                        .resolveWith<Color?>((Set<WidgetState> states) {
                                      return index.isEven ? const Color(0xFFF6F6F6) : const Color(0xFFFDFDFD);
                                    },
                                    ),
                                    cells: [
                                      DataCell(Center(
                                        child: Text(
                                          vm.userConstant.constant.pumpList![index].name,
                                          style: const TextStyle(color: Color(0xFF005B8D)),
                                        ),
                                      )),
                                      DataCell(Center(
                                        child: Checkbox(
                                          value: vm.userConstant.constant.pumpList![index].pumpStation,
                                          onChanged: (bool? value) {
                                            vm.pumpStationOnChange(index, value!);
                                          },
                                        ),
                                      )),
                                      DataCell(Center(
                                        child: Checkbox(
                                          value: vm.userConstant.constant.pumpList![index].controlGem,
                                          onChanged: (bool? value) {
                                            vm.controlGemOnChange(index, value!);
                                          },
                                        ),
                                      )),
                                    ],
                                  );
                                }),
                              ):
                              const Center(child: Text("Pump Data not available"));

                            case "Main Valve":
                              return vm.userConstant.constant.mainValveList!.isNotEmpty?
                              DataTable2(
                                border: const TableBorder(
                                  top: BorderSide(
                                      color: Color(0xFFDFE0E1),
                                      width: 1),
                                  bottom: BorderSide(
                                      color: Color(0xFFDFE0E1),
                                      width: 1),
                                  left: BorderSide(
                                      color: Color(0xFFDFE0E1),
                                      width: 1),
                                  right: BorderSide(
                                      color: Color(0xFFDFE0E1),
                                      width: 1),
                                ),
                                columnSpacing: 12,
                                horizontalMargin: 12,
                                minWidth: 1020,
                                headingRowColor:
                                MaterialStateProperty.all(
                                    const Color(0xFFFDFDFD)),
                                columns: const [
                                  DataColumn(
                                    label: Center(
                                      child: Text('Main Valve', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center,),),),
                                  DataColumn(
                                    label: Center(child: Text('Mode', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center,),),),
                                  DataColumn(
                                    label: Center(child: Text('Delay', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center,),),),
                                ],

                                rows: List.generate(
                                    vm.userConstant.constant.mainValveList!.length, (index) {
                                  return DataRow(
                                      color: WidgetStateProperty
                                          .resolveWith<Color?>(
                                            (Set<WidgetState>states) {
                                          return index.isEven ? const Color(0xFFF6F6F6) : const Color(0xFFFDFDFD); // Alternating row colors
                                        },
                                      ),
                                      cells: [
                                        DataCell(Center(child: Text(
                                          vm.userConstant.constant.mainValveList![index].name,
                                          style: const TextStyle(
                                              color: Color(0xFF005B8D)),))),
                                        DataCell(
                                          Center(
                                              child: PopupMenuButton<String>(
                                                onSelected: (String selectedValue) {
                                                  vm.ddOnChange(index, selectedValue, 'mainValve');
                                                },
                                                itemBuilder: (BuildContext context) {
                                                  return ['No Delay', 'Open before', 'Open after']
                                                      .map((String value) => PopupMenuItem<String>(
                                                    value: value,
                                                    height: 30,
                                                    child: Row(
                                                      children: [
                                                        const SizedBox(width: 8),
                                                        Text(value, style: const TextStyle(fontSize: 17)),
                                                      ],
                                                    ),
                                                  ))
                                                      .toList();
                                                },
                                                child: Text(
                                                  vm.userConstant.constant.mainValveList![index].delay,
                                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                                ),
                                              )

                                          ),
                                        ),
                                        DataCell(Center(
                                            child: TextButton(
                                                onPressed: () {
                                                  vm.showDurationInputDialog(
                                                      context, vm.userConstant.constant.mainValveList![index].duration, index, 'mainValve');
                                                },
                                                child: Text(vm.userConstant.constant.mainValveList![index].duration)))),


                                      ]);
                                }).toList(),
                              ):
                              const Center(child: Text("Main Valve Data not available"));

                            case "Irrigation Line":
                              return vm.userConstant.constant.irrigationLineList!.isNotEmpty ?
                              DataTable2(
                                border: const TableBorder(
                                  top: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  bottom: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  left: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  right: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                ),
                                headingRowColor: MaterialStateProperty.all(const Color(0xFFFDFDFD)),
                                columnSpacing: 12,
                                horizontalMargin: 12,
                                minWidth: 1020,
                                columns: const [
                                  DataColumn(label: Center(child: Text('Irrigation Line',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,)))),
                                  DataColumn(label: Center(child: Text('Low Flow Delay',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,)))),
                                  DataColumn(label: Center(child: Text('High Flow Delay',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,)))),
                                  DataColumn(label: Center(child: Text('Low Flow Action',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,)))),
                                  DataColumn(label: Center(child: Text('High Flow Action',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,)))),
                                ],

                                rows: List.generate(  vm.userConstant.constant.irrigationLineList!.length, (index) {
                                  return DataRow(
                                      color: MaterialStateProperty.resolveWith<Color?>(
                                            (Set<WidgetState> states) {
                                          return index.isEven ? const Color(0xFFF6F6F6) : const Color(0xFFFDFDFD) ; // Alternating row colors
                                        },
                                      ),
                                      cells: [
                                        DataCell(Center(child: Text( vm.userConstant.constant.irrigationLineList![index].name,style: const TextStyle(color: Color(0xFF005B8D)),))), // Center text
                                        DataCell(Center(
                                            child: TextButton(
                                                onPressed: () {
                                                  vm.showDurationInputDialog(context, vm.userConstant.constant.irrigationLineList![index].lowFlowDelay, index, 'irrigateLine_lfd');
                                                },
                                                child: Text(vm.userConstant.constant.irrigationLineList![index].lowFlowDelay)))),
                                        DataCell(Center(
                                            child: TextButton(
                                                onPressed: () {
                                                  vm.showDurationInputDialog(
                                                      context, vm.userConstant.constant.irrigationLineList![index].highFlowDelay, index, 'irrigateLine_hfd');
                                                },
                                                child: Text(vm.userConstant.constant.irrigationLineList![index].highFlowDelay)))),
                                        DataCell(
                                          Center(
                                              child: PopupMenuButton<String>(
                                                onSelected: (String selectedValue) {
                                                  vm.lowFlowAction(index, selectedValue);
                                                },
                                                itemBuilder: (BuildContext context) {
                                                  return ['Ignore', 'Do Next', 'Wait']
                                                      .map((String value) => PopupMenuItem<String>(
                                                    value: value,
                                                    height: 30,
                                                    child: Row(
                                                      children: [
                                                        const SizedBox(width: 8),
                                                        Text(value, style: const TextStyle(fontSize: 17)),
                                                      ],
                                                    ),
                                                  ))
                                                      .toList();
                                                },
                                                child: Text(
                                                  vm.userConstant.constant.irrigationLineList![index].lowFlowAction,
                                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                                ),
                                              )

                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                              child: PopupMenuButton<String>(
                                                onSelected: (String selectedValue) {
                                                  vm.highFlowAction(index, selectedValue);
                                                },
                                                itemBuilder: (BuildContext context) {
                                                  return ['Ignore', 'Do Next', 'Wait']
                                                      .map((String value) => PopupMenuItem<String>(
                                                    value: value,
                                                    height: 30,
                                                    child: Row(
                                                      children: [
                                                        const SizedBox(width: 8),
                                                        Text(value, style: const TextStyle(fontSize: 17)),
                                                      ],
                                                    ),
                                                  ))
                                                      .toList();
                                                },
                                                child: Text(
                                                  vm.userConstant.constant.irrigationLineList![index].highFlowAction,
                                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                                ),
                                              )

                                          ),
                                        )
                                      ]);
                                }),
                              ) :
                              const Center(child: Text("Irrigation Line Data not available"));

                            case "Water Meter":
                              return vm.userConstant.constant.waterMeterList!.isNotEmpty?
                              DataTable2(
                                border: const TableBorder(
                                  top: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  bottom: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  left: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  right: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                ),
                                headingRowColor: MaterialStateProperty.all(const Color(0xFFFDFDFD)),
                                columnSpacing: 12,
                                horizontalMargin: 12,
                                minWidth: 1020,
                                columns: const [
                                  DataColumn(label: Center(child: Text('Name',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,)))),
                                  DataColumn(label: Center(child: Text('Ratio(I/pulse',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,)))),
                                ],

                                rows: List.generate( vm.userConstant.constant.waterMeterList!.length, (index) {
                                  return DataRow(
                                      color: MaterialStateProperty.resolveWith<Color?>(
                                            (Set<MaterialState> states) {
                                          return index.isEven ? const Color(0xFFF6F6F6) : const Color(0xFFFDFDFD) ; // Alternating row colors
                                        },
                                      ),
                                      cells: [
                                        DataCell(Center(child: Text(vm.userConstant.constant.waterMeterList![index].name,style: const TextStyle(color: Color(0xFF005B8D)),))), // Center text
                                        DataCell(Center(
                                            child: TextField(
                                              controller: vm.txtEdControllersRatio[index],
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly
                                              ],
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                              decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: "Enter ratio",
                                                  hintStyle: TextStyle(color: Colors.grey)),
                                              onChanged: (value) {
                                                vm.updateGeneralValve(index, value, 'ratio');
                                              },
                                            ))),
                                      ]);
                                }),
                              ):
                              const Center(child: Text("Water Meter Data not available"));

                            case "Alarm":
                              return vm.userConstant.constant.criticalAlarm!.isNotEmpty?
                              DataTable2(
                                border: const TableBorder(
                                  top: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  bottom: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  left: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  right: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                ),
                                columnSpacing: 12,
                                minWidth: 1020,
                                dataRowHeight: 45.0,
                                headingRowHeight: 40,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFFDFDFD)),
                                columns: const [
                                  DataColumn2(label: Text('Alarm Type',style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal,)), size: ColumnSize.M),
                                  DataColumn2(label: Text('Scan Time',style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal,)), size: ColumnSize.S),
                                  DataColumn(label: Text('Alarm On Status',style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal,))),
                                  DataColumn(label: Text('Reset After Irrigation',style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal,))),
                                  DataColumn(label: Text('Auto Reset Duration',style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal,))),
                                  DataColumn(label: Text('Threshold',style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal,))),
                                  DataColumn(label: Text('Units',style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal,))),
                                ],
                                rows: List<DataRow>.generate(vm.userConstant.constant.criticalAlarm!.length, (index) {
                                  var alarm = vm.userConstant.constant.criticalAlarm![index];
                                  return DataRow(
                                      color: WidgetStateProperty.resolveWith<Color?>(
                                            (Set<WidgetState> states) {
                                          return index.isEven ? const Color(0xFFF6F6F6) : const Color(0xFFFDFDFD) ; // Alternating row colors
                                        },
                                      ),
                                      cells: [
                                        DataCell(Text(
                                          alarm.name,
                                          style: TextStyle(color: alarm.type == 'Normal' ? Colors.green : Colors.red),
                                        )),
                                        DataCell(Center(child: TextButton(
                                            onPressed: () {
                                              vm.showDurationInputDialog(
                                                  context, vm.userConstant.constant.criticalAlarm![index].scanTime, index, 'scanTime');
                                            },
                                            child: Text(vm.userConstant.constant.criticalAlarm![index].scanTime)))),
                                        DataCell(
                                          Center(
                                            child: PopupMenuButton<String>(
                                              onSelected: (String selectedValue) {
                                                vm.ddOnChange(index, selectedValue, 'criticalAlarm');
                                              },
                                              itemBuilder: (BuildContext context) {
                                                return ['Do Nothing', 'Stop Irrigation', 'Stop Fertigation', 'Skip Irrigation']
                                                    .map((String value) => PopupMenuItem<String>(value: value,
                                                  height: 30,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 12.29,
                                                        height: 12.29,
                                                        decoration: const BoxDecoration(
                                                          color: Colors.redAccent,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),/*userConstant.constant.criticalAlarm![index].alarmOnStatus*/
                                                      Text(value, style: const TextStyle(fontSize: 17)),
                                                    ],
                                                  ),
                                                ))
                                                    .toList();
                                              },
                                              icon: null,
                                              child: Center(
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      alarm.alarmOnStatus,
                                                      style: const TextStyle(
                                                        decoration: TextDecoration.underline,
                                                        decorationColor: Colors.black,
                                                        decorationThickness: 1.0,
                                                        fontSize: 17,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      width: 12.29,
                                                      height: 12.29,
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: PopupMenuButton<String>(
                                              onSelected: (String selectedValue) {
                                                vm.ddOnChange(index, selectedValue, 'resetAfterIrrigation');
                                              },
                                              itemBuilder: (BuildContext context) {
                                                return ['Yes', 'No']
                                                    .map((String value) => PopupMenuItem<String>(
                                                  value: value,
                                                  height: 30,
                                                  child: Text(value, style: TextStyle(fontSize: 17),),
                                                )).toList();
                                              },
                                              icon: null,
                                              child: Center(
                                                child: Text(
                                                  alarm.resetAfterIrrigation,
                                                  style: const TextStyle(
                                                    decoration: TextDecoration.underline,
                                                    decorationColor: Colors.black,
                                                    decorationThickness: 1.0,
                                                    fontSize: 17,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(Center(child: TextButton(
                                            onPressed: () {
                                              vm.showDurationInputDialog(
                                                  context, vm.userConstant.constant.criticalAlarm![index].autoResetDuration, index, 'autoResetDuration');
                                            },
                                            child: Text(vm.userConstant.constant.criticalAlarm![index].autoResetDuration)))),
                                        DataCell(Center(child: SizedBox(
                                          width: 100,
                                          child: TextField(
                                            controller: vm.txtEdControllersThreshold[index],
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly
                                            ],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                hintText: "Enter Threshold",
                                                hintStyle: TextStyle(color: Colors.grey)),
                                            onChanged: (value) {
                                              vm.updateGeneralValve(index, value, 'Threshold');
                                            },
                                          ),
                                        ))),
                                        DataCell(Text(
                                          alarm.unit,
                                          style: TextStyle(color: alarm.type == 'Normal' ? Colors.green : Colors.red),
                                        )),
                                      ]);
                                }),
                              ):
                              const Center(child: Text("Critical Alarm Data not available"));

                            case "Global Alarm":
                              return vm.userConstant.constant.globalAlarm!.isNotEmpty?
                              GridView.builder(
                                itemCount: vm.userConstant.constant.globalAlarm!.length,
                                gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                  MediaQuery.sizeOf(context).width >
                                      1350
                                      ? 3
                                      : 2,
                                  crossAxisSpacing: 16.0,
                                  mainAxisSpacing: 16.0,
                                  childAspectRatio:
                                  MediaQuery.sizeOf(context).width >
                                      1350
                                      ? MediaQuery.sizeOf(context)
                                      .width /
                                      250
                                      : MediaQuery.sizeOf(context)
                                      .width /
                                      750,
                                ),
                                itemBuilder:
                                    (BuildContext context, int index) {
                                  return Card(
                                    color: Colors.white,
                                    elevation: 1,
                                    child: Padding(
                                      padding:
                                      const EdgeInsets.only(top: 10),
                                      child: ListTile(
                                        title: Text(vm.userConstant.constant.globalAlarm![index].name),
                                        trailing: Transform.scale(
                                          scale: 0.8,
                                          child: Tooltip(
                                            message: vm.userConstant.constant.globalAlarm![index].value
                                                ? 'Disable': 'Enable',
                                            child: Switch(
                                              hoverColor: Theme.of(context).primaryColor,
                                              activeColor: Theme.of(context).primaryColorLight,
                                              value: vm.userConstant.constant.globalAlarm![index].value,
                                              onChanged:
                                                  (value) {
                                                vm.updateGeneralSwitch(index,!vm.userConstant.constant.globalAlarm![index].value, 'globalAlarm');
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ):
                              const Center(child: Text("Global Alarm Data not available"));

                            case "Level Sensor":
                              return vm.userConstant.constant.levelSensor!.isNotEmpty?
                              DataTable2(
                                border: const TableBorder(
                                  top: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  bottom: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  left: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  right: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                ),
                                columnSpacing: 12,
                                minWidth: 1020,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFFDFDFD)),
                                columns: const [
                                  DataColumn(label: Text('Sensor',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                  DataColumn(label: Text('High Low',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                  DataColumn(label: Text('Units',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                  DataColumn(label: Text('Base',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                  DataColumn(label: Text('Minimum',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                  DataColumn(label: Text('Maximum',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                  DataColumn(label: Text('Height (m)',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                ],
                                rows: vm.userConstant.constant.levelSensor!.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  LevelSensor sensor = entry.value;

                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>(
                                          (Set<WidgetState> states) {
                                        return index.isEven ? const Color(0xFFF6F6F6) : const Color(0xFFFDFDFD);
                                      },
                                    ),
                                    cells: [
                                      DataCell(Text(sensor.name, style: const TextStyle(color: Color(0xFF005B8D)))),
                                      DataCell(Center(
                                          child: PopupMenuButton<String>(
                                            onSelected: (String selectedValue) {
                                              vm.ddOnChange(index, selectedValue, 'levelSensor');
                                            },
                                            itemBuilder: (BuildContext context) {
                                              return ['--', 'Primary', 'Secondary']
                                                  .map((String value) => PopupMenuItem<String>(
                                                value: value,
                                                height: 30,
                                                child: Row(
                                                  children: [
                                                    const SizedBox(width: 8),
                                                    Text(value, style: const TextStyle(fontSize: 17)),
                                                  ],
                                                ),
                                              ))
                                                  .toList();
                                            },
                                            child: Text(
                                              vm.userConstant.constant.levelSensor![index].highLow,
                                              style: const TextStyle(fontSize: 16, color: Colors.black),
                                            ),
                                          )

                                      )),
                                      DataCell(Center(
                                          child: PopupMenuButton<String>(
                                            onSelected: (String selectedValue) {
                                              vm.ddOnChange(index, selectedValue, 'units');
                                            },
                                            itemBuilder: (BuildContext context) {
                                              return ['--', 'Bar', 'ds/m']
                                                  .map((String value) => PopupMenuItem<String>(
                                                value: value,
                                                height: 30,
                                                child: Row(
                                                  children: [
                                                    const SizedBox(width: 8),
                                                    Text(value, style: const TextStyle(fontSize: 17)),
                                                  ],
                                                ),
                                              ))
                                                  .toList();
                                            },
                                            child: Text(
                                              vm.userConstant.constant.levelSensor![index].units,
                                              style: const TextStyle(fontSize: 16, color: Colors.black),
                                            ),
                                          )

                                      )),
                                      DataCell(Center(
                                          child: PopupMenuButton<String>(
                                            onSelected: (String selectedValue) {
                                              vm.ddOnChange(index, selectedValue, 'base');
                                            },
                                            itemBuilder: (BuildContext context) {
                                              return ['--', 'Current', 'Voltage']
                                                  .map((String value) => PopupMenuItem<String>(
                                                value: value,
                                                height: 30,
                                                child: Row(
                                                  children: [
                                                    const SizedBox(width: 8),
                                                    Text(value, style: const TextStyle(fontSize: 17)),
                                                  ],
                                                ),
                                              ))
                                                  .toList();
                                            },
                                            child: Text(
                                              vm.userConstant.constant.levelSensor![index].base,
                                              style: const TextStyle(fontSize: 16, color: Colors.black),
                                            ),
                                          )

                                      )),
                                      DataCell(Center(child: SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: vm.txtEdControllersMin[index],
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly
                                          ],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: "Enter value",
                                              hintStyle: TextStyle(color: Colors.grey)),
                                          onChanged: (value) {
                                            vm.updateGeneralValve(index, value, 'levelSensorMin');
                                          },
                                        ),
                                      ))),
                                      DataCell(Center(child: SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: vm.txtEdControllersMax[index],
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly
                                          ],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: "Enter value",
                                              hintStyle: TextStyle(color: Colors.grey)),
                                          onChanged: (value) {
                                            vm.updateGeneralValve(index, value, 'levelSensorMax');
                                          },
                                        ),
                                      ))),
                                      DataCell(Center(child: SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: vm.txtEdControllersHeight[index],
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly
                                          ],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: "Enter value",
                                              hintStyle: TextStyle(color: Colors.grey)),
                                          onChanged: (value) {
                                            vm.updateGeneralValve(index, value, 'levelSensorHeight');
                                          },
                                        ),
                                      ))),
                                    ],
                                  );
                                }).toList(),
                              ):
                              const Center(child: Text("Level Sensor Data not available"));

                            case "Moisture Sensor":
                              return vm.userConstant.constant.moistureSensor!.isNotEmpty?
                              DataTable2(
                                border: const TableBorder(
                                  top: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  bottom: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  left: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                  right: BorderSide(color: Color(0xFFDFE0E1), width: 1),
                                ),
                                columnSpacing: 12,
                                minWidth: 1020,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFFDFDFD)),
                                columns: const [
                                  DataColumn(label: Text('Sensor',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                  DataColumn(label: Text('High Low',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                  DataColumn(label: Text('Units',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                  DataColumn(label: Text('Base',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                  DataColumn(label: Text('Minimum',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                  DataColumn(label: Text('Maximum',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))),
                                ],
                                rows: vm.userConstant.constant.moistureSensor!.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  MoistureSensor sensor = entry.value;

                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>(
                                          (Set<WidgetState> states) {
                                        return index.isEven ? const Color(0xFFF6F6F6) : const Color(0xFFFDFDFD);
                                      },
                                    ),
                                    cells: [
                                      DataCell(Text(sensor.name, style: const TextStyle(color: Color(0xFF005B8D)))),
                                      DataCell(Center(
                                          child: PopupMenuButton<String>(
                                            onSelected: (String selectedValue) {
                                              vm.ddOnChange(index, selectedValue, 'highLowMS');
                                            },
                                            itemBuilder: (BuildContext context) {
                                              return ['--', 'Primary', 'Secondary']
                                                  .map((String value) => PopupMenuItem<String>(
                                                value: value,
                                                height: 30,
                                                child: Row(
                                                  children: [
                                                    const SizedBox(width: 8),
                                                    Text(value, style: const TextStyle(fontSize: 17)),
                                                  ],
                                                ),
                                              ))
                                                  .toList();
                                            },
                                            child: Text(
                                              vm.userConstant.constant.moistureSensor![index].highLow,
                                              style: const TextStyle(fontSize: 16, color: Colors.black),
                                            ),
                                          )

                                      )),
                                      DataCell(Center(
                                          child: PopupMenuButton<String>(
                                            onSelected: (String selectedValue) {
                                              vm.ddOnChange(index, selectedValue, 'unitsMS');
                                            },
                                            itemBuilder: (BuildContext context) {
                                              return ['--', 'Bar', 'ds/m']
                                                  .map((String value) => PopupMenuItem<String>(
                                                value: value,
                                                height: 30,
                                                child: Row(
                                                  children: [
                                                    const SizedBox(width: 8),
                                                    Text(value, style: const TextStyle(fontSize: 17)),
                                                  ],
                                                ),
                                              ))
                                                  .toList();
                                            },
                                            child: Text(
                                              vm.userConstant.constant.moistureSensor![index].units,
                                              style: const TextStyle(fontSize: 16, color: Colors.black),
                                            ),
                                          )

                                      )),
                                      DataCell(Center(
                                          child: PopupMenuButton<String>(
                                            onSelected: (String selectedValue) {
                                              vm.ddOnChange(index, selectedValue, 'baseMS');
                                            },
                                            itemBuilder: (BuildContext context) {
                                              return ['--', 'Current', 'Voltage']
                                                  .map((String value) => PopupMenuItem<String>(
                                                value: value,
                                                height: 30,
                                                child: Row(
                                                  children: [
                                                    const SizedBox(width: 8),
                                                    Text(value, style: const TextStyle(fontSize: 17)),
                                                  ],
                                                ),
                                              ))
                                                  .toList();
                                            },
                                            child: Text(
                                              vm.userConstant.constant.moistureSensor![index].base,
                                              style: const TextStyle(fontSize: 16, color: Colors.black),
                                            ),
                                          )

                                      )),
                                      DataCell(Center(child: SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: vm.txtEdControllersMinMS[index],
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly
                                          ],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: "Enter value",
                                              hintStyle: TextStyle(color: Colors.grey)),
                                          onChanged: (value) {
                                            vm.updateGeneralValve(index, value, 'moistureSensorMinMS');
                                          },
                                        ),
                                      ))),
                                      DataCell(Center(child: SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: vm.txtEdControllersMaxMS[index],
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly
                                          ],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: "Enter value",
                                              hintStyle: TextStyle(color: Colors.grey)),
                                          onChanged: (value) {
                                            vm.updateGeneralValve(index, value, 'moistureSensorMaxMS');
                                          },
                                        ),
                                      ))),
                                    ],
                                  );
                                }).toList(),
                              ):
                              const Center(child: Text("Moisture Sensor Data not available"));

                            case "Fertilizer":
                              return vm.userConstant.constant.fertilization!.isNotEmpty
                                  ? SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  children: vm.userConstant.constant.fertilization!.asMap().entries.map((entry) {
                                    int siteIndex = entry.key;
                                    ConstantFertilizerSite site = entry.value;

                                    bool sensorAvail = site.ecSensor.isNotEmpty || site.phSensor.isNotEmpty? true : false;
                                    double sensorLength = 50.0;
                                    if(sensorAvail){
                                      sensorLength = sensorLength + 50;
                                    }

                                    return Container(
                                      width: MediaQuery.sizeOf(context).width - 180,
                                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), // Adds spacing
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(color: Colors.grey.shade300, blurRadius: 4, spreadRadius: 2)
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 1,
                                              child: SizedBox(
                                                height: (site.channel.length*50)+50,
                                                child: Center(
                                                  child: Text(
                                                    site.name,
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              )
                                          ),
                                          Container(width: 0.5, height: ((site.channel.length+site.ecSensor.length+site.phSensor.length)*50) + sensorLength, color:  Colors.grey,),
                                          Expanded(
                                            flex: 6,
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                        flex: 2,
                                                        child: SizedBox(
                                                          height: (site.channel.length*50)+50,
                                                          child: DataTable(
                                                            columnSpacing: 10,
                                                            border: const TableBorder(
                                                              horizontalInside: BorderSide.none,
                                                              verticalInside: BorderSide.none,
                                                            ),
                                                            columns: const [
                                                              DataColumn(label: Text("Minimal On Time")),
                                                              DataColumn(label: Text("Minimal Off Time")),
                                                              DataColumn(label: Text("Booster Off delay")),
                                                            ],
                                                            rows: List.generate(1, (index) {
                                                              return DataRow(cells: [
                                                                DataCell(TextButton(
                                                                    onPressed: () {
                                                                      vm.showDurationInputDialog(
                                                                          context,
                                                                          vm.userConstant.constant.valveList![index].duration, index, 'minimalOnTime');
                                                                    },
                                                                    child: Text(site.minimalOnTime))),
                                                                DataCell(TextButton(
                                                                    onPressed: () {
                                                                      vm.showDurationInputDialog(
                                                                          context,
                                                                          vm.userConstant.constant.valveList![index].duration, index, 'minimalOffTime');
                                                                    },
                                                                    child: Text(site.minimalOffTime))),
                                                                DataCell(TextButton(
                                                                    onPressed: () {
                                                                      vm.showDurationInputDialog(
                                                                          context,
                                                                          vm.userConstant.constant.valveList![index].duration, index, 'boosterDelay');
                                                                    },
                                                                    child: Text(site.boosterDelay))),
                                                              ]);
                                                            }).toList(),
                                                          ),
                                                        )
                                                    ),
                                                    Container(width: 0.5, height: (site.channel.length*50)+50, color:  Colors.grey,),// Spacing between title and table
                                                    Expanded(
                                                      flex: 4,
                                                      child: DataTable(
                                                        columnSpacing: 10,
                                                        border: const TableBorder(
                                                          horizontalInside: BorderSide.none,
                                                          verticalInside: BorderSide.none,
                                                        ),
                                                        columns: const [
                                                          DataColumn(label: Text("Name")),
                                                          DataColumn(label: Text("Ratio (L/pulse)")),
                                                          DataColumn(label: Text("Shortest Pulse")),
                                                          DataColumn(label: Text("Nominal Flow (L/hr)")),
                                                          DataColumn(label: Text("Injector Mode")),
                                                        ],
                                                        rows: site.channel.asMap().entries.map<DataRow>((entry) {
                                                          int index = entry.key; // Get index
                                                          var channel = entry.value; // Get channel data

                                                          return DataRow(cells: [
                                                            DataCell(Text(channel.name)),
                                                            DataCell(SizedBox(
                                                              width: 100,
                                                              child: TextField(
                                                                controller: vm.txtEdControllersCheRatio[index],
                                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                keyboardType: TextInputType.number,
                                                                textAlign: TextAlign.center,
                                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                                decoration: const InputDecoration(
                                                                  border: InputBorder.none,
                                                                  hintText: "Enter value",
                                                                  hintStyle: TextStyle(color: Colors.grey),
                                                                ),
                                                                onChanged: (value) {
                                                                  vm.updateGeneralValve(index, value, 'ratioTxtValue');
                                                                },
                                                              ),
                                                            )),
                                                            DataCell(SizedBox(
                                                              width: 100,
                                                              child: TextField(
                                                                controller: vm.txtEdControllersChePulse[index],
                                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                keyboardType: TextInputType.number,
                                                                textAlign: TextAlign.center,
                                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                                decoration: const InputDecoration(
                                                                  border: InputBorder.none,
                                                                  hintText: "Pulse value",
                                                                  hintStyle: TextStyle(color: Colors.grey),
                                                                ),
                                                                onChanged: (value) {
                                                                  vm.updateGeneralValve(index, value, 'pulseTxtValue');
                                                                },
                                                              ),
                                                            )),
                                                            DataCell(SizedBox(
                                                              width: 100,
                                                              child: TextField(
                                                                controller: vm.txtEdControllersCheNF[index],
                                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                keyboardType: TextInputType.number,
                                                                textAlign: TextAlign.center,
                                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                                decoration: const InputDecoration(
                                                                  border: InputBorder.none,
                                                                  hintText: "Nominal flow",
                                                                  hintStyle: TextStyle(color: Colors.grey),
                                                                ),
                                                                onChanged: (value) {
                                                                  vm.updateGeneralValve(index, value, 'nmlFlowTxtValue');
                                                                },
                                                              ),
                                                            )),
                                                            DataCell(Center(
                                                                child: PopupMenuButton<String>(
                                                                  onSelected: (String selectedValue) {
                                                                    vm.ddOnChange(index, selectedValue, 'Injector Mode');
                                                                  },
                                                                  itemBuilder: (BuildContext context) {
                                                                    return ['Concentration', 'Ec controlled', 'Ph controlled', 'Regular']
                                                                        .map((String value) => PopupMenuItem<String>(
                                                                      value: value,
                                                                      height: 30,
                                                                      child: Row(
                                                                        children: [
                                                                          const SizedBox(width: 8),
                                                                          Text(value, style: const TextStyle(fontSize: 17)),
                                                                        ],
                                                                      ),
                                                                    ))
                                                                        .toList();
                                                                  },
                                                                  child: Text(
                                                                    channel.injectorMode,
                                                                    style: const TextStyle(fontSize: 16, color: Colors.black),
                                                                  ),
                                                                )

                                                            )),
                                                          ]);
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                sensorAvail?const Divider(height: 0):const SizedBox(),
                                                sensorAvail?Row(
                                                  children: [
                                                    Expanded(
                                                      child: DataTable(
                                                        columnSpacing: 0,
                                                        border: const TableBorder(
                                                          horizontalInside: BorderSide.none,
                                                          verticalInside: BorderSide.none,
                                                        ),
                                                        headingRowHeight: 40,
                                                        columns: const [
                                                          DataColumn(label: Text("Name")),
                                                          DataColumn(label: Center(child: Text("Control Cycle"))),
                                                          DataColumn(label: Center(child: Text("Delta"))),
                                                          DataColumn(label: Center(child: Text("Fine Tuning"))),
                                                          DataColumn(label: Center(child: Text("Coarse Tuning"))),
                                                          DataColumn(label: Center(child: Text("Deadband"))),
                                                          DataColumn(label: Center(child: Text("Integ"))),
                                                          DataColumn(label: Center(child: Text("Control Sensor"))),
                                                          DataColumn(label: Center(child: Text("Avg Filt Speed"))),
                                                          DataColumn(label: Center(child: Text("Percentage"))),
                                                        ],
                                                        rows: [
                                                          ...site.ecSensor.asMap().entries.map<DataRow>((entry) => buildDataRow(context, siteIndex, entry.key, entry.value,1, vm)),
                                                          ...site.phSensor.asMap().entries.map<DataRow>((entry) => buildDataRow(context, siteIndex, entry.key + site.ecSensor.length, entry.value,2, vm)),
                                                        ],

                                                      ),
                                                    ),
                                                  ],
                                                ):
                                                const SizedBox(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ):
                              const Center(child: Text("Fertilizer Data not available"));

                          }
                          return Center(child: Text("${filteredItem.parameter} Screen"));
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                MaterialButton(
                  color: Colors.green,
                  textColor: Colors.white,
                  onPressed: () {
                    vm.saveConstantData(context, customerId, controllerId, userId);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  DataRow buildDataRow(BuildContext context, int siteIndex, int sensorIndex, var value, int type, ConstantViewModel vm) {

    EcPh sensors = value;

    return DataRow(cells: [
      DataCell(Text(sensors.name)),
      DataCell(TextButton(
          onPressed: () {
            if(type==1){
              vm.showDurationInputDialog(
                  context, vm.userConstant.constant.fertilization![siteIndex].ecSensor[sensorIndex].controlCycle,
                  sensorIndex, 'controlCycle1_$siteIndex');
            }else{
              int sensorIndexFinal = sensorIndex - vm.userConstant.constant.fertilization![siteIndex].ecSensor.length;
              vm.showDurationInputDialog(
                  context, vm.userConstant.constant.fertilization![siteIndex].phSensor[sensorIndexFinal].controlCycle,
                  sensorIndexFinal, 'controlCycle2_$siteIndex');
            }
          },
          child: Text(sensors.controlCycle))),
      DataCell(buildTextField(vm.txtEdControllersEcPhDelta[sensorIndex], "value", (value) {
        if(type==1){
          vm.updateGeneralValve(sensorIndex, value, 'EcDelta_$siteIndex');
        }else{
          int sensorIndexFinal = sensorIndex - vm.userConstant.constant.fertilization![siteIndex].ecSensor.length;
          vm.updateGeneralValve(sensorIndexFinal, value, 'PhDelta_$siteIndex');
        }
      })),
      DataCell(buildTextField(vm.txtEdControllersEcPhFineTune[sensorIndex], "value", (value) {
        if(type==1){
          vm.updateGeneralValve(sensorIndex, value, 'EcFineTune_$siteIndex');
        }else{
          int sensorIndexFinal = sensorIndex - vm.userConstant.constant.fertilization![siteIndex].ecSensor.length;
          vm.updateGeneralValve(sensorIndexFinal, value, 'PhFineTune_$siteIndex');
        }

      })),
      DataCell(buildTextField(vm.txtEdControllersEcPhCoarse[sensorIndex], "value", (value) {
        if(type==1){
          vm.updateGeneralValve(sensorIndex, value, 'EcCoarse_$siteIndex');
        }else{
          int sensorIndexFinal = sensorIndex - vm.userConstant.constant.fertilization![siteIndex].ecSensor.length;
          vm.updateGeneralValve(sensorIndexFinal, value, 'PhCoarse_$siteIndex');
        }
      })),
      DataCell(buildTextField(vm.txtEdControllersEcPhDeadBand[sensorIndex], "value", (value) {
        if(type==1){
          vm.updateGeneralValve(sensorIndex, value, 'EcDeadBand_$siteIndex');
        }else{
          int sensorIndexFinal = sensorIndex - vm.userConstant.constant.fertilization![siteIndex].ecSensor.length;
          vm.updateGeneralValve(sensorIndexFinal, value, 'PhDeadBand_$siteIndex');
        }
      })),
      DataCell(TextButton(
          onPressed: () {
            if(type==1){
              vm.showDurationInputDialog(
                  context, vm.userConstant.constant.fertilization![siteIndex].ecSensor[sensorIndex].integ,
                  sensorIndex, 'integ1_$siteIndex');
            }
            else{
              int sensorIndexFinal = sensorIndex - vm.userConstant.constant.fertilization![siteIndex].ecSensor.length;
              vm.showDurationInputDialog(
                  context, vm.userConstant.constant.fertilization![siteIndex].phSensor[sensorIndexFinal].integ,
                  sensorIndexFinal, 'integ2_$siteIndex');
            }
          },
          child: Text(sensors.integ))),
      DataCell(Center(
          child: PopupMenuButton<String>(
            onSelected: (String selectedValue) {
              if(type==1){
                vm.ddOnChange(sensorIndex, selectedValue, 'EcCSensor_$siteIndex');
              }else{
                int sensorIndexFinal = sensorIndex - vm.userConstant.constant.fertilization![siteIndex].ecSensor.length;
                vm.ddOnChange(sensorIndexFinal, selectedValue, 'PhCSensor_$siteIndex');
              }
            },
            itemBuilder: (BuildContext context) {
              if(type==1){
                return ['Average', 'Ec 1', 'Ec 2']
                    .map((String value) => PopupMenuItem<String>(
                  value: value,
                  height: 30,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(value, style: const TextStyle(fontSize: 17)),
                    ],
                  ),
                ))
                    .toList();
              }else{
                return ['Average', 'Ph 1', 'Ph 2']
                    .map((String value) => PopupMenuItem<String>(
                  value: value,
                  height: 30,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(value, style: const TextStyle(fontSize: 17)),
                    ],
                  ),
                ))
                    .toList();
              }

            },
            child: Text(
              sensors.controlSensor,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          )

      )),
      DataCell(buildTextField(vm.txtEdControllersEcPhAvgFiltSpeed[sensorIndex], "value", (value) {
        if(type==1){
          vm.updateGeneralValve(sensorIndex, value, 'EcAvgFiltSpeed_$siteIndex');
        }else{
          int sensorIndexFinal = sensorIndex - vm.userConstant.constant.fertilization![siteIndex].ecSensor.length;
          vm.updateGeneralValve(sensorIndexFinal, value, 'PhAvgFiltSpeed_$siteIndex');
        }
      })),
      DataCell(buildTextField(vm.txtEdControllersEcPhPercentage[sensorIndex], "value", (value) {
        if(type==1){
          vm.updateGeneralValve(sensorIndex, value, 'EcPercentage_$siteIndex');
        }else{
          int sensorIndexFinal = sensorIndex - vm.userConstant.constant.fertilization![siteIndex].ecSensor.length;
          vm.updateGeneralValve(sensorIndexFinal, value, 'PhPercentage_$siteIndex');
        }
      })),

    ]);
  }

  /*final String controlCycle;
  final String delta;
  final String fineTuning;
  final String coarseTuning;
  final String deadband;
  final String integ;
  final String controlSensor;
  final String avgFiltSpeed;
  final String percentage;*/

  Widget buildTextField(TextEditingController controller, String hint, Function(String) onChanged) {
    return SizedBox(
      width: 100,
      child: TextField(
        controller: controller,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
