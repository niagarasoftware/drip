import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/admin_dealer/dealer_definition_model.dart';
import '../../StateManagement/overall_use.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/snack_bar.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';


class DealerDefinitionInConfig extends StatefulWidget {
  const DealerDefinitionInConfig(
      {super.key,
        required this.userId,
        required this.customerId,
        required this.controllerId,
        required this.imeiNo});
  final int userId, customerId, controllerId;
  final String imeiNo;

  @override
  State<DealerDefinitionInConfig> createState() =>
      DealerDefinitionInConfigState();
}

class DealerDefinitionInConfigState extends State<DealerDefinitionInConfig> {
  DataModelDDConfig data =
  DataModelDDConfig(categories: [], dealerDefinition: {});
  bool visibleLoading = false;

  @override
  Widget build(BuildContext context) {
    // return wideLayout(data, context);
    if (!kIsWeb) {
      return Material(
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(title: const Text('Dealer Definition'),),
            body: MyContainerWithTabs(
              data: data,
              userID: widget.userId,
              customerID: widget.customerId,
              controllerId: widget.controllerId,
            ),
          ),
        ),
      );
    } else {
      return wideLayout(data, context);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    var overAllPvd = Provider.of<OverAllUse>(context,listen: false);
    final prefs = await SharedPreferences.getInstance();
    try{
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.getdealerDefinition({
        "userId":  widget.customerId,
        "controllerId": widget.controllerId
      });
      // final jsonData = jsonDecode(getUserDetails.body);
      if (getUserDetails.statusCode == 200) {
        setState(() {
          var jsonData = jsonDecode(getUserDetails.body);
          AppLog.log("jsonData:$jsonData");
          data = DataModelDDConfig.fromJson(jsonData);
          indicatorViewHide();
        });
      } else {
        //_showSnackBar(response.body);
      }
    }
    catch (e, stackTrace) {
      AppLog.log(' Error overAll getData => ${e.toString()}');
      AppLog.log(' trace overAll getData  => $stackTrace');
    }
  }


  Widget wideLayout(DataModelDDConfig data, BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return visibleLoading
        ? Center(
      child: Visibility(
        visible: visibleLoading,
        child: Container(
          padding: EdgeInsets.fromLTRB(mediaQuery.size.width / 2 - 115, 0,
              mediaQuery.size.width / 2 - 115, 0),
          child: const LoadingIndicator(
            indicatorType: Indicator.ballPulse,
          ),
        ),
      ),
    )
        : Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.categories.length,
              itemBuilder: (context, index) {
                final category = data.categories[index];
                return buildCategoryContainer(category, data);
              },
            ),
          ),
          Container(
            height: 50,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {

                    final sendData = jsonEncode(data.dealerDefinition);
                    final Repository repository = Repository(HttpService());
                    Map<String, Object> body = {
                      "userId": widget.customerId,
                      "controllerId": widget.controllerId,
                      "dealerDefinition": data.dealerDefinition,
                      "createUser": widget.userId
                    };
                    var getUserDetails = await repository.createdealerDefinition(body);
                    final jsonDataResponseput = json.decode(getUserDetails.body);
                    GlobalSnackBar.show(context, jsonDataResponseput['message'], jsonDataResponseput['code']);
                  },
                  label: const Text(' Save'),
                  icon: const Icon(
                    Icons.save_as_outlined,
                  ),style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Theme.of(context).primaryColor,),foregroundColor: WidgetStateProperty.all<Color>(Colors.white)),),
                const SizedBox(
                  width: 20,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String Mqttdata(DataModelDDConfig dmConfig) {
    String mqttFormatData = '';
    for (var i = 0; i < dmConfig.categories.length; i++) {
      int k = dmConfig.categories[i].categoryId;
      for (var j = 0; j < dmConfig.dealerDefinition['$k']!.length; j++) {
        mqttFormatData +=
        '${dmConfig.dealerDefinition['$k']![j].dealerDefinitionId},$k,${dmConfig.dealerDefinition['$k']![j].value.isNotEmpty ? dmConfig.dealerDefinition['$k']![j].value : '0'};';
      }
    }
    return mqttFormatData;
  }

  Widget buildCategoryContainer(Category category, DataModelDDConfig data) {
    if (data.categories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Container(
      width: 350.0,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1.0,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      margin: const EdgeInsets.only(left: 5, right: 5),
      child: Column(
        children: [
          buildFixedRow(category.categoryName),
          Expanded(
            child: buildDealerDefinitionList(category, data),
          ),
        ],
      ),
    );
  }

  Widget buildFixedRow(String categoryName) {
    return Container(
      height: 45.0,
      color: Theme.of(context).primaryColor,
      child: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Center(
            child:
            Text(categoryName, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget buildDealerDefinitionList(Category category, DataModelDDConfig data) {
    return ListView.builder(
      itemCount: data.dealerDefinition['${category.categoryId}']?.length ?? 0,
      itemBuilder: (context, index) {
        final definition =
        data.dealerDefinition['${category.categoryId}']?[index];
        return buildDealerDefinitionItem(definition, category);
      },
    );
  }

  Widget buildDealerDefinitionItem(
      DealerDefinition? definition, Category category)
  {
    final dropdownlist =
    StringToList().stringtolist('${definition?.dropdownValues}', ',');
    int iconcode = int.parse(definition?.iconCodePoint ?? "0xe123");
    String iconfontfamily = definition?.iconFontFamily ?? "MaterialIcons";

    if (definition?.widgetTypeId == 3) {
      return buildDropdownItem(
          definition, dropdownlist, iconcode, iconfontfamily);
    } else if (definition?.widgetTypeId == 1) {
      return buildTextFieldItem(definition, iconcode, iconfontfamily);
    } else {
      return buildSwitchItem(definition, iconcode, iconfontfamily);
    }
  }

  Widget buildDropdownItem(DealerDefinition? definition,
      List<String> dropdownlist, int iconcode, String iconfontfamily)
  {
    return Column(
      children: [
        ListTile(
          // leading: Icon(IconData(iconcode, fontFamily: iconfontfamily)),
          title: Text(
            '${definition?.parameter}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          subtitle: Text('${definition?.description}',
              style:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
          trailing: DropdownButton(
            items: dropdownlist.map((String items) {
              return DropdownMenuItem(
                value: items,
                child: Container(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(items)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                definition?.value = value!;
              });
            },
            value: definition?.value == ''
                ? dropdownlist[0].toString()
                : definition?.value,
          ),
        ),
      ],
    );
  }

  Widget buildTextFieldItem(
      DealerDefinition? definition, int iconcode, String iconfontfamily)
  {
    return Column(
      children: [
        ListTile(
          //leading: Icon(IconData(iconcode, fontFamily: iconfontfamily)),
          title: Text(
            '${definition?.parameter}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          subtitle: Text('${definition?.description}',
              style:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
          trailing: SizedBox(
            width: 50,
            child: CustomTextField(
              onChanged: (text) {
                setState(() {
                  definition?.value = text;
                });
              },
              initialValue: definition?.value ?? '0',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Warranty is required';
                } else {
                  setState(() {
                    definition?.value = value;
                  });
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSwitchItem(
      DealerDefinition? definition, int iconcode, String iconfontfamily)
  {

    int? rtcindex = data.dealerDefinition["1"]?.indexWhere((element) => element.dealerDefinitionId == 33);
    int? rtcmaxindex = data.dealerDefinition["1"]?.indexWhere((element) => element.dealerDefinitionId == 34);
    int? stopmethod = data.dealerDefinition["1"]?.indexWhere((element) => element.dealerDefinitionId == 35);

    if (definition?.dealerDefinitionId == 33 ||
        definition?.dealerDefinitionId == 34 ||
        definition?.dealerDefinitionId == 35) {
      if (definition?.dealerDefinitionId == 33){
        return Column(
          children: [
            ListTile(
              title: Text(
                '${definition?.parameter}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.normal),
              ),
              subtitle: Text('${definition?.description}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.normal)),
              trailing: MySwitch(
                value: definition?.value == '1',
                onChanged: ((value) {
                  setState(() {
                    definition?.value = !value ? '0' : '1';
                    if (value) {
                      data.dealerDefinition["1"]![rtcmaxindex!].value = '0';
                      data.dealerDefinition["1"]![stopmethod!].value = '0';
                    }
                  });
                }),
              ),
            ),
          ],
        );
      }
      else if (definition?.dealerDefinitionId == 34){
        return Column(
          children: [
            ListTile(
              title: Text(
                '${definition?.parameter}',
                style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
              subtitle: Text('${definition?.description}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.normal)),
              trailing: MySwitch(
                value: definition?.value == '1',
                onChanged: ((value) {
                  setState(() {
                    definition?.value = !value ? '0' : '1';
                    if (value) {
                      data.dealerDefinition["1"]![rtcindex!].value = '0';
                      data.dealerDefinition["1"]![stopmethod!].value = '0';
                    }
                  });
                }),
              ),
            ),
          ],
        );
      }
      else{
        return Column(
          children: [
            ListTile(
              title: Text(
                '${definition?.parameter}',
                style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
              subtitle: Text('${definition?.description}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.normal)),
              trailing: MySwitch(
                value: definition?.value == '1',
                onChanged: ((value) {
                  setState(() {
                    definition?.value = !value ? '0' : '1';
                    if (value) {
                      data.dealerDefinition["1"]![rtcindex!].value = '0';
                      data.dealerDefinition["1"]![rtcmaxindex!].value = '0';
                    }
                  });
                }),
              ),
            ),
          ],
        );
      }
    }else {
      return Column(
        children: [
          ListTile(
            //leading: Icon(IconData(iconcode, fontFamily: iconfontfamily)),

            title: Text(
              '${definition?.parameter}',
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
            subtitle: Text('${definition?.description}',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.normal)),
            trailing: MySwitch(
              value: definition?.value == '1',
              onChanged: ((value) {
                setState(() {
                  definition?.value = !value ? '0' : '1';
                });
              }),
            ),
          ),
        ],
      );
    }
  }

  void indicatorViewShow() {
    setState(() {
      visibleLoading = true;
    });
  }

  void indicatorViewHide() {
    setState(() {
      visibleLoading = false;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class MyContainerWithTabs extends StatefulWidget {
  const MyContainerWithTabs(
      {super.key,
        required this.data,
        required this.userID,
        required this.customerID,
        required this.controllerId});
  final DataModelDDConfig data;
  final int userID, customerID, controllerId;

  @override
  State<MyContainerWithTabs> createState() => _MyContainerWithTabsState();
}

class _MyContainerWithTabsState extends State<MyContainerWithTabs> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey.shade50,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  DefaultTabController(
                    length: widget.data.categories.length, // Number of tabs
                    child: Column(
                      children: [
                        TabBar(
                          indicatorColor:
                          const Color.fromARGB(255, 175, 73, 73),
                          isScrollable: true,
                          tabs: [
                            for (var i = 0;
                            i < widget.data.categories.length;
                            i++)
                              Tab(
                                text: widget.data.categories[i].categoryName,
                              ),
                          ],
                          onTap: (value) {},
                        ),
                        const SizedBox(height: 10.0),
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height - 310,
                          child: TabBarView(
                            children: [
                              for (var i = 0;
                              i < widget.data.categories.length;
                              i++)
                                widget.data.categories[i].categoryName.isEmpty
                                    ? Container()
                                    : buildTab(widget.data.dealerDefinition[
                                '${widget.data.categories[i].categoryId}']),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 60,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {

                    final sendData = jsonEncode(widget.data.dealerDefinition);
                    final Repository repository = Repository(HttpService());
                    Map<String, Object> body = {
                      "userId": widget.customerID,
                      "controllerId": widget.controllerId,
                      "dealerDefinition": widget.data.dealerDefinition,
                      "createUser": widget.userID
                    };
                    var getUserDetails = await repository.createdealerDefinition(body);
                    final jsonDataResponseput = json.decode(getUserDetails.body);
                    GlobalSnackBar.show(context, jsonDataResponseput['message'], jsonDataResponseput['code']);
                  },
                  label: const Text('Save'),
                  icon: const Icon(
                    Icons.save_as_outlined,
                  ),style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Theme.of(context).primaryColor,),foregroundColor: WidgetStateProperty.all<Color>(Colors.white)),),

                const SizedBox(
                  width: 20,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTab(List<DealerDefinition>? Listofvalue) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: Listofvalue?.length ?? 0,
            itemBuilder: (context, index) {


              if (Listofvalue?[index].widgetTypeId == 3) {
                final dropdownlist = StringToList().stringtolist(
                  '${Listofvalue?[index].dropdownValues}',
                  ',',
                );

                return Column(
                  children: [
                    Container(
                      child: ListTile(
                        title: Text('${Listofvalue?[index].parameter}'),
                        subtitle: Text(
                          'Details: ${Listofvalue?[index].description}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        // leading: Icon(IconData(iconcode, fontFamily: iconfontfamily)),
                        trailing: Container(
                          color: Colors.white,
                          width: 140,
                          child: DropdownButton(
                            items: dropdownlist.map((String items) {
                              return DropdownMenuItem(
                                value: items,
                                child: Container(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(items)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                Listofvalue?[index].value = value!;
                              });
                            },
                            value: Listofvalue?[index].value == ''
                                ? dropdownlist[0].toString()
                                : Listofvalue?[index].value,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else if (Listofvalue?[index].widgetTypeId == 1) {

                return Column(
                  children: [
                    Container(
                      child: ListTile(
                        title: Text('${Listofvalue?[index].parameter}'),
                        subtitle: Text(
                          'Details: ${Listofvalue?[index].description}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        //leading: Icon(IconData(iconcode, fontFamily: iconfontfamily)),
                        trailing: SizedBox(
                            width: 50,
                            child: CustomTextField(
                              onChanged: (text) {
                                setState(() {
                                  Listofvalue?[index].value = text;
                                });
                              },
                              initialValue: Listofvalue?[index].value ?? '0',
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
                            )
                        ),
                      ),
                    ),
                    // const Padding(
                    //   padding: EdgeInsets.only(
                    //     left: 70,
                    //   ),
                    //   child: Divider(
                    //     height: 1.0,
                    //     color: Colors.grey,
                    //   ),
                    // ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Container(
                      child: ListTile(
                        title: Text('${Listofvalue?[index].parameter}'),
                        subtitle: Text(
                          'Details: ${Listofvalue?[index].description}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        // leading: Icon(IconData(iconcode, fontFamily: iconfontfamily)),
                        trailing: MySwitch(
                          value: Listofvalue?[index].value == '1',
                          onChanged: ((value) {
                            setState(() {
                              Listofvalue?[index].value = !value ? '0' : '1';
                            });
                            // Listofvalue?[index].value = value;
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              }

            },
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class StringToList {
  List<String> stringtolist(
      String name,
      String split,
      ) {
    var f = name.split(split);
    return f;
  }
}

class MySwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const MySwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<MySwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<MySwitch> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: Switch(value: widget.value, onChanged: widget.onChanged),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? initialValue;

  final IconData? prefixIcon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.initialValue,
    this.prefixIcon,
    this.obscureText = false,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      initialValue: initialValue,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
      validator: (text) {
        if (text == null || text.isEmpty) {
          return 'Please enter a username.';
        }
        return null;
      },
    );
  }
}