import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/Widgets/custom_buttons.dart';
import 'package:oro_drip_irrigation/Widgets/custom_drop_down_button.dart';
import 'package:oro_drip_irrigation/modules/fertilizer_set/model/fertilizer_site_setting_model.dart';
import 'package:oro_drip_irrigation/modules/fertilizer_set/repository/fertilizer_set_repository.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/constants.dart';
import '../../../Constants/properties.dart';
import '../../../StateManagement/overall_use.dart';
import '../../../Widgets/HoursMinutesSeconds.dart';
import '../../../Widgets/status_box.dart';
import '../../config_maker/view/config_web_view.dart';

enum SelectMode {select, unSelect, selectAll}

class FertilizerSetScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const FertilizerSetScreen({super.key, required this.userData});

  @override
  State<FertilizerSetScreen> createState() => _FertilizerSetScreenState();
}

class _FertilizerSetScreenState extends State<FertilizerSetScreen> {
  late Future<int> fertilizerSetResponse;
  List<FertilizerSiteSettingModel> listOfFertilizerSite = [];
  List<FertilizerSiteSettingModel> listOfFertilizerSet = [];
  int selectedFertilizerSite = 0;
  late ThemeData themeData;
  late bool themeMode;
  HardwareAcknowledgementState payloadState = HardwareAcknowledgementState.notSent;
  List<Map<String, dynamic>> popUpItemList = [
    {'name' : 'Select', 'mode' : SelectMode.select},
    {'name' : 'Unselect', 'mode' : SelectMode.unSelect},
    {'name' : 'Select All', 'mode' : SelectMode.selectAll},
  ];
  SelectMode popUpSelectedValue = SelectMode.unSelect;
  String name = '';
  final formKey = GlobalKey<FormState>();
  FocusNode firstFocus = FocusNode();
  FocusNode secondFocus = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    debugPrint("widget.userData : ${widget.userData}");
    fertilizerSetResponse = getFertilizerSetData(widget.userData);
  }


  Future<int> getFertilizerSetData(Map<String, dynamic>userData)async{
    try{
      var body = {
        "userId": userData['customerId'],
        "controllerId": userData['controllerId'],
      };
      var response = await FertilizerSetRepository().getUserFertilizerSet(body);
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      setState(() {
        listOfFertilizerSite = (jsonData['data']['default']['fertilizerSite'] as List<dynamic>).map((site){
          return FertilizerSiteSettingModel.fromJson(site);
        }).toList();
        listOfFertilizerSet = (jsonData['data']['fertilizerSet'] as List<dynamic>).map((site){
          return FertilizerSiteSettingModel.fromJson(site);
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
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    themeData = Theme.of(context);
    themeMode = themeData.brightness == Brightness.light;
  }


  @override
  Widget build(BuildContext context) {
    var overAllPvd = Provider.of<OverAllUse>(context,listen: true);
    return FutureBuilder<int>(
        future: fertilizerSetResponse,
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
                title: const Text('Fertilizer Set'),
              ): null,
              body: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 10,),
                            getFertilizerSiteTab(),
                            addDeleteSelect(),
                            ResponsiveGridList(
                              horizontalGridSpacing: 20,
                              minItemWidth: 350,
                              shrinkWrap: true,
                              listViewBuilderOptions: ListViewBuilderOptions(
                                physics: const NeverScrollableScrollPhysics(),
                              ),
                              children: [
                                for(var recipe in listOfFertilizerSet)
                                  if(recipe.sNo == listOfFertilizerSite[selectedFertilizerSite].sNo)
                                    Container(
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.white,
                                          boxShadow: AppProperties.customBoxShadowLiteTheme
                                      ),
                                      child: Column(
                                        spacing: 15,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          recipeListTile(recipe),
                                          getEcPh(recipe),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: 30,
                                                  color: themeData.primaryColorLight.withOpacity(0.1),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      tableColumnCell(width: 50 , title: 'Active'),
                                                      tableColumnCell(width: 50, title: 'Channel'),
                                                      tableColumnCell(width: 120, title: 'Method'),
                                                      tableColumnCell(width: 80, title: 'Value'),
                                                    ],
                                                  ),
                                                ),
                                                ...recipe.channel.map((channel) {
                                                  return  Container(
                                                    height: 40,
                                                    color: recipe.channel.indexOf(channel).isOdd ? themeData.primaryColorLight.withOpacity(0.05) : null,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        tableRowCell(
                                                            width: 50,
                                                            widget:  Checkbox(
                                                              value: channel.active == 1 ? true : false,
                                                              onChanged: (value){
                                                                setState(() {
                                                                  channel.active = value! ? 1 : 0;
                                                                });
                                                              },
                                                            )
                                                        ),
                                                        tableRowCell(
                                                            width: 50,
                                                            widget: Text('Ch ${recipe.channel.indexOf(channel) + 1}', style: TextStyle(color: Colors.black54),)
                                                        ),
                                                        tableRowCell(
                                                            width: 120,
                                                            widget : CustomDropDownButton(
                                                              value: channel.method,
                                                              list: ['Time', 'Pro.time', 'Quantity', 'Pro.quantity', 'Pro.quant per 1000L'],
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  channel.method = value!;
                                                                });
                                                              },
                                                              // style: TextStyle(color: channel.method.contains('ime') ? Colors.pink : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                                                            )
                                                          // widget: DropdownButton(
                                                          //   isExpanded: true,
                                                          //   value: channel.method,
                                                          //   underline: Container(),
                                                          //   items: ['Time', 'Pro.time', 'Quantity', 'Pro.quantity', 'Pro.quant per 1000L']
                                                          //       .map((String items) {
                                                          //     return DropdownMenuItem(
                                                          //       value: items,
                                                          //       child: Text(items, style: TextStyle(fontSize: 12, color: Colors.black)),
                                                          //     );
                                                          //   }).toList(),
                                                          //   onChanged: (value) {
                                                          //     setState(() {
                                                          //       channel.method = value!;
                                                          //     });
                                                          //   },
                                                          // )
                                                        ),
                                                        tableRowCell(
                                                            width: 80,
                                                            widget: channel.method.contains('ime')
                                                                ? InkWell(
                                                              onTap: (){
                                                                _showTimePicker(overAllPvd: overAllPvd, time: channel.timeValue, onPressed: (){
                                                                  setState(() {
                                                                    channel.timeValue = '${overAllPvd.hrs < 10 ? '0' :''}${overAllPvd.hrs}:${overAllPvd.min < 10 ? '0' :''}${overAllPvd.min}:${overAllPvd.sec < 10 ? '0' :''}${overAllPvd.sec}';
                                                                  });
                                                                  Navigator.pop(context);
                                                                }) ;
                                                              },
                                                              child: Center(
                                                                child: Text(Constants.showHourAndMinuteOnly(channel.timeValue, widget.userData['modelId'])),
                                                              ),
                                                            )
                                                                : getTextField(
                                                                key: '${recipe.channel.indexOf(channel) + 1} - ${channel.sNo}',
                                                                initialValue: channel.quantityValue,
                                                                regex: AppProperties.regexForDecimal,
                                                                onChanged: (value){
                                                                  setState(() {
                                                                    channel.quantityValue = value;
                                                                  });
                                                                }
                                                            )
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),

                                              ],
                                            ),
                                          ),

                                        ],
                                      ),
                                    )
                              ],
                            ),
                          ],
                        ),
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

  Widget getFloatingActionButton(){
    return FloatingActionButton(
      onPressed: (){
        setState(() {
          payloadState = HardwareAcknowledgementState.notSent;
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
                              stateSetter((){
                                setState(() {
                                  payloadState = HardwareAcknowledgementState.sending;
                                });
                              });
                              sendToHttp();
                              await Future.delayed(const Duration(seconds: 1));
                              stateSetter((){
                                setState(() {
                                  payloadState = HardwareAcknowledgementState.success;
                                });
                              });
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

  void sendToHttp()async{
    var body = {
      "userId" : widget.userData['customerId'],
      "controllerId" : widget.userData['controllerId'],
      'fertilizerSet' : listOfFertilizerSet.map((set) => set.toJson()).toList(),
      "createUser" : widget.userData['userId']
    };
    var response = await FertilizerSetRepository().createUserFertilizerSet(body);
    print('response fertilizerSet : ${response.body}');
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

  Widget tableColumnCell({
    required double width,
    required String title
  }){
    return SizedBox(
      width: width,
      child: Center(child: Text(title)),
    );
  }

  Widget tableRowCell({
    required double width,
    required Widget widget
  }){
    return SizedBox(
        width: width,
        child: Center(child: widget)
    );
  }


  void _showTimePicker({required OverAllUse overAllPvd,required String time, required void Function() onPressed}) async {
    overAllPvd.editTimeAll();
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context,StateSetter stateSetter){
          return AlertDialog(
            surfaceTintColor: Colors.white,
            backgroundColor: Colors.white,
            title: const Column(
              children: [
                Text(
                  'Select time',style: TextStyle(color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: HoursMinutesSeconds(
              initialTime: time,
              onPressed: onPressed,
              modelId: widget.userData['modelId'],
            ),
          );
        });

      },
    );
  }

  Widget getTextField({
    required String key,
    required String initialValue,
    double? width,
    required List<TextInputFormatter>? regex,
    required void Function(String)? onChanged,
  }){
    return Container(
      width:  width ?? 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(width: 1, color: Theme.of(context).primaryColorDark.withOpacity(0.3)),
      ),
      child: TextFormField(
        key: Key(key),
        inputFormatters: regex,
        initialValue: initialValue,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        cursorHeight: 20,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(maxHeight: 30),
          counterText: '',
          border: OutlineInputBorder(
              borderSide: BorderSide.none
          ),
        ),
      ),
    );
  }

  Widget getEcPh(FertilizerSiteSettingModel recipe){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          spacing: 10,
          children: [
            Text('Ec', style: themeData.textTheme.labelLarge,),
            getTextField(
                regex: AppProperties.regexForDecimal,
                key: '${listOfFertilizerSet.indexOf(recipe)} - ec',
                initialValue: recipe.ecValue,
                onChanged: (value){
                  setState(() {
                    recipe.ecValue = value;
                  });
                }),
          ],
        ),
        Row(
          spacing: 10,
          children: [
            Text('Ph', style: themeData.textTheme.labelLarge,),
            getTextField(
                regex: AppProperties.regexForDecimal,
                key: '${listOfFertilizerSet.indexOf(recipe)} - ph',
                initialValue: recipe.phValue,
                onChanged: (value){
                  setState(() {
                    recipe.phValue = value;
                  });
                }),
          ],
        ),
      ],
    );
  }

  Widget recipeListTile(FertilizerSiteSettingModel recipe){
    return ListTile(
      onTap: popUpSelectedValue != SelectMode.unSelect
          ? () {
              setState(() {
                recipe.select = !recipe.select;
              });
            }
          : null,
      leading: popUpSelectedValue != SelectMode.unSelect
          ? Checkbox(
              value: recipe.select,
              onChanged: (bool? value) {
                setState(() {
                  recipe.select = value ?? false;
                });
              },
            )
          : null,
      title: Text(recipe.recipeName, style: themeData.textTheme.labelLarge,),
      trailing: IntrinsicWidth(
        child: Row(
          spacing: 15,
          children: [
            boxButton(
                color: Colors.orange,
                icon: Icons.edit_note_outlined,
                onTap: (){
                  editRecipeName(recipe);
                }
            ),
          ],
        ),
      ),
    );
  }

  void editRecipeName(FertilizerSiteSettingModel recipe){
    final editController = TextEditingController(text: recipe.recipeName);
    final editFormKey = GlobalKey<FormState>();

    showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: const Text('Edit Recipe Name'),
            content: Form(
              key: editFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: editController,
                    textAlign: TextAlign.center,
                    cursorHeight: 20,
                    validator: (value){
                      if(value == null || value.trim().isEmpty){
                        return 'Name must not be empty';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(bottom: 10),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              CustomMaterialButton(
                title: 'Cancel',
                outlined: true,
                onPressed: (){
                  Navigator.pop(context);
                },
              ),
              CustomMaterialButton(
                title: 'Save',
                onPressed: (){
                  if(editFormKey.currentState!.validate()){
                    setState(() {
                      recipe.recipeName = editController.text.trim();
                    });
                    Navigator.pop(context);
                  }
                },
              )
            ],
          );
        }
    );
  }

  Widget boxButton({
    required Color color,
    required IconData icon,
    required void Function()? onTap,
  }){
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3)
        ),
        child: Icon(icon, color: color,),
      ),
    );
  }

  Widget getFertilizerSiteTab(){
    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for(var site = 0; site < listOfFertilizerSite.length;site++)
              InkWell(
                onTap: (){
                  setState(() {
                    selectedFertilizerSite = site;
                    popUpSelectedValue = SelectMode.unSelect;
                    for(var i in listOfFertilizerSet){
                      i.select = false;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: EdgeInsets.symmetric(horizontal: 15,vertical: selectedFertilizerSite == site ? 12 :10),
                  decoration: BoxDecoration(
                      border: const Border(top: BorderSide(width: 0.5), left: BorderSide(width: 0.5), right: BorderSide(width: 0.5)),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                      color: selectedFertilizerSite == site ? Theme.of(context).primaryColor : Colors.grey.shade300
                  ),
                  child: Text(listOfFertilizerSite[site].name, style: TextStyle(color: selectedFertilizerSite == site ? Colors.white : Colors.black, fontSize: 13),),
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

  Widget addDeleteSelect(){
    return Container(
      width: double.infinity,
      height: 60,
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 300,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 10,
          children: [
            if(popUpSelectedValue == SelectMode.unSelect)
              addButton(),
            if(popUpSelectedValue != SelectMode.unSelect)
              deleteButton(),
            popUpButton()
          ],
        ),
      ),
    );
  }

  Widget addButton(){
    return CustomMaterialButton(
      color: Colors.green,
      child: const Row(
        spacing: 10,
        children: [
          Icon(Icons.add,color: Colors.white),
          Text('Add', style: TextStyle(color: Colors.white),)
        ],
      ),
      onPressed: (){
        recipeName();
      },
    );
  }

  Widget deleteButton(){
    return CustomMaterialButton(
      color: Colors.red,
      child: const Row(
        spacing: 10,
        children: [
          Icon(Icons.delete,color: Colors.white),
          Text('Delete', style: TextStyle(color: Colors.white),)
        ],
      ),
      onPressed: (){
        setState(() {
          listOfFertilizerSet = listOfFertilizerSet.where((e) => !e.select).toList();
          popUpSelectedValue = SelectMode.unSelect;
        });
      },
    );
  }

  Widget popUpButton(){
    return PopupMenuButton(
      child: const Row(
        children: [
          Icon(Icons.check_box_outline_blank),
          Icon(Icons.arrow_drop_down_outlined),
        ],
      ),
      itemBuilder: (context){
        return popUpItemList.map((e){
          return PopupMenuItem(
              value: e['mode'],
              child: Text(e['name']!)
          );
        }).toList();
      },
      onSelected: (value){
        setState(() {
          popUpSelectedValue = value as SelectMode;
          if(popUpSelectedValue == SelectMode.selectAll){
            for(var i in listOfFertilizerSet){
              if(listOfFertilizerSite.isNotEmpty && selectedFertilizerSite < listOfFertilizerSite.length){
                if(i.sNo == listOfFertilizerSite[selectedFertilizerSite].sNo){
                  i.select = true;
                }
              } else {
                i.select = true;
              }
            }
          } else if(popUpSelectedValue == SelectMode.unSelect || popUpSelectedValue == SelectMode.select){
            for(var i in listOfFertilizerSet){
              i.select = false;
            }
          }
        });
      },
    );
  }

  void recipeName(){
    showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: const Text('Enter The Name'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    onChanged: (value){
                      setState(() {
                        name = value;
                      });
                    },
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.text,
                    cursorHeight: 20,
                    validator: (value){
                      if(value!.isEmpty){
                        return 'Name must not be empty';
                      }else{
                        return null;
                      }
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(bottom: 10),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              CustomMaterialButton(
                onPressed: (){
                  if(formKey.currentState!.validate()){
                    setState(() {
                      setState(() {
                        listOfFertilizerSet.add(listOfFertilizerSite[selectedFertilizerSite].createRecipe(name));
                        name = '';
                      });
                    });
                    Navigator.pop(context);
                  }
                },
              )
            ],
          );
        }
    );
  }
}