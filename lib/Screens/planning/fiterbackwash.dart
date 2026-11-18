import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import 'package:oro_drip_irrigation/utils/environment.dart';
import 'package:provider/provider.dart';
import '../../Constants/constants.dart';
import '../../models/back_wash_model.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../StateManagement/overall_use.dart';
import '../../Widgets/HoursMinutesSeconds.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/snack_bar.dart';
import '../../modules/IrrigationProgram/view/program_library.dart';
import '../../modules/IrrigationProgram/view/water_and_fertilizer_screen.dart';

class FilterBackwashUI extends StatefulWidget {
  final int userId;
  final int controllerId;
  final int customerId;
  final int modelId;
  final String deviceId;
  final bool fromDealer;
  const FilterBackwashUI(
      {super.key, required this.userId, required this.controllerId, required this.customerId, required this.deviceId, required this.fromDealer, required this.modelId,});

  @override
  State<FilterBackwashUI> createState() => _FilterBackwashUIState();
}

class _FilterBackwashUIState extends State<FilterBackwashUI>
    with SingleTickerProviderStateMixin {
  late MqttPayloadProvider mqttPayloadProvider;

  // late TabController _tabController;
   Filterbackwash _filterbackwash = Filterbackwash();
  int tabclickindex = 0;

  @override
  void initState() {
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);

    super.initState();
    //MqttWebClient().init();
     fetchData();
  }

  Future<void> fetchData() async {
        try{
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.getUserFilterBackwasing({
        "userId": widget.fromDealer ? widget.customerId : widget.userId,
        "controllerId": widget.controllerId
      });
       // final jsonData = jsonDecode(getUserDetails.body);
        if (getUserDetails.statusCode == 200) {
        setState(() {
          var jsonData = jsonDecode(getUserDetails.body);
          _filterbackwash = Filterbackwash.fromJson(jsonData);
        });
      } else {
        //_showSnackBar(response.body);
      }
    }
    catch (e, stackTrace) {
      mqttPayloadProvider.httpError = true;
      print(' Error overAll getData => ${e.toString()}');
      print(' trace overAll getData  => ${stackTrace}');
    }


  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: true);
    if (_filterbackwash.code != 200) {
      return Center(
          child:
          Text(_filterbackwash.message ?? 'Currently No Filter Available'));
    } else if (_filterbackwash.data == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (_filterbackwash.data!.filterBackwashing!.isEmpty) {
      return const Center(child: Text('Currently No Filter Available'));
    } else {
      return LayoutBuilder(builder: (context, constaint) {
        return Container(
          width: constaint.maxWidth,
          height: constaint.maxHeight,
          child: DefaultTabController(
            animationDuration: const Duration(milliseconds: 888),
            length: _filterbackwash.data!.filterBackwashing!.length,
            child: Scaffold(
              backgroundColor: const Color(0xffE6EDF5),
              appBar: AppBar(title: const Text('Filter BackWash', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),automaticallyImplyLeading: false,),
              body: SizedBox(
                child: Column(
                  children: [
                    const SizedBox(height: 10,),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white),
                      height: 50,
                      child: TabBar(
                        indicatorWeight: 4,
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabAlignment: TabAlignment.start,
                        indicator: BoxDecoration(
                          color: Theme.of(context).primaryColorDark,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              width: 10, color: Theme.of(context).primaryColorDark),
                        ),
                        isScrollable: true,
                        unselectedLabelColor: Colors.black,
                        labelColor: Colors.white,
                        labelStyle:
                        const TextStyle(fontWeight: FontWeight.bold),
                        tabs: [
                          for (var i = 0; i < _filterbackwash.data!.filterBackwashing!.length; i++)
                            Tab(
                              text: '${_filterbackwash.data!.filterBackwashing?[i].name}',
                            ),
                          // ),
                        ],
                        onTap: (value) {
                          setState(() {
                            tabclickindex = value;
                            changeval(value);
                          });
                        },
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TabBarView(children: [
                        for (var i = 0; i < _filterbackwash.data!.filterBackwashing!.length; i++)
                          MediaQuery.sizeOf(context).width > 600
                              ? buildTab(
                              _filterbackwash.data!.filterBackwashing?[i].filter,
                              i,
                              _filterbackwash.data!.filterBackwashing?[i].name,
                              _filterbackwash.data!.filterBackwashing?[i].sNo ?? 0,
                              constaint.maxWidth,
                              constaint.maxHeight)
                              : buildTabMob(
                            _filterbackwash.data!.filterBackwashing?[i].filter,
                            i,
                            _filterbackwash.data!.filterBackwashing?[i].name,
                            _filterbackwash.data!.filterBackwashing?[i].sNo ?? 0,
                          )
                      ]),
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: Theme.of(context).primaryColorDark,
                foregroundColor: Colors.white,
                onPressed: () async {
                  setState(() {
                    updatefilterbackwash();
                  });
                },
                tooltip: 'Send',
                child: const Icon(Icons.send),
              ),
            ),
          ),
        );
      });
    }
  }

  double Changesize(int? count, int val) {
    count ??= 0;
    double size = (count * val).toDouble();
    return size;
  }

  changeval(int Selectindexrow) {}

  Widget buildTab(List<Filter>? Listofvalue, int i, String? name, double? srno,
      double width, double height) {
    var overAllPvd = Provider.of<OverAllUse>(context, listen: true);
     return Row(
      children: [
        Container(
          width: width,
          height: height - 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                customizeGridView(
                  maxWith: width / 3 < 350 ? 350 : width / 3,
                   screenWidth: width,
                  listOfWidget: [
                    for (var j = 0; j < Listofvalue![0].value!.length; j++)
                      SizedBox(
                        width: 400,
                        height: 60,
                        child: Card(
                          elevation: 7,
                          child: ListTile(
                            title: Text(
                              '${Listofvalue[0].value[j]['name']} ON TIME',
                              style: const TextStyle(
                                fontSize:
                                14,
                                fontWeight: FontWeight.bold,
                              ),
                              softWrap: true,
                            ),
                            trailing: SizedBox(
                              width: 90,
                              child: Container(
                                child: Center(
                                  child: InkWell(
                                    child: Text(
                                      Constants.showHourAndMinuteOnly(
                                          '${Listofvalue[0].value![j]['value']}' !=
                                              ''
                                              ? '${Listofvalue[0].value![j]['value']}'
                                              : '00:00:00', widget.modelId
                                      ),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    onTap: () async {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: HoursMinutesSeconds(
                                              initialTime:
                                              '${Listofvalue[0].value![j]['value']}' !=
                                                  ''
                                                  ? '${Listofvalue[0].value![j]['value']}'
                                                  : '00:00:00',
                                              onPressed: () {
                                                setState(() {
                                                  Listofvalue[0].value![j]
                                                  ['value'] =
                                                  '${overAllPvd.hrs.toString().padLeft(2, '0')}:${overAllPvd.min.toString().padLeft(2, '0')}:${overAllPvd.sec.toString().padLeft(2, '0')}';
                                                });
                                                Navigator.pop(context);
                                              }, modelId: widget.modelId,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    for (var i = 1; i < Listofvalue.length; i++)
                      SizedBox(
                        width: 400,
                        height: 60,
                        child: filterCard(Listofvalue, i, Listofvalue[i].sNo!),
                      )
                  ], maxHeight: 60,
                ),
              ],
            ),
          ),
        ),
        Container(
          color: Theme.of(context).primaryColor,
        )
      ],
    );
  }

  Widget filterCard(
      List<Filter>? Listofvalue,
      int index,
      int srno,
      ) {
    var overAllPvd = Provider.of<OverAllUse>(context, listen: true);
    final RegExp _regex = RegExp(r'^([0-9]|[1-9][0-9])(\.[0-9])?$');
    if (Listofvalue?[index].widgetTypeId == 1) {
      if (Listofvalue?[index].sNo == 6) {
        return SizedBox(
          height: 60,
          width: 400,
          child: Card(
            elevation: 7,
            //color: myTheme.primaryColorLight.withOpacity(0.4),
            child: ListTile(
              title: Text(
                '${Listofvalue?[index].title}',
                style: const TextStyle(
                  fontSize:  14,
                  fontWeight: FontWeight.bold,
                ),
                softWrap: true,
              ),
              trailing: SizedBox(
                  width: 100,
                  height: 60,
                  child: Row(
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: TextFormField(
                          textAlign: TextAlign.center,
                          onChanged: (text) {
                            setState(() {
                              Listofvalue?[index].value = text;
                            });
                          },
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              hintText: '0.0', border: InputBorder.none),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(
                                r'^\d{1,2}(\.\d{0,1})?$|^99(\.0)?$|^99\.9$')),
                          ],
                          initialValue: Listofvalue?[index].value ?? '',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Warranty is required';
                            } else {
                              setState(() {
                                if (!_regex.hasMatch(value)) {
                                } else {}
                                Listofvalue?[index].value = value;
                              });
                            }
                            return null;
                          },
                        ),
                      ),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                            width: 30,
                            // height: 60,
                            child: Text(
                              'bar',
                              style: TextStyle(
                                fontSize:
                                14,
                                fontWeight: FontWeight.bold,
                              ),
                              softWrap: true,
                            )),
                      )
                    ],
                  )),
            ),
          ),
        );
      }
      return SizedBox(
        height: 60,
        width: 400,
        child: Card(
          elevation: 7,
          //color: myTheme.primaryColorLight.withOpacity(0.4),
          child: ListTile(
            title: Text(
              '${Listofvalue?[index].title}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              softWrap: true,
            ),
            trailing: SizedBox(
                width: 100,
                child: TextFormField(
                  textAlign: TextAlign.center,
                  onChanged: (text) {
                    setState(() {
                      Listofvalue?[index].value = text;
                    });
                  },
                  decoration: const InputDecoration(
                      hintText: '0', border: InputBorder.none),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  initialValue: Listofvalue?[index].value ?? '',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Warranty is required';
                    } else {
                      setState(() {
                        Listofvalue?[index].value = value;
                      });
                    }
                    return null;
                  },
                )),
          ),
        ),
      );
    } else if (Listofvalue?[index].widgetTypeId == 2) {
      return SizedBox(
        height: 60,
        width: 400,
        child: Card(
          elevation: 7,
          //color: myTheme.primaryColorLight.withOpacity(0.4),
          child: ListTile(
              title: Text(
                '${Listofvalue?[index].title}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                softWrap: true,
              ),
              trailing:  TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.green, // White text color
                ),
                onPressed: () {
                  manualonoff(srno);
                },
                child: const Text('ON/OFF'),
              )
          ),
        ),
      );
    } else if (Listofvalue?[index].widgetTypeId == 3) {
      final dropdownlist = _filterbackwash.data!.whileBackwash;
      String dropdownval = Listofvalue?[index].value;
      dropdownlist?.contains(dropdownval) == true
          ? dropdownval
          : dropdownval = 'Stop Irrigation';
      return SizedBox(
        height: 60,
        width: 400,
        child: Card(
          elevation: 7,
          //color: myTheme.primaryColorLight.withOpacity(0.4),
          child: ListTile(
            title: Text(
              '${Listofvalue?[index].title}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              softWrap: true,
            ),
            trailing: SizedBox(
              // color: Color.fromARGB(255, 28, 123, 137),
              width: 180,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).primaryColorDark,
                ),
                child: DropdownButton(
                    iconEnabledColor: Colors.white,
                    dropdownColor: Theme.of(context).primaryColorDark,
                    items: dropdownlist?.map((String items) {
                      return DropdownMenuItem(
                        value: items,
                        child: Container(
                            child: Text(
                              items,
                              style: const TextStyle(color: Colors.white),
                            )),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        Listofvalue?[index].value = value!;
                        dropdownval = Listofvalue?[index].value;
                      });
                    },
                    value: Listofvalue?[index].value == ''
                        ? dropdownlist![0]
                        : Listofvalue?[index].value),
              ),
            ),
          ),
        ),
      );
    } else if (Listofvalue?[index].widgetTypeId == 5 &&
        Listofvalue?[index].sNo != 1) {
      return SizedBox(
        height: 60,
        width: 400,
        child: Card(
          elevation: 6,
          //color: myTheme.primaryColorLight.withOpacity(0.4),
          child: ListTile(
            title: Text(
              '${Listofvalue?[index].title}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              softWrap: true,
            ),
            trailing: SizedBox(
              width: 100,
              child: Container(
                  child: Center(
                    child: InkWell(
                      child: Text(
                        '${Listofvalue?[index].value}' != ''
                            ? '${Listofvalue?[index].value}'
                            : '00:00:00',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () async {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: HoursMinutesSeconds(
                                  initialTime: '${Listofvalue?[index].value}' != ''
                                      ? '${Listofvalue?[index].value}'
                                      : '00:00:00',
                                  onPressed: () {
                                    setState(() {
                                      Listofvalue?[index].value =
                                      '${overAllPvd.hrs.toString().padLeft(2, '0')}:${overAllPvd.min.toString().padLeft(2, '0')}:${overAllPvd.sec.toString().padLeft(2, '0')}';
                                    });
                                    Navigator.pop(context);
                                  }, modelId: widget.modelId,
                                ),
                              );
                            });
                      },
                    ),
                  )),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget buildTabMob(
      List<Filter>? listOfValue,
      int i,
      String? name,
      double srNo,
      ) {
    var overAllPvd = Provider.of<OverAllUse>(context, listen: true);
    final RegExp regex = RegExp(r'^([0-9]|[1-9][0-9])(\.[0-9])?$');
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xffE6EDF5),
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.only(right: 10),
                child: Text(
                  "DELTA P - Differential Pressure  ",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 60),
              child: ListView.builder(
                itemCount: listOfValue?.length ?? 0,
                itemBuilder: (context, index) {
                  if (listOfValue?[index].widgetTypeId == 1) {
                    if (listOfValue?[index].sNo ==
                        6) {
                      return Column(
                        children: [
                          Card(
                            elevation: 0.1,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(
                                '${listOfValue?[index].title}',
                                style: const TextStyle(
                                  fontSize:   14,
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: true,
                              ),
                              trailing: SizedBox(
                                  width: 100,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: TextFormField(
                                          textAlign: TextAlign.center,
                                          onChanged: (text) {
                                            setState(() {
                                              listOfValue?[index].value =
                                                  text;
                                            });
                                          },
                                          keyboardType: const TextInputType
                                              .numberWithOptions(
                                              decimal: true),
                                          decoration: const InputDecoration(
                                              hintText: '0.0',
                                              border: InputBorder.none),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(
                                                    r'^\d{1,2}(\.\d{0,1})?$|^99(\.0)?$|^99\.9$')),
                                            // FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}$')),
                                          ],
                                          initialValue:
                                          listOfValue?[index].value ?? '',
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Warranty is required';
                                            } else {
                                              setState(() {
                                                if (!regex.hasMatch(value)) {
                                                } else {}
                                                listOfValue?[index].value =
                                                    value;
                                              });
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const Align(
                                        alignment: Alignment.centerRight,
                                        child: SizedBox(
                                            width: 30,
                                            child: Text(
                                              'bar',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              softWrap: true,
                                            )),
                                      )
                                    ],
                                  )),
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Card(
                          elevation: 0.1,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: Text(
                              '${listOfValue?[index].title}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              softWrap: true,
                            ),
                            trailing: SizedBox(
                                width: 100,
                                child: TextFormField(
                                  textAlign: TextAlign.center,
                                  onChanged: (text) {
                                    setState(() {
                                      listOfValue?[index].value = text;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                      hintText: '0',
                                      border: InputBorder.none),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  initialValue:
                                  listOfValue?[index].value ?? '',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Warranty is required';
                                    } else {
                                      setState(() {
                                        listOfValue?[index].value = value;
                                      });
                                    }
                                    return null;
                                  },
                                )),
                          ),
                        ),
                      ],
                    );
                  } else if (listOfValue?[index].widgetTypeId == 2) {
                    return Column(
                      children: [
                        Card(
                          elevation: 0.1,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: Text(
                              '${listOfValue?[index].title}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              softWrap: true,
                            ),
                            trailing: SizedBox(
                                width: 80,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white, backgroundColor: Colors.green, // White text color
                                  ),
                                  onPressed: () {
                                    manualonoff(srNo as int);
                                  },
                                  child: const Text('ON/OFF'),
                                )
                            ),
                          ),
                        ),
                      ],
                    );
                  } else if (listOfValue?[index].widgetTypeId == 3) {
                    final dropDownList = [
                      'Stop Irrigation',
                      'Continue Irrigation',
                      'No Fertilization',
                      'Open Valves',
                    ];
                    String dropDownVal = listOfValue?[index].value;
                    dropDownList.contains(dropDownVal) == true
                        ? dropDownVal
                        : dropDownVal = 'Stop Irrigation';

                    return Column(
                      children: [
                        Card(
                          elevation: 0.1,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: Text(
                              '${listOfValue?[index].title}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              softWrap: true,
                            ),
                            trailing: SizedBox(
                              width: 180,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButton(
                                    items: dropDownList.map((String items) {
                                      return DropdownMenuItem(
                                        value: items,
                                        child: Container(
                                            child: Text(
                                              items,
                                            )),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        listOfValue?[index].value = value!;
                                        dropDownVal =
                                            listOfValue?[index].value;
                                      });
                                    },
                                    value: listOfValue?[index].value == ''
                                        ? dropDownList[0]
                                        : listOfValue?[index].value),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else if (listOfValue?[index].widgetTypeId == 5 &&
                      listOfValue?[index].sNo != 1) {
                    return Column(
                      children: [
                        Card(
                          elevation: 0.1,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: Text(
                              '${listOfValue?[index].title}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              softWrap: true,
                            ),
                            trailing: SizedBox(
                              width: 100,
                              child: Container(
                                  child: Center(
                                    child: InkWell(
                                      child: Text(Constants.showHourAndMinuteOnly(
                                          '${listOfValue?[index].value}' != ''
                                            ? '${listOfValue?[index].value}'
                                            : '00:00:00', widget.modelId),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      onTap: () async {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: HoursMinutesSeconds(
                                                  initialTime: '${listOfValue?[index].value}' != ''
                                                      ? '${listOfValue?[index].value}'
                                                      : '00:00:00',
                                                  // initialTime:
                                                  //     '${listOfValue?[index].value}' !=
                                                  //             ''
                                                  //         ? '${listOfValue?[index].value}'
                                                  //         : '00:00:00',
                                                  onPressed: () {
                                                    setState(() {
                                                      listOfValue?[index].value =
                                                      '${overAllPvd.hrs.toString().padLeft(2, '0')}:${overAllPvd.min.toString().padLeft(2, '0')}:${overAllPvd.sec.toString().padLeft(2, '0')}';
                                                    });
                                                    Navigator.pop(context);
                                                  }, modelId: widget.modelId,
                                                ),
                                              );
                                            });
                                      },
                                    ),
                                  )),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        SizedBox(
                          height: Changesize(
                              listOfValue?[index].value.length, 60),
                          width: double.infinity,
                          child: ListView.builder(
                              itemCount:
                              listOfValue?[index].value!.length ?? 0,
                              itemBuilder: (context, flusingindex) {
                                return Column(
                                  children: [
                                    Card(
                                      elevation: 0.1,
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          '${listOfValue?[index].value[flusingindex]['name']} BACKWASH ON TIME',
                                          style: const TextStyle(
                                            fontSize:14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          softWrap: true,
                                        ),
                                        trailing: SizedBox(
                                          width: 90,
                                          child: Container(
                                              child: Center(
                                                child: InkWell(
                                                  child: Text(Constants.showHourAndMinuteOnly
                                                    ('${listOfValue?[index].value![flusingindex]['value']}' !=
                                                        ''
                                                        ? '${listOfValue?[index].value![flusingindex]['value']}'
                                                        : '00:00:00', widget.modelId),
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                  ),
                                                  onTap: () async {
                                                    showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return AlertDialog(
                                                            title:
                                                            HoursMinutesSeconds(
                                                              initialTime:
                                                              '${listOfValue?[0].value![flusingindex]['value']}' !=
                                                                  ''
                                                                  ? '${listOfValue?[0].value![flusingindex]['value']}'
                                                                  : '00:00:00',
                                                              // initialTime:
                                                              //     '${listOfValue?[index].value![flusingindex]['value']}' !=
                                                              //             ''
                                                              //         ? '${listOfValue?[index].value![flusingindex]['value']}'
                                                              //         : '00:00:00',
                                                              onPressed: () {
                                                                setState(() {
                                                                  listOfValue?[index]
                                                                      .value![flusingindex]
                                                                  [
                                                                  'value'] =
                                                                  '${overAllPvd.hrs.toString().padLeft(2, '0')}:${overAllPvd.min.toString().padLeft(2, '0')}:${overAllPvd.sec.toString().padLeft(2, '0')}';
                                                                });
                                                                Navigator.pop(
                                                                    context);
                                                              }, modelId: widget.modelId,
                                                            ),
                                                          );
                                                        });
                                                  },
                                                ),
                                              )),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                        )
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  updatefilterbackwash() async {
    var overAllPvd = Provider.of<OverAllUse>(context,listen: false);
     // List<Map<String, dynamic>> filterBackWash =
    // _filterbackwash.data!.filterBackwashing.map((condition) => condition.toJson()).toList();
    Map<String, dynamic> filterBackWash =
    _filterbackwash.toJson();
    Map<String, dynamic> filterBackWashserverSenddata = {
      "filterBackwashing" : filterBackWash["data"]['filterBackwashing'],
      "controllerReadStatus" : "0",
    };

    String mqttSendData = toMqttFormat(_filterbackwash.data);
    Map<String, dynamic> payLoadFinal = {
      "900": [
        {"901": mqttSendData},
      ]
    };
    final Repository repository = Repository(HttpService());

    Map<String, dynamic> body = {
      "userId": overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId,
      "controllerId": overAllPvd.controllerId,
      "filterBackwash": filterBackWashserverSenddata,
      "hardware":payLoadFinal,
      "createUser": overAllPvd.userId
    };
     var getUserDetails = await repository.UpdateFilterBackwasing(body);
      var jsonDataResponse = jsonDecode(getUserDetails.body);

    if (MqttService().isConnected == true) {
      await validatePayloadSent(
          dialogContext: context,
          context: context,
          mqttPayloadProvider: mqttPayloadProvider,
          acknowledgedFunction: () async{
            setState(() {
              body["controllerReadStatus"] = "1";
            });
          },
          payload: payLoadFinal,
          payloadCode: '900',
          deviceId: overAllPvd.imeiNo
      );
    } else {
      // Map<String, dynamic>
      GlobalSnackBar.show(context, 'MQTT is Disconnected', 201);
    }




    // MQTTManager().publish(payLoadFinal, 'AppToFirmware/${widget.deviceID}');
    GlobalSnackBar.show(context, jsonDataResponse['message'], jsonDataResponse.statusCode);
    // showNavigationDialog(context: context, menuId: widget.menuId, ack: body["filterBackwash"]["controllerReadStatus"] == "1");
    // if (MQTTManager().isConnected == true) {
    //   MQTTManager().publish(payLoadFinal, 'AppToFirmware/${widget.deviceID}');
    //   GlobalSnackBar.show(
    //       context, jsonDataResponse['message'], response.statusCode);
    // } else {
    //   GlobalSnackBar.show(context, 'MQTT is Disconnected', 201);
    // }
  }

  manualonoff(int index) async {
    var overAllPvd = Provider.of<OverAllUse>(context,listen: false);
    String payLoadFinal = jsonEncode({
      "4000": [
        {"4001": index},
      ]
    });
    if (MqttService().isConnected == true) {
      MqttService().topicToPublishAndItsMessage(payLoadFinal, '${Environment.mqttPublishTopic}/${overAllPvd.imeiNo}');
      GlobalSnackBar.show(context, 'Manual ON/OFF Send', 200);
    } else {
      GlobalSnackBar.show(context, 'MQTT is Disconnected', 201);
    }
  }

  String toMqttFormat(
      Data? data,
      ) {
    String mqttData = '';
    for (var i = 0; i < data!.filterBackwashing!.length; i++) {
      double sno = data.filterBackwashing![i].sNo!;
      int id = data.filterBackwashing![i].objectId!;
      List<String> time = [];
      for (var j = 0; j < data.filterBackwashing![i].filter![0].value.length; j++) {
        time.add('${data.filterBackwashing![i].filter![0].value[j]['value']}');
      }
      String flushingTime = time.join('_');
      String filterInterval = data.filterBackwashing![i].filter![1].value!.isEmpty
          ? '00:00:00'
          : '${data.filterBackwashing![i].filter![1].value!}';
      String flushingInterval = data.filterBackwashing![i].filter![2].value!.isEmpty
          ? '00:00:00'
          : '${data.filterBackwashing![i].filter![2].value!}';
      String whileFlushing = '2';
      if (data.filterBackwashing![i].filter![3].value! == 'Continue Irrigation') {
        whileFlushing = '1';
      } else if (data.filterBackwashing![i].filter![3].value! == 'Stop Irrigation') {
        whileFlushing = '2';
      } else if (data.filterBackwashing![i].filter![3].value! == 'No Fertilization') {
        whileFlushing = '3';
      } else if (data.filterBackwashing![i].filter![3].value! == 'Open Valves') {
        whileFlushing = '4';
      }
      String cycles =
      data.filterBackwashing![i].filter![4].value!.isEmpty ? '0' : data.filterBackwashing![i].filter![4].value!;
      String pressureValues =
      data.filterBackwashing![i].filter![5].value!.isEmpty ? '0' : data.filterBackwashing![i].filter![5].value!;
      String deltaPressureDelay = data.filterBackwashing![i].filter![6].value!.isEmpty
          ? '00:00:00'
          : '${data.filterBackwashing![i].filter![6].value!}';
      String dwellTimeMainFilter = data.filterBackwashing![i].filter![8].value!.isEmpty
          ? '00:00:00'
          : '${data.filterBackwashing![i].filter![8].value!}';
      String afterDeltaPressureDelay = data.filterBackwashing![i].filter![7].value!.isEmpty
          ? '00:00:00'
          : '${data.filterBackwashing![i].filter![7].value!}';
      mqttData +=
      '$sno,$id,$flushingTime,$filterInterval,$flushingInterval,$whileFlushing,$cycles,$pressureValues,$deltaPressureDelay,$dwellTimeMainFilter,$afterDeltaPressureDelay;';
    }
    return mqttData;
  }
}
