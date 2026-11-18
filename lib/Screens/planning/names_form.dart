
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/names_model.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/snack_bar.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

// AppConstants import path உங்கள் project-க்கு ஏற்ப சரிபார்க்கவும்.
import 'package:oro_drip_irrigation/utils/constants.dart';

class Names extends StatefulWidget {
  final int userID;
  final int customerID;
  final int controllerId;
  final int menuId;
  final int modelId;
  final String imeiNo;

  const Names({
    super.key,
    required this.userID,
    required this.customerID,
    required this.controllerId,
    required this.menuId,
    required this.imeiNo,
    required this.modelId,
  });

  @override
  State<Names> createState() => _NamesState();
}

class _NamesState extends State<Names> {
  NamesConfigModel configModel = NamesConfigModel();

  List<String> uniqueObjectNames = [];
  List<TextEditingController> _controllers = [];

  dynamic liveData;
  int selectedCategory = 0;

  // Pump models -> Location hidden.
  // Other models -> Location visible.
  bool get showLocation =>
      !AppConstants.pumpList.contains(widget.modelId);

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> getData() async {
    try {
      final Repository repository = Repository(HttpService());

      final response = await repository.getUserConfigMaker({
        "userId": widget.customerID,
        "controllerId": widget.controllerId,
      });

      final jsonData = jsonDecode(response.body);

      if (jsonData['code'] == 200) {
        final newModel = NamesConfigModel.fromJson(jsonData['data']);

        final newCategories = (newModel.configObject ?? [])
            .map((obj) => obj.objectName ?? '')
            .toSet()
            .toList();

        final newControllers = (newModel.configObject ?? [])
            .map(
              (obj) => TextEditingController(
            text: obj.name ?? '',
          ),
        )
            .toList();

        if (!mounted) {
          for (final controller in newControllers) {
            controller.dispose();
          }
          return;
        }

        setState(() {
          for (final controller in _controllers) {
            controller.dispose();
          }

          configModel = newModel;
          uniqueObjectNames = newCategories;
          _controllers = newControllers;

          if (selectedCategory >= uniqueObjectNames.length) {
            selectedCategory = 0;
          }
        });
      }
    } catch (e, stackTrace) {
      AppLog.log('Error overAll getData => $e');
      AppLog.log('trace overAll getData => $stackTrace');
    }
  }

  Widget getTabBarViewWidget() {
    final List<String> listOfCategory = uniqueObjectNames;

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
                        color: selectedCategory == i
                            ? Colors.white
                            : Colors.black,
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
    if (selectedTabIndex < 0 ||
        selectedTabIndex >= uniqueObjectNames.length) {
      return const Center(
        child: Text('No category selected'),
      );
    }

    final filteredData = (configModel.configObject ?? [])
        .where(
          (obj) =>
      obj.objectName == uniqueObjectNames[selectedTabIndex],
    )
        .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Table(
          // Dynamic column widths.
          // Pump: S.No | Name
          // Others: S.No | Location | Name
          columnWidths: {
            0: const FixedColumnWidth(80),
            if (showLocation) 1: const FixedColumnWidth(120),
            if (showLocation) 2: const FlexColumnWidth(),
            if (!showLocation) 1: const FlexColumnWidth(),
          },
          children: [
            // Header
            TableRow(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              children: [
                _buildHeaderCell('S.No'),

                // Show Location only for non-pump models.
                if (showLocation)
                  _buildHeaderCell('Location'),

                _buildHeaderCell('Name'),
              ],
            ),

            // Data rows
            ...filteredData.asMap().entries.map((entry) {
              final int index = entry.key;
              final data = entry.value;

              final Color rowColor = index.isEven
                  ? Colors.grey.shade100
                  : Colors.white;

              final int originalIndex =
              (configModel.configObject ?? []).indexOf(data);

              return TableRow(
                decoration: BoxDecoration(
                  color: rowColor,
                ),
                children: [
                  // S.No
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Text(
                      data.sNo.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Location: hide for pump models.
                  if (showLocation)
                    Container(
                      height: 50,
                      alignment: Alignment.center,
                      child: Text(
                        configModel.getNameBySNo(
                          data.location ?? 0.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Name
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: TextFormField(
                      controller: _controllers[originalIndex],
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                        FilteringTextInputFormatter.allow(
                          RegExp(
                            r'[a-zA-Z0-9\s.!@#$%^&*()_+\-=\[\]{}|;:"<>,.?/`~]',
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          final bool nameExists =
                          (configModel.configObject ?? []).any(
                                (element) =>
                            element != data &&
                                element.name?.trim().toLowerCase() ==
                                    val.trim().toLowerCase() &&
                                element.objectName == "Valve" &&
                                element.location == data.location,
                          );

                          if (nameExists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Name Already Exists'),
                              ),
                            );
                          } else if (val.length > 15) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                Text('Name length Maximum reached'),
                              ),
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
                      style: const TextStyle(
                        color: Colors.blue,
                      ),
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

  Widget _buildHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColorDark,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (configModel.configObject == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(
        title: const Text('Names'),
      ),
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
          updateAllNames();
          updateUserNames();
        },
        tooltip: 'Send',
        child: const Icon(Icons.send),
      ),
    );
  }

  Future<void> updateUserNames() async {
    final Map<String, dynamic> namesModelData = configModel.toJson();

    final Repository repository = Repository(HttpService());

    AppLog.log(namesModelData['configObject']);

    final Map<String, dynamic> body = {
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

    final response = await repository.updateUserNames(body);

    final jsonDataResponsePut = jsonDecode(response.body);

    if (!mounted) return;

    GlobalSnackBar.show(
      context,
      jsonDataResponsePut['message'],
      jsonDataResponsePut['code'],
    );
  }

  void updateAllNames() {
    final Map<double, String> configNames = {};

    for (final obj in configModel.configObject ?? []) {
      if (obj.sNo != null && obj.name != null) {
        configNames[obj.sNo!] = obj.name!;
      }
    }

    for (final src in configModel.waterSource ?? []) {
      if (configNames.containsKey(src.commonDetails?.sNo)) {
        src.commonDetails?.name =
        configNames[src.commonDetails!.sNo];
      }
    }

    for (final pump in configModel.pump ?? []) {
      if (configNames.containsKey(pump.commonDetails?.sNo)) {
        pump.commonDetails?.name =
        configNames[pump.commonDetails!.sNo];
      }
    }

    for (final filterSite in configModel.filterSite ?? []) {
      if (configNames.containsKey(filterSite.commonDetails?.sNo)) {
        filterSite.commonDetails?.name =
        configNames[filterSite.commonDetails!.sNo];
      }
    }

    for (final fertSite in configModel.fertilizerSite ?? []) {
      if (configNames.containsKey(fertSite.commonDetails?.sNo)) {
        fertSite.commonDetails?.name =
        configNames[fertSite.commonDetails!.sNo];
      }
    }

    for (final moisture in configModel.moistureSensor ?? []) {
      if (configNames.containsKey(moisture.commonDetails?.sNo)) {
        moisture.commonDetails?.name =
        configNames[moisture.commonDetails!.sNo];
      }
    }

    for (final line in configModel.irrigationLine ?? []) {
      if (configNames.containsKey(line.commonDetails?.sNo)) {
        line.commonDetails?.name =
        configNames[line.commonDetails!.sNo];
      }
    }

    setState(() {});
  }
}
