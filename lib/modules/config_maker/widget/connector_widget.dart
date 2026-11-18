import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Widgets/sized_image.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../view/connection.dart';
import '../state_management/config_maker_provider.dart';
import '../../../utils/constants.dart';


class ConnectorWidget extends StatelessWidget {
  final ConfigMakerProvider configPvd;
  final String type;
  final int connectionNo;
  final String keyWord;
  final DeviceModel selectedDevice;
  final Color color;
  const ConnectorWidget({
    super.key,
    required this.connectionNo,
    required this.selectedDevice,
    required this.configPvd,
    required this.type,
    required this.keyWord,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    DeviceObjectModel? object = configPvd.listOfGeneratedObject.cast<DeviceObjectModel?>().firstWhere(
          (object) => object?.controllerId == selectedDevice.controllerId && object?.connectionNo == connectionNo && object?.type == type,
      orElse: () => null as DeviceObjectModel?,
    );
    String? name = object?.name;
    bool selectedConnector = (configPvd.selectedModelControllerId == selectedDevice.controllerId && configPvd.selectedType == type && configPvd.selectedConnectionNo == connectionNo);
    bool themeMode = Theme.of(context).brightness == Brightness.light;
    if(selectedDevice.categoryId == 6 && type == '4' && connectionNo == 5){
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AnimatedContainer(
                width: 20,
                height: 20,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.grey,
                ),
                duration: const Duration(milliseconds: 200),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.grey.shade200
                    ),
                  ),
                ),
              ),
              Container(
                width: 20,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 5,),
              const Text('D5  - Pulse Input')
            ],
          ),
          const SizedBox(height: 5,),
          connector(
              object: object,
              selectedConnector: selectedConnector,
              context: context,
              themeMode: themeMode,
              name: name
          )
        ],
      );
    }
    return connector( 
        object: object,
        selectedConnector: selectedConnector,
        context: context,
        themeMode: themeMode,
        name: name
    );
  }

  Widget connector({required DeviceObjectModel? object, required bool selectedConnector, required BuildContext context, required bool themeMode, required String? name}){
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        InkWell(
          onDoubleTap: configPvd.selectedSelectionMode == SelectionMode.auto ? null :  (){
            if(object != null){
              configPvd.removeSingleObjectFromConfigureToNotConfigure(object);
            }
          },
          onTap: configPvd.selectedSelectionMode == SelectionMode.auto ? null : (){
            configPvd.updateSelectedConnectionNoAndItsType(connectionNo, type);
          },
          child: Row(
            children: [
              AnimatedContainer(
                width: selectedConnector ? 23 : 20,
                height: selectedConnector ? 23 : 20,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: selectedConnector ? Theme.of(context).primaryColorDark : themeMode ? Colors.black : Colors.grey.shade400,
                ),
                duration: const Duration(milliseconds: 200),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: selectedConnector ? Theme.of(context).primaryColorLight : (object != null ? color : Colors.grey.shade200)
                    ),
                  ),
                ),
              ),
              Container(
                width: 20,
                height: 5,
                decoration: BoxDecoration(
                  color: selectedConnector ? Theme.of(context).primaryColorDark : themeMode ? Colors.black : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 5,),
              Text('${getSuitableKeyWord()} - ',style: Theme.of(context).textTheme.bodySmall,)
            ],
          ),
        ),
        const SizedBox(width: 5,),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if(object != null)
                Expanded(child: Text(name.toString(),style: Theme.of(context).textTheme.bodySmall)),
              const SizedBox(width: 5,),
              if(object != null)
                SizedImageSmall(imagePath: '${AppConstants.svgObjectPath}objectId_${object.objectId}.svg')
            ],
          ),
        )
      ],
    );
  }

  String getSuitableKeyWord(){
    String specificSensor = '';
    if(connectionNo == 5 && selectedDevice.categoryId == 6 && selectedDevice.modelId == 3 && type == '3'){
      specificSensor = '(Ph)';
    }else if(connectionNo == 6 && selectedDevice.categoryId == 6 && selectedDevice.modelId == 3 && type == '3'){
      specificSensor = '(Ph)';
    }else if(connectionNo == 7 && selectedDevice.categoryId == 6 && selectedDevice.modelId == 3 && type == '3'){
      specificSensor = '(Ec)';
    }else if(connectionNo == 8 && selectedDevice.categoryId == 6 && selectedDevice.modelId == 3 && type == '3'){
      specificSensor = '(Ec)';
    }else if(connectionNo == 9 && selectedDevice.categoryId == 6 && type == '3'){
      specificSensor = '(ps)';
    }
    // else if(connectionNo == 1 && selectedDevice.categoryId == 5 && type == '3'){
    //   specificSensor = '(Ph)';
    // }else if(connectionNo == 2 && selectedDevice.categoryId == 5 && type == '3'){
    //   specificSensor = '(Ph)';
    // }
    String editConnectionNo = '$connectionNo';
    if(connectionNo == 9 && selectedDevice.categoryId == 6 && type == '3'){
      editConnectionNo = '';
    }
    if(connectionNo == 5 && selectedDevice.categoryId == 6 && type == '4'){
      editConnectionNo = '6';
    }
    return '$keyWord$editConnectionNo$specificSensor';
  }
}