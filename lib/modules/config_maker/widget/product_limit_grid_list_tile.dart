import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Widgets/sized_image.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/toggle_text_form_field_product_limit.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/communication_codes.dart';
import '../model/device_object_model.dart';
import '../view/product_limit.dart';
import '../state_management/config_maker_provider.dart';
import '../../../utils/constants.dart';
import 'blinking_container.dart';

class ProductLimitGridListTile extends StatefulWidget {
  final List<DeviceObjectModel> listOfObjectModel;
  final ConfigMakerProvider configPvd;
  final String title;
  Color? leadingColor;

  ProductLimitGridListTile({
    super.key,
    required this.listOfObjectModel,
    required this.title,
    required this.configPvd,
    this.leadingColor,
  });

  @override
  State<ProductLimitGridListTile> createState() => _ProductLimitGridListTileState();
}

class _ProductLimitGridListTileState extends State<ProductLimitGridListTile> with SingleTickerProviderStateMixin{
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Total duration of 2 blinks
    );

    // Define the color animation
    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.red,
    ).animate(_controller);
    _startBlinking();
  }

  void _startBlinking() async {
    for (int i = 0; i < 2; i++) {
      await _controller.forward(); // Blink to red
      await _controller.reverse(); // Blink back to white
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(widget.title,style: Theme.of(context).textTheme.headlineLarge,),
        ),
        ResponsiveGridList(
          horizontalGridMargin: 20,
          verticalGridMargin: 10,
          minItemWidth: 250,
          shrinkWrap: true,
          listViewBuilderOptions: ListViewBuilderOptions(
            physics: const NeverScrollableScrollPhysics(),
          ),
          children: [
            for(var object in widget.listOfObjectModel)
              if(['-', '1,2'].contains(object.type)  || getInputCount(int.parse(object.type), widget.configPvd.listOfDeviceModel) != 0)
                if(dependentObjectByCommonObject(object.objectId))
                  objectTile(object)
          ],
        ),
      ],
    );
  }

  Widget objectTile(DeviceObjectModel object){
    bool themeMode = Theme.of(context).brightness == Brightness.light;
    Color typeColor = widget.leadingColor ?? getObjectTypeCodeToColor(int.parse(object.type));
    Widget myWidget = ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      title: Text(object.objectName, style: Theme.of(context).textTheme.labelLarge, overflow: TextOverflow.ellipsis,),
      subtitle: Text('Configured : ${getConfiguredObjectByObjectId(object.objectId)}', style: Theme.of(context).textTheme.labelSmall,),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: SizedImage(
          imagePath: '${AppConstants.svgObjectPath}objectId_${object.objectId}.svg',
        ),
      ),
      trailing: SizedBox(
        width: 80,
        child: ToggleTextFormFieldForProductLimit(
          leadingColor: typeColor,
          configPvd: widget.configPvd,
          initialValue: object.count.toString(),
          object: object,
        ),
      ),
    );
    if(widget.configPvd.noticeableObjectId.contains(object.objectId)){
      return BlinkingContainer(child: myWidget);
    }else{
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border(left: BorderSide(width: 3, color: typeColor)),
          color: Theme.of(context).cardColor,
          boxShadow: const [
            BoxShadow(color: Colors.grey, blurRadius: 5)
          ],
          // boxShadow: AppProperties.customBoxShadowLiteTheme
        ),
        width: 300,
        child: myWidget,
      );
    }
  }

  int getConfiguredObjectByObjectId(int objectId){
    List<DeviceObjectModel> configured = widget.configPvd.listOfGeneratedObject.where((object) => (object.objectId == objectId && object.controllerId != null)).toList();
    return configured.length;
  }

  bool dependentObjectByCommonObject(int objectId){
    bool visible = true;
    /*hide waterSource for pump with valve model*/
    if(AppConstants.pumpWithValveModelList.contains(widget.configPvd.masterData['modelId'])){
      if (kDebugMode) {
        print('master ::: pump with valve model');
      }
    }
    else if(AppConstants.ecoGemModelList.contains(widget.configPvd.masterData['modelId']) && !AppConstants.ecoGemFlowControlValveModel.contains(widget.configPvd.masterData['modelId'])){
      if (kDebugMode) {
        print('master ::: eco gem');
      }
      List<int> objectThatConfigureToEcoGemModel = [1, 2, 3, 4, 5, 7, 9, 10, 11, 13, 22, 24, 25, 26, 30, 40];
      if(objectThatConfigureToEcoGemModel.contains(objectId)){
        visible = true;
      }else{
        visible = false;
      }
    }else if(AppConstants.aquacultureModelList.contains(widget.configPvd.masterData['modelId'])){
      if (kDebugMode) {
        print('master ::: BCH gem');
      }
      List<int> objectThatConfigureToBchModel = [1, 2, 5, 40];
      if(objectThatConfigureToBchModel.contains(objectId)){
        visible = true;
      }else{
        visible = false;
      }
    }
    else{
      if (kDebugMode) {
        print('master ::: gem');
      }
      if(objectIdDependsOnDosing.contains(objectId)){
        //filter object by dosing site
        DeviceObjectModel dosingObject = widget.configPvd.listOfSampleObjectModel.firstWhere((object) => object.objectId == 3);
        if(dosingObject.count == '0'){
          visible = false;
        }
      }
      else if(objectIdDependsOnFiltration.contains(objectId)){
        DeviceObjectModel filtrationObject = widget.configPvd.listOfSampleObjectModel.firstWhere((object) => object.objectId == 4);
        if(filtrationObject.count == '0'){
          visible = false;
        }
      }
      else if(objectIdDependsOnTank.contains(objectId)){
        DeviceObjectModel tankObject = widget.configPvd.listOfSampleObjectModel.firstWhere((object) => object.objectId == 1);
        if(tankObject.count == '0'){
          visible = false;
        }
      }
      else if([31, 32, 34, 35, 37, 38].contains(objectId)){
        bool weatherDeviceAvailable = widget.configPvd.listOfDeviceModel.any((device) => device.categoryId == 4);
        if(!weatherDeviceAvailable){
          visible = false;
        }
      }
      // else if([15, 16, 17, 18, 20, 21].contains(objectId)){
      //   bool gemModel3Available = widget.configPvd.listOfDeviceModel.any((device) => (device.categoryId == 4 && device.modelId == 3));
      //   if(!gemModel3Available){
      //     visible = false;
      //   }
      // }
    }

    if (kDebugMode) {
      print('objectId ($objectId) - $visible');
    }

    return visible;
  }
}

List<int> objectIdDependsOnDosing = [7, 8, 10, 27, 28];
List<int> objectIdDependsOnFiltration = [11, 12];
List<int> objectIdDependsOnTank = [5, 26, 40];