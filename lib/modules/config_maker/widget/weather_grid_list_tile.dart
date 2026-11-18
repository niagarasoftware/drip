import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Widgets/sized_image.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/properties.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../utils/constants.dart';

class WeatherGridListTile extends StatefulWidget {
  final DeviceModel device;
  final ConfigMakerProvider configPvd;
  Color? leadingColor;
  WeatherGridListTile({
    super.key,
    required this.configPvd,
    required this.device,
    this.leadingColor,
  });

  @override
  State<WeatherGridListTile> createState() => _WeatherGridListTileState();
}

class _WeatherGridListTileState extends State<WeatherGridListTile> with SingleTickerProviderStateMixin{
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  List<Map<String, dynamic>> weatherData = [
    {'objectId' : 25, 'name' : 'Moisture 1'},
    {'objectId' : 25, 'name' : 'Moisture 2'},
    {'objectId' : 25, 'name' : 'Moisture 3'},
    {'objectId' : 25, 'name' : 'Moisture 4'},
    {'objectId' : 30, 'name' : 'Soil Temperature'},
    {'objectId' : 36, 'name' : 'Humidity'},
    {'objectId' : 29, 'name' : 'Temperature'},
    {'objectId' : 41, 'name' : 'Atmospheric Pressure'},
    {'objectId' : 33, 'name' : 'Co2'},
    {'objectId' : 35, 'name' : 'Ldr'},
    {'objectId' : 34, 'name' : 'Lux'},
    {'objectId' : 31, 'name' : 'Wind Direction'},
    {'objectId' : 32, 'name' : 'Wind Speed'},
    {'objectId' : 38, 'name' : 'Rain Fall'},
    {'objectId' : 37, 'name' : 'Leaf Wetness'}
  ];

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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5,),
        ResponsiveGridList(
          horizontalGridMargin: 20,
          verticalGridMargin: 10,
          minItemWidth: 250,
          shrinkWrap: true,
          listViewBuilderOptions: ListViewBuilderOptions(
            physics: const NeverScrollableScrollPhysics(),
          ),
          children: [
              for(var sensor = 0;sensor < weatherData.length;sensor++)
                objectTile(sensor)
          ]
        ),
      ],
    );
  }

  Widget objectTile(object){
    Widget myWidget = ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      title: Text(weatherData[object]['name'], style: AppProperties.listTileBlackBoldStyle,),
      leading: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
        ),
        child: SizedImage(
          imagePath: '${AppConstants.svgObjectPath}objectId_${weatherData[object]['objectId']}.svg',
        ),
      ),
      // trailing: Checkbox(
      //     value: widget.device.weatherModel![object],
      //     onChanged: (value){
      //
      //     }
      // )
    );
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          boxShadow: AppProperties.customBoxShadowLiteTheme
      ),
      width: 300,
      child: myWidget,
    );
  }
  int getConfiguredObjectByObjectId(int objectId){
    List<DeviceObjectModel> configured = widget.configPvd.listOfGeneratedObject.where((object) => (object.objectId == objectId && object.controllerId != null)).toList();
    return configured.length;
  }
  bool dependentObjectByCommonObject(int objectId){
    bool visible = true;
    if(objectIdDependsOnDosing.contains(objectId)){
      //filter object by dosing site
      DeviceObjectModel dosingObject = widget.configPvd.listOfSampleObjectModel.firstWhere((object) => object.objectId == 3);
      if(dosingObject.count == '0'){
        visible = false;
      }
    }else if(objectIdDependsOnFiltration.contains(objectId)){
      DeviceObjectModel filtrationObject = widget.configPvd.listOfSampleObjectModel.firstWhere((object) => object.objectId == 4);
      if(filtrationObject.count == '0'){
        visible = false;
      }
    }else if(objectIdDependsOnTank.contains(objectId)){
      DeviceObjectModel tankObject = widget.configPvd.listOfSampleObjectModel.firstWhere((object) => object.objectId == 1);
      if(tankObject.count == '0'){
        visible = false;
      }
    }else if([31, 32, 34, 35, 37, 38].contains(objectId)){
      bool weatherDeviceAvailable = widget.configPvd.listOfDeviceModel.any((device) => device.categoryId == 4);
      if(!weatherDeviceAvailable){
        visible = false;
      }
    }else if([15, 16, 17, 18, 19, 20, 21].contains(objectId)){
      bool gemModel3Available = widget.configPvd.listOfDeviceModel.any((device) => (device.categoryId == 4 && device.modelId == 3));
      if(!gemModel3Available){
        visible = false;
      }
    }

    return visible;
  }

}

List<int> objectIdDependsOnDosing = [7, 8, 10, 27, 28];
List<int> objectIdDependsOnFiltration = [11, 12];
List<int> objectIdDependsOnTank = [5, 26, 39];
