import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/properties.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/connection_grid_list_tile.dart';
import '../widget/connector_widget.dart';

class Connection extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const Connection({
    super.key,
    required this.configPvd
  });

  @override
  State<Connection> createState() => _ConnectionState();
}

class _ConnectionState extends State<Connection> {
  late Future<bool> updateValuesConnectionPageInitialize;

  @override
  void initState() {
    super.initState();
    updateValuesConnectionPageInitialize = updateConnection();
  }

  Future<bool> updateConnection() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      List<int> listOfCategory = [];
      for (var device in widget.configPvd.listOfDeviceModel) {
        if (![10].contains(device.categoryId) && ![1, 2, 4].contains(device.modelId) &&
            device.masterId != null &&
            !listOfCategory.contains(device.categoryId)) {
          listOfCategory.add(device.categoryId);
        }
      }
      if (listOfCategory.isEmpty) {
        return false;
      }
      widget.configPvd.selectedCategory = listOfCategory[0];
      for (var device in widget.configPvd.listOfDeviceModel) {
        if (device.categoryId == listOfCategory[0] && device.masterId != null) {
          widget.configPvd.selectedModelControllerId = device.controllerId;
          break;
        }
      }
      widget.configPvd.updateSelectedConnectionNoAndItsType(0, '');
      widget.configPvd.updateConnectionListTile();
      print("widget.configPvd.selectedModelControllerId --- : ${widget.configPvd.selectedModelControllerId}");
      return true;
    } catch (e) {
      print('Error in updateConnection: ${e.toString()}');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: updateValuesConnectionPageInitialize,
        builder: (context, snapShot){
          if (snapShot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Show loading
          }
          if (snapShot.hasError) {
            return const Center(child: Text('Error loading data'));
          }
          if(snapShot.hasData && snapShot.data == true){
            DeviceModel selectedDevice = widget.configPvd.listOfDeviceModel.firstWhere((device) => device.controllerId == widget.configPvd.selectedModelControllerId);
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(builder: (context, constraint){
                return SizedBox(
                  width: constraint.maxWidth,
                  height: constraint.maxHeight,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        getAvailableDeviceCategory(),
                        const SizedBox(height: 8,),
                        getModelBySelectedCategory(),
                        const SizedBox(height: 5,),
                        Text(selectedDevice.modelName),
                        if(!AppConstants.weatherModelList.contains(selectedDevice.categoryId))
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              spacing: 20,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if((selectedDevice.noOfRelay == 0 ? selectedDevice.noOfLatch : selectedDevice.noOfRelay) != 0)
                                  getConnectionBox(
                                      selectedDevice: selectedDevice,
                                      color: AppConstants.outputColor,
                                      from: 0,
                                      to: selectedDevice.noOfRelay == 0 ? selectedDevice.noOfLatch : selectedDevice.noOfRelay,
                                      type: '1,2',
                                      typeName: selectedDevice.noOfRelay == 0 ? 'Latch' : 'Relay',
                                      keyWord: selectedDevice.noOfRelay == 0 ? 'L' : 'R'
                                  ),
                                if(selectedDevice.noOfAnalogInput != 0)
                                  getConnectionBox(
                                      selectedDevice: selectedDevice,
                                      color: getObjectTypeCodeToColor(3),
                                      from: 0,
                                      to: selectedDevice.noOfAnalogInput,
                                      type: AppConstants.analogCode,
                                      typeName: 'Analog',
                                      keyWord: 'A'
                                  ),
                                if(selectedDevice.noOfDigitalInput != 0)
                                  getConnectionBox(
                                      selectedDevice: selectedDevice,
                                      color: getObjectTypeCodeToColor(4),
                                      from: 0,
                                      to: selectedDevice.noOfDigitalInput,
                                      type: AppConstants.digitalCode,
                                      typeName: 'Digital',
                                      keyWord: 'D'
                                  ),
                                if(selectedDevice.noOfPulseInput != 0)
                                  getConnectionBox(
                                      selectedDevice: selectedDevice,
                                      color: getObjectTypeCodeToColor(6),
                                      from: 0,
                                      to: selectedDevice.noOfPulseInput,
                                      type: AppConstants.pulseCode,
                                      typeName: 'Pulse',
                                      keyWord: 'P'
                                  ),
                                if(selectedDevice.noOfMoistureInput != 0)
                                  getConnectionBox(
                                      selectedDevice: selectedDevice,
                                      color: getObjectTypeCodeToColor(5),
                                      from: 0,
                                      to: selectedDevice.noOfMoistureInput,
                                      type: AppConstants.moistureCode,
                                      typeName: 'Moisture',
                                      keyWord: 'M'
                                  ),
                                if(selectedDevice.noOfI2CInput != 0)
                                  getConnectionBox(
                                      selectedDevice: selectedDevice,
                                      color: getObjectTypeCodeToColor(7),
                                      from: 0,
                                      to: selectedDevice.noOfI2CInput,
                                      type: AppConstants.i2cCode,
                                      typeName: 'I2c',
                                      keyWord: 'I2c'
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20,),
                        if([...AppConstants.gemModelList, ...AppConstants.omsGemList].contains(widget.configPvd.masterData['modelId']))
                          Center(child: getSelectionCategory()),
                        if(widget.configPvd.selectedSelectionMode == SelectionMode.auto)
                          ...getAutoSelection(selectedDevice)
                        else
                          ...getManualSelection(selectedDevice),
                      ],
                    ),
                  ),
                );
              }),
            );
          }else{
            return const Center(child: CircularProgressIndicator());
          }

        }
    );
  }

  Widget getSelectionCategory(){
    return SegmentedButton<SelectionMode>(
      style: ButtonStyle(
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))
      ),
      segments: [
        getButtonSegment(SelectionMode.auto, "Automatic"),
        getButtonSegment(SelectionMode.manual, "Manual"),
      ],
      selected: {widget.configPvd.selectedSelectionMode},
      onSelectionChanged: (Set<SelectionMode> newSelection) {
        setState(() {
          widget.configPvd.selectedConnectionNo = 0;
          widget.configPvd.selectedSelectionMode = newSelection.first;
        });
      },
    );
  }

  ButtonSegment<SelectionMode> getButtonSegment(SelectionMode value, String title){
    return ButtonSegment<SelectionMode>(
        value: value,
        label: Container(
          width: 100,
          padding: const EdgeInsets.all(15.0),
          child: Text(title, style: const TextStyle(fontSize: 14),),
        )
    );
  }

  List<Widget> getManualSelection(DeviceModel selectedDevice){
    return [
      const Text('Select Object To Connect', style: AppProperties.normalBlackBoldTextStyle,),
      ResponsiveGridList(
        horizontalGridMargin: 20,
        verticalGridMargin: 10,
        minItemWidth: 150,
        shrinkWrap: true,
        listViewBuilderOptions: ListViewBuilderOptions(
          physics: const NeverScrollableScrollPhysics(),
        ),
        children: widget.configPvd.listOfGeneratedObject
            .where((object) => selectedDevice.connectingObjectId.contains(object.objectId)
            && object.controllerId == null || (object.controllerId == selectedDevice.controllerId && object.connectionNo == widget.configPvd.selectedConnectionNo))
            .toList().where((object) => object.type == widget.configPvd.selectedType)
            .map((object){
          print("object name : ${object.name}  type : ${object.type} widget.configPvd.selectedType : ${widget.configPvd.selectedType}");
          bool isSelected = object.controllerId == selectedDevice.controllerId
              && object.type == widget.configPvd.selectedType
              && object.connectionNo == widget.configPvd.selectedConnectionNo;
          return InkWell(
            onTap: (){
              setState(() {
                // remove if there any old connection
                for(var generatedObject in widget.configPvd.listOfGeneratedObject){
                  if(widget.configPvd.selectedConnectionNo == generatedObject.connectionNo && selectedDevice.controllerId == generatedObject.controllerId && generatedObject.type == object.type){
                    generatedObject.controllerId = null;
                    generatedObject.connectionNo = 0;
                    for(var connectionObject in widget.configPvd.listOfObjectModelConnection){
                      if(generatedObject.objectId == connectionObject.objectId){
                        int integerValue = int.parse(connectionObject.count == '' ? '0' : connectionObject.count!);
                        connectionObject.count = (integerValue - 1).toString();
                      }
                    }
                  }
                }
                // update connection for selected object
                for(var generatedObject in widget.configPvd.listOfGeneratedObject){
                  if(object.sNo == generatedObject.sNo){
                    generatedObject.controllerId = selectedDevice.controllerId;
                    generatedObject.connectionNo = widget.configPvd.selectedConnectionNo;
                    for(var connectionObject in widget.configPvd.listOfObjectModelConnection){
                      if(generatedObject.objectId == connectionObject.objectId){
                        int integerValue = int.parse(connectionObject.count == '' ? '0' : connectionObject.count!);
                        connectionObject.count = (integerValue + 1).toString();
                      }
                    }
                  }
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SvgPicture.asset(
                    'assets/Images/Svg/objectId_${object.objectId}.svg',
                    width: 25,
                    height: 25,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  Text('${object.name}', style: isSelected ? AppProperties.tableHeaderStyleWhite : AppProperties.tableHeaderStyle,),
                ],
              ),
            ),
          );
        }).toList(),
      )

    ];
  }

  List<Widget> getAutoSelection(DeviceModel selectedDevice){
    return [
      outputObject(selectedDevice),
      const SizedBox(height: 10,),
      inputObject(title: 'Analog Input', sensorCode: AppConstants.analogCode),
      inputObject(title: 'Digital Input', sensorCode: AppConstants.digitalCode),
      inputObject(title: 'Moisture Input', sensorCode: AppConstants.moistureCode),
      inputObject(title: 'Pulse Input', sensorCode: AppConstants.pulseCode),
      inputObject(title: 'I2c Input', sensorCode: AppConstants.i2cCode),
      // analogObject(),
    ];
  }

  Widget getConnectionBox(
      {
        required DeviceModel selectedDevice,
        required Color color,
        required int from,
        required int to,
        required String type,
        required String typeName,
        required String keyWord,
      }
      ){
    int firstEight = 8;
    if(to < 8){
      firstEight = firstEight - (8 - to);
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      width: to > 8 ? 500 : 250,
      height: 280,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        // border: Border.all(width: 1, color: color),

        boxShadow: AppProperties.customBoxShadowLiteTheme,
        color: Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    for(var count = from;count < firstEight;count++)
                      ...[
                        ConnectorWidget(
                          connectionNo: count + 1,
                          selectedDevice: selectedDevice,
                          configPvd: widget.configPvd,
                          type: type,
                          keyWord: keyWord,
                          color: color,
                        ),
                        const SizedBox(height: 5,),
                      ],
                    if(type == AppConstants.analogCode && selectedDevice.categoryId == 6)
                      ...[
                        ConnectorWidget(
                          connectionNo: 9,
                          selectedDevice: selectedDevice,
                          configPvd: widget.configPvd,
                          type: type,
                          keyWord: '',
                          color: color,
                        ),
                        const SizedBox(height: 5,),
                      ]
                  ],
                ),
              ),
              if(to > 8)
                const SizedBox(width: 10,),
              if(to > 8)
                Expanded(
                  child: Column(
                    children: [
                      for(var count = firstEight;count < to;count++)
                        ...[
                          ConnectorWidget(
                            connectionNo: count + 1,
                            selectedDevice: selectedDevice,
                            configPvd: widget.configPvd,
                            type: type,
                            keyWord: keyWord,
                            color: color,
                          ),
                          const SizedBox(height: 5,)
                        ],
                    ],
                  ),
                ),
            ],
          ),
          Text(typeName, style: TextStyle(color: color, fontWeight: FontWeight.bold),)
        ],
      ),
    );
  }

  Widget changeMode(){
    return IconButton(
        onPressed: (){
          setState(() {
            widget.configPvd.selectedSelectionMode = widget.configPvd.selectedSelectionMode == SelectionMode.auto
                ? SelectionMode.manual
                : SelectionMode.auto;
            widget.configPvd.selectedConnectionNo = 0;
          });
        },
        icon: widget.configPvd.selectedSelectionMode == SelectionMode.auto ? const Icon(Icons.list) : const Icon(Icons.grid_view_outlined)
    );
  }

  Widget outputObject(DeviceModel selectedDevice){
    DeviceModel selectedDevice = widget.configPvd.listOfDeviceModel.firstWhere((device) => device.controllerId == widget.configPvd.selectedModelControllerId);
    List<int> filteredObjectList = widget.configPvd.listOfSampleObjectModel
        .where((object) {
      if(object.objectId == AppConstants.pumpObjectId && AppConstants.ecoGemModelList.contains(widget.configPvd.masterData['modelId'])){
        return false;
      }else{
        return true;
      }
    })
        .where((object) => (object.type == '1,2' && !['', '0', null].contains(object.count)))
        .toList().where((object) => selectedDevice.connectingObjectId.contains(object.objectId)).toList().map((object) => object.objectId)
        .toList();

    List<DeviceObjectModel> filteredList = widget.configPvd.listOfObjectModelConnection.where((object)=> filteredObjectList.contains(object.objectId)).toList();
    filteredList = filteredList.where((object) {
      if(['', '0', null].contains(object.count) && getNotConfiguredObjectByObjectId(object.objectId, widget.configPvd) == 0){
        return false;
      }else{
        return true;
      }
    }).toList();
    return ConnectionGridListTile(
      listOfObjectModel: filteredList,
      title: 'Output Object',
      leadingColor: AppConstants.outputColor,
      configPvd: widget.configPvd,
      selectedDevice: selectedDevice,
    );
  }

  Widget inputObject({
    required String title,
    required String sensorCode,
  }){
    DeviceModel selectedDevice = widget.configPvd.listOfDeviceModel.firstWhere((device) => device.controllerId == widget.configPvd.selectedModelControllerId);
    List<int> filteredObjectList = widget.configPvd.listOfSampleObjectModel
        .where((object) => (object.type == sensorCode && !['', '0', null].contains(object.count)))
        .toList().where((object) => selectedDevice.connectingObjectId.contains(object.objectId)).toList().map((object) => object.objectId)
        .toList();
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfObjectModelConnection.where((object)=> filteredObjectList.contains(object.objectId)).toList();

    filteredList = filteredList.where((object) {
      if(['', '0', null].contains(object.count) && getNotConfiguredObjectByObjectId(object.objectId, widget.configPvd) == 0){
        return false;
      }else{
        return true;
      }
    }).toList();

    return filteredList.isNotEmpty ? ConnectionGridListTile(
      listOfObjectModel: filteredList,
      title: title,
      configPvd: widget.configPvd,
      selectedDevice: selectedDevice,
    ) : Container();
  }

  Widget getAvailableDeviceCategory(){
    List<int> listOfCategory = [];
    for(var device in widget.configPvd.listOfDeviceModel){
      if(![10].contains(device.categoryId) && ![1, 2, 4].contains(device.modelId) &&device.masterId != null && !listOfCategory.contains(device.categoryId)){
        listOfCategory.add(device.categoryId);
      }
    }
    listOfCategory.sort();
    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for(var categoryId in listOfCategory)
              InkWell(
                onTap: (){
                  setState(() {
                    widget.configPvd.selectedCategory = categoryId;
                    for(var device in widget.configPvd.listOfDeviceModel){
                      if(device.categoryId == categoryId && device.masterId != null){
                        widget.configPvd.selectedModelControllerId = device.controllerId;
                        break;
                      }
                    }
                  });
                  widget.configPvd.updateSelectedConnectionNoAndItsType(0, '');
                  widget.configPvd.updateConnectionListTile();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: EdgeInsets.symmetric(horizontal: 15,vertical: widget.configPvd.selectedCategory == categoryId ? 12 :10),
                  decoration: BoxDecoration(
                      border: const Border(top: BorderSide(width: 0.5), left: BorderSide(width: 0.5), right: BorderSide(width: 0.5)),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                      color: widget.configPvd.selectedCategory == categoryId ? Theme.of(context).primaryColor : Colors.grey.shade300
                  ),
                  child: Text(widget.configPvd.listOfDeviceModel.firstWhere((device)=> device.categoryId == categoryId).deviceName, style: TextStyle(color: widget.configPvd.selectedCategory == categoryId ? Colors.white : Colors.black, fontSize: 13),),
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

  Widget getModelBySelectedCategory(){
    List<DeviceModel> filteredDeviceModel =
    widget.configPvd.listOfDeviceModel.where(
            (device) => (
                device.categoryId == widget.configPvd.selectedCategory
                    &&
                    device.masterId != null
                    && ![...AppConstants.ecModel, ...AppConstants.phModel].contains(device.modelId)
            )).toList();
    Widget child = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for(var model in filteredDeviceModel)
            ...[
              InkWell(
                onTap: (){
                  setState(() {
                    widget.configPvd.selectedModelControllerId = model.controllerId;
                  });
                  widget.configPvd.updateConnectionListTile();
                  widget.configPvd.updateSelectedConnectionNoAndItsType(0, '');
                },
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: widget.configPvd.selectedModelControllerId == model.controllerId ? const Color(0xff1C863F) :Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Column(
                      children: [
                        Text(model.deviceName,style: TextStyle(color: widget.configPvd.selectedModelControllerId == model.controllerId ? Colors.white : Colors.black, fontSize: 13),),
                        Text(model.modelDescription,style: TextStyle(color: widget.configPvd.selectedModelControllerId == model.controllerId ? Colors.white : Colors.black, fontSize: 10),),
                        Text(model.deviceId,style: TextStyle(color: widget.configPvd.selectedModelControllerId == model.controllerId ? Colors.amberAccent : Colors.black, fontSize: 10, fontWeight: FontWeight.bold),),
                      ],
                    )
                ),
              ),
              const SizedBox(width: 10,)
            ]
        ],
      ),
    );
    return child;
  }

}

enum SelectionMode {auto, manual}