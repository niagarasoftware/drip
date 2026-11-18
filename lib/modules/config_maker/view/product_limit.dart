import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/properties.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/legend.dart';
import '../widget/product_limit_grid_list_tile.dart';

class ProductLimit extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  List<DeviceModel> listOfDevices;

  ProductLimit({
    super.key,
    required this.listOfDevices,
    required this.configPvd,
  });

  @override
  State<ProductLimit> createState() => _ProductLimitState();
}

class _ProductLimitState extends State<ProductLimit> {

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(builder: (context, productLimitSize){
        return SizedBox(
          width: productLimitSize.maxWidth,
          height: productLimitSize.maxHeight,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...colorLegendBox(screenWidth,screenHeight),
                  if(!AppConstants.pumpWithValveModelList.contains(widget.configPvd.masterData['modelId']) && !AppConstants.weatherGsmModelList.contains(widget.configPvd.masterData['modelId']))
                    commonObject(),
                  outputObject(),
                if(getInputCount(3, widget.listOfDevices) != 0)
                  analogObject(),
                if(getInputCount(4, widget.listOfDevices) != 0)
                  digitalObject(),
                if(getInputCount(5, widget.listOfDevices) != 0)
                  moistureObject(),
                if(getInputCount(6, widget.listOfDevices) != 0)
                  pulseObject(),
                if(getInputCount(7, widget.listOfDevices) != 0)
                  i2cObject()
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget commonObject(){
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel.where((object) => (widget.configPvd.masterData['categoryId'] != 2 ? object.type == '-' : object.objectId == 1)).toList();
    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'Common Object',
      leadingColor: AppConstants.commonObjectColor,
      configPvd: widget.configPvd,
    );
  }

  Widget outputObject(){
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel.where((object) {
      return (object.type == '1,2' && widget.configPvd.getPossibleConnectingObjectId().contains(object.objectId));
    }).toList();
    for(var obj in filteredList){
      print("obj name : ${obj.objectName}");
    }
    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'Output Object',
      leadingColor: AppConstants.outputColor,
      configPvd: widget.configPvd,
    );
  }

  Widget analogObject(){
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel.where((object) => (object.type == '3' && widget.configPvd.getPossibleConnectingObjectId().contains(object.objectId))).toList();
    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'Analog Input',
      configPvd: widget.configPvd,
    );
  }

  Widget digitalObject(){
    print("widget.configPvd.getPossibleConnectingObjectId() : ${widget.configPvd.getPossibleConnectingObjectId()}");
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel.where((object) {
      if(AppConstants.pumpWithValveModelList.contains(widget.configPvd.masterData['modelId'])){
        return (object.type == '4' && widget.configPvd.getPossibleConnectingObjectId().contains(object.objectId));
      }else{
        return (object.type == '4' && widget.configPvd.getPossibleConnectingObjectId().contains(object.objectId));
      }
    }).toList();

    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'Digital Input',
      configPvd: widget.configPvd,
    );
  }

  Widget moistureObject(){
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel.where((object) => object.objectId == AppConstants.moistureObjectId).toList();
    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'Moisture Input',
      configPvd: widget.configPvd,
    );
  }

  Widget pulseObject(){
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel.where((object) => (object.type == '6' && widget.configPvd.getPossibleConnectingObjectId().contains(object.objectId))).toList();
    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'Pulse Input',
      configPvd: widget.configPvd,
    );
  }

  Widget i2cObject(){
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel.where((object) => (object.type == '7' && widget.configPvd.getPossibleConnectingObjectId().contains(object.objectId))).toList();
    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'I2c Input',
      configPvd: widget.configPvd,
    );
  }

  // Widget analogObject(){
  //   print('listOfObjectId : ${widget.configPvd.listOfSampleObjectModel.map((e) => e.objectId)}');
  //   List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel.where((object) => (widget.configPvd.masterData['categoryId'] != 2 ? !['-', '1,2'].contains(object.type) : [22, 24, 26, 40].contains(object.objectId))).toList();
  //   print('filteredList : ${filteredList.map((e) => e.objectId)}');
  //   filteredList.sort((a, b) => a.type.compareTo(b.type));
  //   return ProductLimitGridListTile(
  //     listOfObjectModel: filteredList,
  //     title: 'Input Object',
  //     configPvd: widget.configPvd,
  //   );
  // }

  List<Widget> colorLegendBox(double screenWidth,double screenHeight){
    return [
      const Text('Object Color Legend',style: AppProperties.normalBlackBoldTextStyle),
      const SizedBox(height: 10,),
      Container(
        width: screenWidth > 500 ? null : double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1, color: Theme.of(context).primaryColorDark.withOpacity(0.2)),
        ),
        child: Wrap(
          runSpacing: 10,
          spacing: screenWidth > 500 ? 30 : 10,
          children: [
            ColorLegend(
              color: AppConstants.commonObjectColor,
              message: 'Common Object',
              screenWidth: screenWidth,
            ),
            ColorLegend(
              color: AppConstants.outputColor,
              message: 'Output : ${getRelayLatchCount(widget.listOfDevices) - balanceCountForRelayLatch(widget.configPvd)}/${getRelayLatchCount(widget.listOfDevices)}',
              screenWidth: screenWidth,
            ),
            for(var code in [3, 4, 5, 6, 7])
              if(getInputCount(code, widget.listOfDevices) != 0)
                ColorLegend(
                  color: getObjectTypeCodeToColor(code),
                  message: '${getObjectTypeCodeToString(code)} : ${getInputCount(code, widget.listOfDevices) - balanceCountForInputType(code, widget.configPvd)}/${getInputCount(code, widget.listOfDevices)}',
                  screenWidth: screenWidth,
                ),
          ],
        ),
      )
    ];
  }

}

int getRelayLatchCount(List<DeviceModel> listOfDevices){
  int count = 0;
  for(var node in listOfDevices){
    if(node.masterId != null){
      count += node.noOfRelay;
      count += node.noOfLatch;
    }
  }
  return count;
}

int balanceCountForRelayLatch(ConfigMakerProvider configPvd){
  int totalCount = getRelayLatchCount(configPvd.listOfDeviceModel);
  for(var object in configPvd.listOfSampleObjectModel){
    if(object.type == '1,2'){
      int objectCount = [null, ''].contains(object.count) ? 0 : int.parse(object.count!);
      // update 0 when pump under eco gem. otherwise update
      totalCount -= object.objectId == AppConstants.pumpObjectId && AppConstants.ecoGemModelList.contains(configPvd.masterData['modelId'])  ? 0 : objectCount;
    }
  }
  return totalCount;
}

int getInputCount(int code, List<DeviceModel> listOfDevices){
  int count = 0;
  for(var node in listOfDevices){
    if(node.masterId != null){
      if(code == 3){
        count += node.noOfAnalogInput;
      }else if(code == 4){
        count += node.noOfDigitalInput;
      }else if(code == 5){
        count += node.noOfMoistureInput;
      }else if(code == 6){
        count += node.noOfPulseInput;
      }else{
        count += node.noOfI2CInput;
      }
    }
  }
  return count;
}

int balanceCountForInputType(int code, ConfigMakerProvider configPvd){
  int totalCount = getInputCount(code, configPvd.listOfDeviceModel);
  for(var object in configPvd.listOfSampleObjectModel){
    if(object.type == '$code' && object.objectId != AppConstants.powerSupplyObjectId){
      int objectCount = [null, ''].contains(object.count) ? 0 : int.parse(object.count!);
      totalCount -= objectCount;
    }
  }
  return totalCount;
}