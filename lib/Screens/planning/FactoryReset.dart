import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../models/reset_AccumalationModel.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/environment.dart';
import '../../utils/snack_bar.dart';

class ResetAccumalationScreen extends StatefulWidget {
  const ResetAccumalationScreen(
      {Key? key,
        required this.userId,
        required this.controllerId,
        required this.deviceID});
  final userId, controllerId, deviceID;

  @override
  State<ResetAccumalationScreen> createState() => _ResetAccumalationScreenState();
}

class _ResetAccumalationScreenState extends State<ResetAccumalationScreen>
    with SingleTickerProviderStateMixin {
  // late TabController _tabController;
  ResetModel _resetModel = ResetModel();
  int tabclickindex = 0;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchData();
    Request();
  }

  Future<void> fetchData() async {
    try{
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.getresetAccumulation({
        "userId": widget.userId,
        "controllerId": widget.controllerId
      });

       if (getUserDetails.statusCode == 200) {
        setState(() {
          var jsonData = jsonDecode(getUserDetails.body);
          _resetModel = ResetModel.fromJson(jsonData);
        });
      } else {
        //_showSnackBar(response.body);
      }
    }
    catch (e, stackTrace) {
      print(' Error overAll getData => ${e.toString()}');
      print(' trace overAll getData  => ${stackTrace}');
    }


  }
  createUserSentAndReceivedMessageManually(String hw) async {
    try{
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.sendManualOperationToServer(
          {"userId": widget.userId, "controllerId": widget.controllerId, "messageStatus": "Factory Reset", "hardware": hw, "createUser": widget.userId}
      );

    }
    catch (e, stackTrace) {
      print(' Error overAll getData => ${e.toString()}');
      print(' trace overAll getData  => ${stackTrace}');
    }


  }




  @override
  Widget build(BuildContext context) {


     return Scaffold(
      appBar: AppBar(title: const Text('Factory Reset'),),
      body: Column(
        children: [
          _resetModel.code == 200 ? _resetModel.data!.accumulation!.isNotEmpty ? DefaultTabController(
            length: _resetModel.data!.accumulation!.length,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 80, right: 8, top: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      height: 50,
                      child: TabBar(
                        // controller: _tabController,
                        indicatorColor: const Color.fromARGB(255, 175, 73, 73),
                        isScrollable: true,
                        unselectedLabelColor: Colors.grey,
                        labelColor: Theme.of(context).primaryColor,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: [
                          for (var i = 0; i < _resetModel.data!.accumulation!.length; i++)
                            Tab(
                              text: '${_resetModel.data!.accumulation![i].name}',
                            ),
                        ],
                        onTap: (value) {
                          setState(() {
                            tabclickindex = value;
                            changeval(value);
                          });
                        },
                      ),
                    ),
                    SizedBox(
                     height: 300,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey, // Border color
                           ),
                        ),
                         child: TabBarView(children: [
                          for (var i = 0; i < _resetModel.data!.accumulation!.length; i++)
                            buildTab(_resetModel.data!.accumulation![i].list)
                        ]),
                      ),
                    ),
                    // ElevatedButton(
                    //   child: const Text("RESET ALL"),
                    //   onPressed: () async {
                    //     setState(() {
                    //       ResetAll(_resetModel.data!.accumulation!);
                    //     });
                    //   },
                    // ),
                    const SizedBox(height: 10,),

                  ],
                ),
              ),
            ),

          ) :   const Center(child: Text('Currently No data Available')): const Center(child: Text('Currently No data Available')),
          ElevatedButton(
            style: ButtonStyle(  backgroundColor: WidgetStateProperty.all(Colors.redAccent),),
            child: const Text("Factory Reset",style: TextStyle(color: Colors.white),),
            onPressed: () async {
              setState(() {
                _showMyDialog(context);
              });
            },
          ),
        ],
      ),
    );

  }

  Future<void> _showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Do you want to Reset All data?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert dialog
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                FResetAll();
                Navigator.of(context).pop(); // Close the alert dialog
              },
            ),
          ],
        );
      },
    );
  }
  double Changesize(int? count, int val) {
    count ??= 0;
    double size = (count * val).toDouble();
    return size;
  }
  changeval(int Selectindexrow) {}
  Widget buildTab(List<ListElement>? Listofvalue,){
    return Container(
      child: DataTable2(
          headingRowColor: WidgetStateProperty.all<Color>(
              Theme.of(context).primaryColorDark.withOpacity(0.2)),
          // fixedCornerColor: myTheme.primaryColor,
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 600,
          // border: TableBorder.all(width: 0.5),
          // fixedColumnsColor: Colors.amber,
          headingRowHeight: 50,
          columns: const [
            DataColumn2(
              fixedWidth: 70,
              label: Center(
                  child: Text(
                    'Sno',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:  16,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                  )),
            ),
            DataColumn2(
              label: Center(
                  child: Text(
                    'Name',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:  16,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                  )),
            ),
            DataColumn2(
              fixedWidth: 150,
              label: Center(
                  child: Text(
                    'Daily Accumalation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                  )),
            ),
            DataColumn2(
              fixedWidth: 150,
              label: Center(
                  child: Text(
                    'Total Accumalation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                  )),
            ),
            DataColumn2(
              fixedWidth: 150,
              label: Center(
                  child: Text(
                    'Reset',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                  )),
            ),
          ],
          rows: List<DataRow>.generate(Listofvalue!.length, (index) => DataRow(cells: [
            DataCell(Center(child: Text('${Listofvalue[index].sNo}'))),
            DataCell(Center(
              child: Text(
                '${Listofvalue[index].name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )),
            DataCell(Center(
              child: Text(
                '${Listofvalue[index].todayCumulativeFlow}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )),
            DataCell(Center(
              child: Text(
                '${Listofvalue[index].totalCumulativeFlow}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )),
            DataCell(
              Center(
                child: ElevatedButton(
                  style:  ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 18),foregroundColor: Colors.white,),
                  onPressed: () { reset(Listofvalue[index].sNo!);},
                  child: const Text('Reset'),

                ),
              ),
            ),]),
          )),
    );
    // }
  }

  updateradiationset() async {
    try{
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.updateresetAccumulation({
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "modifyUser": widget.userId
      });

      // String payLoadFinal = jsonEncode({
      //   "2900": [
      //     {"2901": body},
      //   ]
      // });
      // MQTTManager().publish( payLoadFinal, 'AppToFirmware/${widget.deviceID}');
    }
    catch (e, stackTrace) {
      print(' Error overAll getData => ${e.toString()}');
      print(' trace overAll getData  => ${stackTrace}');
    }
  }


  Request(){
    String payLoadFinal = jsonEncode({
      "5300":
      {"5301": "1"},
    });
    MqttService().topicToPublishAndItsMessage(payLoadFinal, "${Environment.mqttPublishTopic}/${widget.deviceID}");


  }

  void reset(double Srno) async{
    String payLoadFinal = jsonEncode({
      "5400":
      {"5401": '${Srno},1;'},
    });

    MqttService().topicToPublishAndItsMessage(payLoadFinal, "${Environment.mqttPublishTopic}/${widget.deviceID}");
    createUserSentAndReceivedMessageManually(payLoadFinal);
    GlobalSnackBar.show(context, 'Request send', 200);
    await Future.delayed(const Duration(seconds: 2));
    fetchData();
  }
  ResetAll(List<Accumulation>? data)   {
    String restsrn = '';

    for (var j = 0; j < data!.length; j++) {
      restsrn += "${data[j].list?[0].sNo},1;";
    }
    Map<String, dynamic> payLoadFinal = {
      "5400":
      {"5401": restsrn}
    };

    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), "${Environment.mqttPublishTopic}/${widget.deviceID}");
    createUserSentAndReceivedMessageManually(jsonEncode(payLoadFinal));
  }
  FResetAll()   {
    String payLoadFinal = jsonEncode({
      "5300":
      {"5301": "2"},
    });
    MqttService().topicToPublishAndItsMessage(payLoadFinal, "${Environment.mqttPublishTopic}/${widget.deviceID}");
    createUserSentAndReceivedMessageManually(payLoadFinal);
  }
}