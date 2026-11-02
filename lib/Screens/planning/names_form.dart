import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/names_model.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/snack_bar.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';


class Names extends StatefulWidget {
  final int userID, customerID, controllerId, menuId;
  final String imeiNo;

  const Names({
    required this.userID,
    required this.customerID,
    required this.controllerId,
    required this.menuId,
    required this.imeiNo,
    super.key,
  });

  @override
  _NamesState createState() => _NamesState();
}

class _NamesState extends State<Names> {
  NamesConfigModel configModel = NamesConfigModel();
  List<String> uniqueObjectNames = [];
  var liveData;
  int selectedCategory = 0;
  late List<TextEditingController> _controllers;

  void getData() async {
    try {
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.getUserConfigMaker({
        "userId": widget.customerID,
        "controllerId": widget.controllerId,
      });

      final jsonData = jsonDecode(getUserDetails.body);
      if (jsonData['code'] == 200) {
        setState(() {
          configModel = NamesConfigModel.fromJson(jsonData['data']);
          uniqueObjectNames = (configModel.configObject ?? [])
              .map((obj) => obj.objectName ?? '')
              .toSet()
              .toList();

          _controllers = (configModel.configObject ?? [])
              .map((obj) => TextEditingController(text: obj.name ?? ""))
              .toList();
        });
      }
    } catch (e, stackTrace) {
      AppLog.log('Error overAll getData => ${e.toString()}');
      AppLog.log('trace overAll getData  => $stackTrace');
    }
  }

  @override
  void initState() {
    super.initState();
    _controllers = [];
    getData();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget getTabBarViewWidget() {
    List<String> listOfCategory = uniqueObjectNames;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (int i = 0; i < listOfCategory.length; i++)
                InkWell(
                  onTap: () {
                     setState(() {
                      selectedCategory = i;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    padding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: selectedCategory == i ? 12 : 10,
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
                      color: selectedCategory == i
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                    ),
                    child: Text(
                      listOfCategory[i],
                      style: TextStyle(
                        color: selectedCategory == i ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          height: 3,
          color: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  Widget buildTab(int selectedTabIndex) {
    if (selectedTabIndex < 0 || selectedTabIndex >= uniqueObjectNames.length) {
      return const Center(child: Text('No category selected'));
    }

    final filteredData = (configModel.configObject ?? [])
        .where((obj) => obj.objectName == uniqueObjectNames[selectedTabIndex])
        .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(80),
            1: FixedColumnWidth(120),
            2: FlexColumnWidth(),
          },
          children: [
             TableRow(
              decoration: const BoxDecoration(color: Colors.white),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'S.No',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Location',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Name',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            ...filteredData.asMap().entries.map((entry) {
              int index = entry.key;
              var data = entry.value;
              Color rowColor = (index % 2 == 0) ? Colors.grey[100]! : Colors.white;
              int originalIndex = (configModel.configObject ?? []).indexOf(data);

              return TableRow(
                decoration: BoxDecoration(color: rowColor),
                children: [
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Text(
                      data.sNo.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Text(
                      configModel.getNameBySNo(data.location ?? 0.0),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: TextFormField(
                      controller: _controllers[originalIndex],
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                         FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.!@#$%^&*()_+\-=\[\]{}|;:"<>,.?/`~]'))
                      ],
                      onChanged: (val) {
                        setState(() {
                          // bool nameExists = (configModel.configObject ?? []).any(
                          //         (element) => element.name == val && element != data);

                           bool nameExists = (configModel.configObject ?? []).any(
                                  (element) =>
                              element != data &&
                                  element.name?.trim().toLowerCase() == val.trim().toLowerCase() &&
                                  element.objectName == "Valve" &&
                                  element.location == data.location
                          );
                          if (nameExists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name Already Exists')),
                            );
                            // _controllers[originalIndex].text = data.name ?? "";
                          } else if (val.length > 15) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name length Maximum reached')),
                            );
                          } else if (val.isNotEmpty) {
                            AppLog.log("val->$val");
                            data.name = val;
                          }
                        });
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (configModel.configObject == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: kIsWeb ? null  : AppBar(title: const Text('Names'),),
      body: Column(
        children: [
          getTabBarViewWidget(),
          Expanded(
            child: buildTab(selectedCategory),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColorDark,
        foregroundColor: Colors.white,
        onPressed: () {
          setState(() {
            updateAllNames();
            updateUserNames();
          });
        },
        tooltip: 'Send',
        child: const Icon(Icons.send),
      ),
    );
  }

  updateUserNames() async {
     Map<String, dynamic> namesModelData = configModel.toJson();

    final Repository repository = Repository(HttpService());
    AppLog.log(namesModelData['configObject']);
    Map<String, dynamic> body = {
      "userId": widget.customerID,
      "controllerId": widget.controllerId,
      "configObject": namesModelData['configObject'],
      "waterSource": namesModelData['waterSource'],
      "pump": namesModelData['pump'],
      "filterSite": namesModelData['filterSite'],
      "fertilizerSite": namesModelData['fertilizerSite'],
      "irrigationLine": namesModelData['irrigationLine'],
      "moistureSensor": namesModelData['moistureSensor'],
      "createUser": widget.userID,
    };
     AppLog.log('body:-$body');

     var getUserDetails = await repository.updateUserNames(body);
       // AppLog.log('getUserDetails.body-:${getUserDetails.body}');
      final jsonDataResponsePut = json.decode(getUserDetails.body);
      GlobalSnackBar.show(context, jsonDataResponsePut['message'], jsonDataResponsePut['code']);

  }

  void updateAllNames() {
     Map<double, String> configNames = {};
    for (var obj in configModel.configObject ?? []) {
      if (obj.sNo != null && obj.name != null) {
        configNames[obj.sNo!] = obj.name!;
      }
    }
     for (var src in configModel.waterSource ?? []) {
      if (configNames.containsKey(src.commonDetails?.sNo)) {
        src.commonDetails?.name = configNames[src.commonDetails!.sNo];
      }
    }
     for (var pump in configModel.pump ?? []) {
      if (configNames.containsKey(pump.commonDetails?.sNo)) {
        pump.commonDetails?.name = configNames[pump.commonDetails!.sNo];
      }
    }
     for (var filterSite in configModel.filterSite ?? []) {
      if (configNames.containsKey(filterSite.commonDetails?.sNo)) {
        filterSite.commonDetails?.name = configNames[filterSite.commonDetails!.sNo];
      }
    }
     for (var fertSite in configModel.fertilizerSite ?? []) {
      if (configNames.containsKey(fertSite.commonDetails?.sNo)) {
        fertSite.commonDetails?.name = configNames[fertSite.commonDetails!.sNo];
      }
    }
     for (var moisture in configModel.moistureSensor ?? []) {
      if (configNames.containsKey(moisture.commonDetails?.sNo)) {
        moisture.commonDetails?.name = configNames[moisture.commonDetails!.sNo];
      }
    }
     for (var line in configModel.irrigationLine ?? []) {
      if (configNames.containsKey(line.commonDetails?.sNo)) {
        line.commonDetails?.name = configNames[line.commonDetails!.sNo];
      }
    }

    setState(() {});
  }
}