import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Constants/properties.dart';
import '../../models/valve_group_model.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../StateManagement/overall_use.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/snack_bar.dart';

class GroupListScreen extends StatefulWidget {
  final int userId;
  final int controllerId;
  final int customerId;
  final String deviceId;

  const GroupListScreen({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.deviceId, required this.customerId,
  });

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  late MqttPayloadProvider mqttPayloadProvider;
  Groupdata _groupdata = Groupdata();

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchData();
      });
    }
  }

  deleteValveGroupAtIndex(int index) {
    if (_groupdata.data?.valveGroup != null &&
        index >= 0 &&
        index < _groupdata.data!.valveGroup!.length) {
      _groupdata.data!.valveGroup!.removeAt(index);
    } else {
      print("Invalid index or valveGroup is null.");
    }
  }

  Future<void> fetchData() async {
    print("fetch data Call");
    var overAllPvd = Provider.of<OverAllUse>(context, listen: false);

    Map<String, Object> body = {
      "userId": widget.customerId,
      "controllerId": widget.controllerId,
    };
    final Repository repository = Repository(HttpService());
    final response = await repository.getUserPlanningValveGroup(body);
    if (response.statusCode == 200) {
      setState(() {
        var jsonData = jsonDecode(response.body);
        _groupdata = Groupdata.fromJson(jsonData);
      });
    } else {
      GlobalSnackBar.show(context, "Failed to fetch valve groups", 400);
    }
  }

  Future<void> createValveGroup() async {
    print("createvalvegroup call");
    final Repository repository = Repository(HttpService());
    Map<String, dynamic> body = {
      "userId": widget.userId,
      "controllerId": widget.controllerId,
      "valveGroup": _groupdata.data?.valveGroup!.map((x) => x.toJson()).toList() ?? [],
      "createUser": widget.userId,
    };

    var getUserDetails = await repository.createUserValveGroup(body);
    var jsonDataResponse = jsonDecode(getUserDetails.body);
    GlobalSnackBar.show(context, jsonDataResponse['message'], jsonDataResponse['code']);
    if (jsonDataResponse['code'] == 200) {
      setState(() {
        fetchData();
      });
    }
  }

  void _showAddEditValveGroupDialog({bool editCheck = false, int? selectedGroupIndex}) {
    final TextEditingController _controller = TextEditingController();
    IrrigationLine? selectedIrrigationLine;
    List<Valve> selectedValves = [];
    List<double> selectedValveSnos = [];
    int selectLineIndex = 0;

    // Initialize dialog state for editing or adding
    if (editCheck && selectedGroupIndex != null) {
      // Deep copy to avoid modifying the original data
      selectedValves = List.from(_groupdata.data!.valveGroup![selectedGroupIndex].valve);
      selectedValveSnos = selectedValves.map((e) => e.sNo).toList();
      _controller.text = _groupdata.data!.valveGroup![selectedGroupIndex].groupName;
      double selectedIrrigationLineSno = _groupdata.data!.valveGroup![selectedGroupIndex].sNo;
      selectedIrrigationLine = _groupdata.data!.defaultData.irrigationLine
          .firstWhere((line) => line.sNo == selectedIrrigationLineSno);
      selectLineIndex = _groupdata.data!.defaultData.irrigationLine
          .indexWhere((line) => line.sNo == selectedIrrigationLineSno);
    } else {
      selectedIrrigationLine = _groupdata.data!.defaultData.irrigationLine[0];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                editCheck ? 'Edit Valve Group' : 'Add Valve Group',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _controller,
                          decoration: const InputDecoration(labelText: 'Group Name:'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButton<IrrigationLine>(
                          hint: const Text('Choose an irrigation line'),
                          value: selectedIrrigationLine,
                          onChanged: (IrrigationLine? newValue) {
                            setStateDialog(() {
                              selectLineIndex = _groupdata.data!.defaultData.irrigationLine
                                  .indexWhere((line) => line.name == newValue!.name);
                              selectedIrrigationLine = newValue;
                              // Clear valves when irrigation line changes
                              selectedValves.clear();
                              selectedValveSnos.clear();
                            });
                          },
                          items: _groupdata.data!.defaultData.irrigationLine.map((IrrigationLine line) {
                            return DropdownMenuItem<IrrigationLine>(
                              value: line,
                              child: Text(line.name),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selectedIrrigationLine != null) ...[
                      const Text(
                        'Select Valves:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: selectedIrrigationLine!.valve.map((Valve valve) {
                          return ChoiceChip(
                            label: Text(valve.name),
                            selected: selectedValveSnos.contains(valve.sNo),
                            onSelected: (bool selected) {
                              setStateDialog(() {
                                if (selected) {
                                  if (!selectedValveSnos.contains(valve.sNo)) {
                                    selectedValves.add(valve);
                                    selectedValveSnos.add(valve.sNo);
                                  }
                                } else {
                                  // Remove valve by sNo to avoid object reference issues
                                  selectedValves.removeWhere((v) => v.sNo == valve.sNo);
                                  selectedValveSnos.remove(valve.sNo);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedValves.isNotEmpty
                      ? () async {
                    String groupId = editCheck
                        ? _groupdata.data!.valveGroup![selectedGroupIndex!].groupID
                        : 'VG.${_groupdata.data!.valveGroup!.length + 1}';
                    ValveGroup vdate = ValveGroup(
                      groupID: groupId,
                      objectId: _groupdata.data!.defaultData.irrigationLine[selectLineIndex].objectId,
                      groupName: _controller.text,
                      irrigationLineName: _groupdata.data!.defaultData.irrigationLine[selectLineIndex].name,
                      sNo: _groupdata.data!.defaultData.irrigationLine[selectLineIndex].sNo,
                      name: _groupdata.data!.defaultData.irrigationLine[selectLineIndex].name,
                      objectName: _groupdata.data!.defaultData.irrigationLine[selectLineIndex].objectName,
                      valve: selectedValves,
                    );

                    setState(() {
                      if (editCheck) {
                        _groupdata.data!.valveGroup![selectedGroupIndex!] = vdate;
                      } else {
                        _groupdata.data!.valveGroup!.add(vdate);
                      }
                    });

                    await createValveGroup();
                    Navigator.of(context).pop();
                  }
                      : null,
                  child: Text(
                    editCheck ? 'Update' : 'Create',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !kIsWeb
          ? AppBar(
        title: const Text("Valve Group"),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add', style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (_groupdata.data!.defaultData.valveGroupLimit > 0 &&
                  _groupdata.data!.valveGroup!.length < _groupdata.data!.defaultData.valveGroupLimit) {
                _showAddEditValveGroupDialog();
              } else {
                GlobalSnackBar.show(context, "Valve group limit is reached", 201);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      )
          : null,
      backgroundColor: const Color(0xffE6EDF5),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        if (_groupdata.data!.defaultData.valveGroupLimit > 0 &&
                            _groupdata.data!.valveGroup!.length < _groupdata.data!.defaultData.valveGroupLimit) {
                          _showAddEditValveGroupDialog();
                        } else {
                          GlobalSnackBar.show(context, "Valve group limit is reached", 201);
                        }
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _groupdata.data?.valveGroup?.length ?? 0,
                itemBuilder: (context, index) {
                  final group = _groupdata.data!.valveGroup![index];

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: AppProperties.customBoxShadowLiteTheme,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: kIsWeb
                          ? buildWebLayout(context, group, index)
                          : buildMobileLayout(context, group, index),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      floatingActionButton: Row(
        children: [
          const Spacer(),
          FloatingActionButton(
            onPressed: createValveGroup,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget buildWebLayout(BuildContext context, group, int index) {
    return Row(
      children: [
        const SizedBox(width: 10),
        CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.groupName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(group.irrigationLineName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(width: 5,),
        Container(width: 1, height: 100, color: Colors.grey),
        SizedBox(width: 5,),
        Expanded(
          child: Wrap(
            spacing: 5.0,
            runSpacing: 10.0,
            children: List.generate(group.valve.length, (vindex) {
              return Chip(
                backgroundColor: const Color(0xfffdce7f),
                labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                label: Text(group.valve[vindex].name),
              );
            }),
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Image.asset('assets/png/delete_icon.png'),
              onPressed: () => _confirmDelete(context, index),
            ),
            IconButton(
              icon: Image.asset('assets/png/edit_icon.png'),
              onPressed: () => _showAddEditValveGroupDialog(editCheck: true, selectedGroupIndex: index),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildMobileLayout(BuildContext context, group, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
          ),
          title: Text(group.groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(group.irrigationLineName),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Image.asset('assets/png/edit_icon.png'),
                onPressed: () => _showAddEditValveGroupDialog(editCheck: true, selectedGroupIndex: index),
              ),
              IconButton(
                icon: Image.asset('assets/png/delete_icon.png'),
                onPressed: () => _confirmDelete(context, index),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: List.generate(group.valve.length, (vindex) {
              return Chip(
                backgroundColor: const Color(0xfffdce7f),
                labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                label: Text(group.valve[vindex].name),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _confirmDelete(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Valve Group'),
          content: const Text('Are you sure you want to delete this valve group?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                deleteValveGroupAtIndex(index);
                await createValveGroup();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

}