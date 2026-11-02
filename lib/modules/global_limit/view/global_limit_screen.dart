import 'dart:convert';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/Constants/properties.dart';
import 'package:oro_drip_irrigation/modules/global_limit/repository/global_limit_repository.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import '../../../Widgets/custom_buttons.dart';
import '../../../Widgets/status_box.dart';
import '../../../utils/environment.dart';
import '../../config_maker/view/config_web_view.dart';
import '../model/line_in_global_limit_model.dart';


class GlobalLimitScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const GlobalLimitScreen({super.key, required this.userData});

  @override
  State<GlobalLimitScreen> createState() => _GlobalLimitScreenState();
}

class _GlobalLimitScreenState extends State<GlobalLimitScreen> {
  late Future<int> globalLimitResponse;
  List<LineInGlobalLimitModel> listOfIrrigationLine = [];
  int selectedLine = 0;
  late ThemeData themeData;
  late bool themeMode;
  HardwareAcknowledgementState payloadState = HardwareAcknowledgementState.notSent;
  MqttService mqttService = MqttService();
  int maximumNoOfChannel = 8;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    globalLimitResponse = getGlobalLimitData(widget.userData);
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    themeData = Theme.of(context);
    themeMode = themeData.brightness == Brightness.light;
  }

  Future<int> getGlobalLimitData(Map<String, dynamic>userData)async{
    try{
      var body = {
        "userId": userData['customerId'],
        "controllerId": userData['controllerId'],
      };
      var response = await GlobalLimitRepository().getUserGlobalLimit(body);
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      setState(() {
        listOfIrrigationLine = (jsonData['data']['globalLimit'] as List<dynamic>).map((line){
          return LineInGlobalLimitModel.fromJson(line);
        }).toList();
      });
      return jsonData['code'];
    }catch(e, stackTrace){
      if (kDebugMode) {
        print('Error :: $e');
        print('Stack Trace :: $stackTrace');
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
        future: globalLimitResponse,
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Loading state
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}'); // Error state
          } else if (snapshot.hasData) {
            return Scaffold(
              backgroundColor: Colors.white,
              floatingActionButton: getFloatingActionButton(),
              appBar: MediaQuery.of(context).size.width < 500 ? AppBar(
                title: const Text('Global Limit'),
              ): null,
              body: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: Column(
                        children: [
                          const SizedBox(height: 10,),
                          getIrrigationLine(),
                          const SizedBox(height: 10,),
                          Expanded(
                            child: Container(
                              width: MediaQuery.of(context).size.width - 20,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(width: 1, color: themeData.primaryColor.withValues(alpha: 0.5))
                              ),
                              child: DataTable2(
                                minWidth: 2750,
                                fixedLeftColumns: 1,
                                columns: [
                                  DataColumn2(
                                    fixedWidth: 150,
                                    label: Text('Valve', style: themeData.textTheme.headlineLarge,),
                                  ),
                                  DataColumn2(
                                    fixedWidth: 150,
                                    label: Text('Quantity', style: themeData.textTheme.headlineLarge,),
                                  ),
                                  ...List.generate(maximumNoOfChannel, (int index){
                                    return  DataColumn2(
                                      fixedWidth: 150,
                                      label: Text('Central Ch${index+1}', style: themeData.textTheme.headlineLarge,),
                                    );
                                  }),
                                  ...List.generate(maximumNoOfChannel, (int index){
                                    return  DataColumn2(
                                      fixedWidth: 150,
                                      label: Text('Local Ch${index+1}', style: themeData.textTheme.headlineLarge,),
                                    );
                                  }),
                                ],
                                dividerThickness: 1,
                                rows: List.generate(listOfIrrigationLine[selectedLine].valve.length, (int row){
                                  return DataRow(
                                      color: WidgetStatePropertyAll(
                                        row.isOdd ? Colors.white : themeData.primaryColorLight.withValues(alpha: 0.1),
                                      ),
                                      cells: [
                                        DataCell(
                                            Text(listOfIrrigationLine[selectedLine].valve[row].name)
                                        ),
                                        DataCell(
                                            getTextField(
                                                key: '${listOfIrrigationLine[selectedLine].valve[row].sNo}',
                                                initialValue: listOfIrrigationLine[selectedLine].valve[row].quantity,
                                                onChanged: (value){
                                                  setState(() {
                                                    listOfIrrigationLine[selectedLine].valve[row].quantity = value;
                                                  });
                                                },
                                                inputFormatters: AppProperties.regexForNumbers
                                            )
                                        ),
                                        ...List.generate(maximumNoOfChannel, (int cell){
                                          if(listOfIrrigationLine[selectedLine].centralCount > cell){
                                            return DataCell(
                                                getTextField(
                                                    key: '${listOfIrrigationLine[selectedLine].valve[row].sNo}',
                                                    initialValue: listOfIrrigationLine[selectedLine].valve[row].getCentralChannel(channelNo: cell).value,
                                                    onChanged: (value){
                                                      setState(() {
                                                        listOfIrrigationLine[selectedLine].valve[row].getCentralChannel(channelNo: cell).value = value;
                                                      });
                                                    },
                                                    inputFormatters: AppProperties.regexForDecimal
                                                )
                                            );
                                          }else{
                                            return DataCell(Text('N/A', style: TextStyle(color: Colors.grey.shade400)));
                                          }

                                        }),
                                        ...List.generate(maximumNoOfChannel, (int cell){
                                          if(listOfIrrigationLine[selectedLine].localCount > cell){
                                            return DataCell(
                                                getTextField(
                                                    key: '${listOfIrrigationLine[selectedLine].valve[row].sNo}',
                                                    initialValue: listOfIrrigationLine[selectedLine].valve[row].getLocalChannel(channelNo: cell).value,
                                                    onChanged: (value){
                                                      setState(() {
                                                        listOfIrrigationLine[selectedLine].valve[row].getLocalChannel(channelNo: cell).value = value;
                                                      });
                                                    },
                                                    inputFormatters: AppProperties.regexForDecimal
                                                )
                                            );
                                          }else{
                                            return DataCell(Text('N/A', style: TextStyle(color: Colors.grey.shade400),));
                                          }
                                        })
                                      ]
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                ),
              ),
            );
          } else {
            return const Text('No data'); // Shouldn't reach here normally
          }
        }
    );
  }

  Widget getTextField({
    required String key,
    required String initialValue,
    required void Function(String)? onChanged,
    required List<TextInputFormatter>? inputFormatters

  }){
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(width: 1, color: Theme.of(context).primaryColorDark.withValues(alpha: 0.3)),
      ),
      child: TextFormField(
        key: Key(key),
        inputFormatters: inputFormatters,
        initialValue: initialValue,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        cursorHeight: 20,
        decoration: const InputDecoration(
            contentPadding: EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(maxHeight: 35),
            counterText: '',
            border: OutlineInputBorder(
                borderSide: BorderSide.none
            )
        ),
      ),
    );
  }

  Widget getFloatingActionButton(){
    return FloatingActionButton(
      onPressed: (){
        setState(() {
          payloadState = HardwareAcknowledgementState.notSent;
          mqttService.acknowledgementPayload = null;
        });
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context){
              return StatefulBuilder(
                  builder: (context, stateSetter){
                    return AlertDialog(
                      title: Text('Send Payload', style: Theme.of(context).textTheme.labelLarge,),
                      content: getHardwareAcknowledgementWidget(payloadState),
                      actions: [
                        if(payloadState != HardwareAcknowledgementState.sending && payloadState != HardwareAcknowledgementState.notSent)
                          CustomMaterialButton(),
                        if(payloadState == HardwareAcknowledgementState.notSent)
                          CustomMaterialButton(title: 'Cancel',outlined: true,),
                        if(payloadState == HardwareAcknowledgementState.notSent)
                          CustomMaterialButton(
                            onPressed: ()async{
                              sendToHttp();
                              var payload = jsonEncode(getGlobalLimitPayload());
                              int delayDuration = 10;
                              for(var delay = 0; delay < delayDuration; delay++){
                                if(delay == 0){
                                  stateSetter((){
                                    setState((){
                                      mqttService.topicToPublishAndItsMessage(payload, '${Environment.mqttPublishTopic}/${widget.userData['deviceId']}');
                                      payloadState = HardwareAcknowledgementState.sending;
                                    });
                                  });
                                }
                                stateSetter((){
                                  setState((){
                                    if(mqttService.acknowledgementPayload != null){
                                      if(validatePayloadFromHardware(mqttService.acknowledgementPayload, ['cC'], widget.userData['deviceId']) && validatePayloadFromHardware(mqttService.acknowledgementPayload!, ['cM', '4201', 'PayloadCode'], '1100')){
                                        if(mqttService.acknowledgementPayload!['cM']['4201']['Code'] == '200'){
                                          payloadState = HardwareAcknowledgementState.success;
                                        }else if(mqttService.acknowledgementPayload!['cM']['4201']['Code'] == '90'){
                                          payloadState = HardwareAcknowledgementState.programRunning;
                                        }else if(mqttService.acknowledgementPayload!['cM']['4201']['Code'] == '1'){
                                          payloadState = HardwareAcknowledgementState.hardwareUnknownError;
                                        }else{
                                          payloadState = HardwareAcknowledgementState.errorOnPayload;
                                        }
                                        mqttService.acknowledgementPayload == null;
                                      }
                                    }
                                  });
                                });
                                await Future.delayed(const Duration(seconds: 1));
                                if(delay == delayDuration-1){
                                  stateSetter((){
                                    setState((){
                                      payloadState = HardwareAcknowledgementState.failed;
                                    });
                                  });
                                }
                                if(payloadState != HardwareAcknowledgementState.sending){
                                  break;
                                }
                              }
                            },
                            title: 'Send',
                          ),

                      ],
                    );
                  }
              );
            }
        );
      },
      child: const Icon(Icons.send),
    );
  }

  Map<String, dynamic> getGlobalLimitPayload(){
    var payload = listOfIrrigationLine.map((line){
      return line.valve.map((valve) {
        return {
          'S_No' : valve.sNo,
          'IrrigationQuantityLimit' : valve.quantity.isEmpty ? 0 : valve.quantity,
          'CentralFertilizerLimit' : List.generate(maximumNoOfChannel, (int channelNo){
            if(channelNo < line.centralCount){
              String val = valve.getCentralChannel(channelNo: channelNo).value;
              return val.isEmpty ? 0 : val;
            }else{
              return '';
            }
          }).join('_'),
          'LocalFertilizerLimit' : List.generate(maximumNoOfChannel, (int channelNo){
            if(channelNo < line.localCount){
              String val = valve.getLocalChannel(channelNo: channelNo).value;
              return val.isEmpty ? 0 : val;
            }else{
              return '';
            }
          }).join('_'),

        }.entries.map((obj) => obj.value).join(',');
      }).toList();
    }).expand((list) => list).toList().join(';');
    var globalLimitPayload = {
      "1100" :{
        "1101" :payload
      }
    };
    print('globalLimitPayload : $globalLimitPayload');
    return globalLimitPayload;
  }


  Widget getHardwareAcknowledgementWidget(HardwareAcknowledgementState state){
    print('state : $state');
    if(state == HardwareAcknowledgementState.notSent){
      return const StatusBox(color:  Colors.black87,child: Text('Do you want to send payload..',),);
    }else if(state == HardwareAcknowledgementState.success){
      return const StatusBox(color:  Colors.green,child: Text('Success..',),);
    }else if(state == HardwareAcknowledgementState.failed){
      return const StatusBox(color:  Colors.red,child: Text('Failed..',),);
    }else if(state == HardwareAcknowledgementState.errorOnPayload){
      return const StatusBox(color:  Colors.red,child: Text('Payload error..',),);
    }else{
      return const SizedBox(
          width: double.infinity,
          height: 5,
          child: LinearProgressIndicator()
      );
    }
  }

  void sendToHttp()async{
    var body = {
      "userId" : widget.userData['userId'],
      "controllerId" : widget.userData['controllerId'],
      'globalLimit' : listOfIrrigationLine.map((line) => line.toJson()).toList(),
      "createUser" : widget.userData['userId']
    };
    var response = await GlobalLimitRepository().createUserGlobalLimit(body);
    print('response global limit : ${response.body}');
  }



  Widget getIrrigationLine(){
    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for(var line = 0; line < listOfIrrigationLine.length;line++)
              InkWell(
                onTap: (){
                  setState(() {
                    selectedLine = line;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: EdgeInsets.symmetric(horizontal: 15,vertical: selectedLine == line ? 12 :10),
                  decoration: BoxDecoration(
                      border: const Border(top: BorderSide(width: 0.5), left: BorderSide(width: 0.5), right: BorderSide(width: 0.5)),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                      color: selectedLine == line ? Theme.of(context).primaryColor : Colors.grey.shade300
                  ),
                  child: Text(listOfIrrigationLine[line].name, style: TextStyle(color: selectedLine == line ? Colors.white : Colors.black, fontSize: 13),),
                ),
              )
          ],
        ),
        Container(
          width: double.infinity,
          height: 3,
          color: Theme.of(context).primaryColor,
        )
      ],
    );
    return child;
  }
}
