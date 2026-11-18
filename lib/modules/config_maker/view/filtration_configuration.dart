import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../Constants/properties.dart';
import '../model/device_object_model.dart';
import '../model/filtration_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/custom_drop_down_button.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';

class FiltrationConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const FiltrationConfiguration({super.key, required this.configPvd});

  @override
  State<FiltrationConfiguration> createState() => _FiltrationConfigurationState();
}

class _FiltrationConfigurationState extends State<FiltrationConfiguration> {
  late ThemeData themeData;
  late bool themeMode;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    themeData = Theme.of(context);
    themeMode = themeData.brightness == Brightness.light;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(builder: (context, constraint){
        double ratio = constraint.maxWidth < 500 ? 0.6 : 1.0;
        return SizedBox(
          width: constraint.maxWidth,
          height: constraint.maxHeight,
          child:  SingleChildScrollView(
            child: ResponsiveGridList(
              horizontalGridMargin: 0,
              verticalGridMargin: 10,
              minItemWidth: 500,
              shrinkWrap: true,
              listViewBuilderOptions: ListViewBuilderOptions(
                physics: const NeverScrollableScrollPhysics(),
              ),
              children: [
                for(var filtrationSite in widget.configPvd.filtration)
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                        boxShadow: AppProperties.customBoxShadowLiteTheme
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IntrinsicWidth(
                          stepWidth: 200,
                          child: ListTile(
                            leading: SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_4.svg', color: Colors.black,),
                            title: Text(filtrationSite.commonDetails.name!),
                            trailing: IntrinsicWidth(
                              child: CustomDropDownButton(
                                  value: getCentralLocalCodeToString(filtrationSite.siteMode),
                                  list: const ['Central', 'Local'],
                                  onChanged: (value){
                                    setState(() {
                                      filtrationSite.siteMode = getCentralLocalStringToCode(value!);
                                    });
                                  }
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 200,
                          alignment: Alignment.center,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if(filtrationSite.filters.length == 1)
                                    FiltrationDashboardFormation(filtrationFormation: FiltrationFormation.singleFilter, filtrationSite: filtrationSite),
                                  if(filtrationSite.filters.length > 1)
                                    FiltrationDashboardFormation(filtrationFormation: FiltrationFormation.multipleFilter, filtrationSite: filtrationSite)
                                ],
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_11.svg', color: Colors.black,),
                            const SizedBox(width: 20,),
                            const Text('Filter : ', style: AppProperties.listTileBlackBoldStyle,),
                            SizedBox(
                              width: 150,
                              child: Center(
                                child: Text(filtrationSite.filters.isEmpty ? '-' : filtrationSite.filters.map((filter) => getObjectName(filter.sNo, widget.configPvd).name!).join(', '), style: TextStyle(color: themeData.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),),
                              ),
                            ),
                            IconButton(
                                onPressed: (){
                                  setState(() {
                                    widget.configPvd.listOfSelectedSno.clear();
                                    List<double> listOfFilterSno = filtrationSite.filters.map((filter) => filter.sNo).toList();
                                    widget.configPvd.listOfSelectedSno.addAll(listOfFilterSno);
                                  });
                                  selectionDialogBox(
                                      context: context,
                                      title: 'Select Filters',
                                      singleSelection: false,
                                      listOfObject: getUnselectedFilterObject(filtrationSite),
                                      onPressed: (){
                                        setState(() {
                                          filtrationSite.filters.clear();
                                          List<Filter> listOfFilter = widget.configPvd.listOfSelectedSno.map((sNo) => Filter.fromJson({"sNo" : sNo, "filterMode" : 1})).toList();
                                          filtrationSite.filters.addAll(listOfFilter);
                                          widget.configPvd.listOfSelectedSno.clear();
                                        });
                                        Navigator.pop(context);
                                      }
                                  );
                                },
                                icon: Icon(Icons.touch_app, color: themeData.primaryColor, size: 20,)
                            )
                          ],
                        ),
                        Row(
                          children: [
                            SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_24.svg', color: Colors.black,),
                            const SizedBox(width: 20,),
                            const Text('Pressure In : ', style: AppProperties.listTileBlackBoldStyle,),
                            SizedBox(
                              width: 150,
                              child: Center(
                                child: Text(filtrationSite.pressureIn == 0.0 ? '-' : getObjectName(filtrationSite.pressureIn, widget.configPvd).name!, style: TextStyle(color: themeData.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),),
                              ),
                            ),
                            IconButton(
                                onPressed: (){
                                  setState(() {
                                    widget.configPvd.selectedSno = filtrationSite.pressureIn;
                                  });
                                  selectionDialogBox(
                                      context: context,
                                      title: 'Select Pressure In',
                                      singleSelection: true,
                                      listOfObject: getPressureSensor(filtrationSite, 1),
                                      onPressed: (){
                                        setState(() {
                                          filtrationSite.pressureIn = widget.configPvd.selectedSno;
                                          widget.configPvd.selectedSno = 0.0;
                                        });
                                        Navigator.pop(context);
                                      }
                                  );
                                },
                                icon: Icon(Icons.touch_app, color: themeData.primaryColor, size: 20,)
                            )
                          ],
                        ),
                        Row(
                          children: [
                            SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_24.svg', color: Colors.black,),
                            const SizedBox(width: 20,),
                            const Text('Pressure Out : ', style: AppProperties.listTileBlackBoldStyle,),
                            SizedBox(
                              width: 150,
                              child: Center(
                                child: Text(filtrationSite.pressureOut == 0.0 ? '-' : getObjectName(filtrationSite.pressureOut, widget.configPvd).name!, style: TextStyle(color: themeData.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),),
                              ),
                            ),
                            IconButton(
                                onPressed: (){
                                  setState(() {
                                    widget.configPvd.selectedSno = filtrationSite.pressureOut;
                                  });
                                  selectionDialogBox(
                                      context: context,
                                      title: 'Select Pressure Out',
                                      singleSelection: true,
                                      listOfObject: getPressureSensor(filtrationSite, 2),
                                      onPressed: (){
                                        setState(() {
                                          filtrationSite.pressureOut = widget.configPvd.selectedSno;
                                          widget.configPvd.selectedSno = 0.0;
                                        });
                                        Navigator.pop(context);
                                      }
                                  );
                                },
                                icon: Icon(Icons.touch_app, color: themeData.primaryColor, size: 20,)
                            )
                          ],
                        ),
                      ],
                    ),
                  )
              ],
            ),
          ),

        );
      }),
    );
  }

  List<DeviceObjectModel> getUnselectedFilterObject(FiltrationModel filtrationSite){
    List<DeviceObjectModel> filterObject = widget.configPvd.listOfGeneratedObject
        .where((object) => object.objectId == 11)
        .toList();
    List<double> assignedFilters = [];
    List<double> unAssignedFilters = [];
    for(var site in widget.configPvd.filtration){
      for(var filter in site.filters){
        assignedFilters.add(filter.sNo);
      }
    }
    List<double> filterSnoOfFiltrationSite = filtrationSite.filters.map((filter) => filter.sNo).toList();
    filterObject = filterObject.where((object) => (!assignedFilters.contains(object.sNo!) || filterSnoOfFiltrationSite.contains(object.sNo))).toList();
    return filterObject;
  }

  List<DeviceObjectModel> getPressureSensor(FiltrationModel filtrationSite, int pressureMode){
    List<double> assignedPressureSensor = [];
    List<double> sensorList = [];
    for(var filtration in widget.configPvd.filtration){
      if(filtration.pressureIn != 0.0){
        assignedPressureSensor.add(filtration.pressureIn);
      }
      if(filtration.pressureOut != 0.0){
        assignedPressureSensor.add(filtration.pressureOut);
      }
    }
    for(var object in widget.configPvd.listOfGeneratedObject){
      double currentPressureSno = pressureMode == 1 ?  filtrationSite.pressureIn : filtrationSite.pressureOut;
      if(currentPressureSno == object.sNo || (!assignedPressureSensor.contains(object.sNo) && object.objectId == 24)){
        sensorList.add(object.sNo!);
      }
    }
    return widget.configPvd.listOfGeneratedObject.where((generatedObject) => sensorList.contains(generatedObject.sNo)).toList();
  }
}


enum FiltrationFormation {singleFilter, multipleFilter}

class FiltrationDashboardFormation extends StatefulWidget {
  FiltrationFormation filtrationFormation;
  FiltrationModel filtrationSite;
  FiltrationDashboardFormation({
    super.key,
    required this.filtrationFormation,
    required this.filtrationSite,
  });

  @override
  State<FiltrationDashboardFormation> createState() => _FiltrationDashboardFormationState();
}

class _FiltrationDashboardFormationState extends State<FiltrationDashboardFormation> {
  late ConfigMakerProvider configPvd;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: true);
    if(widget.filtrationFormation == FiltrationFormation.singleFilter){
      return singleFilter();
    }else{
      return multipleFilter();
    }
  }
  Widget firstHorizontalPipe(){
    return SizedBox(
      width: 60 * configPvd.ratio,
      height: 150 * configPvd.ratio,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/Images/Filtration/horizontal_pipe_4.svg',
              width: 60,
              height: 8 * configPvd.ratio,
            ),
          ),
          Positioned(
            top: 22 * configPvd.ratio,
            right: 0,
            child: SvgPicture.asset(
              'assets/Images/Filtration/horizontal_pipe_0.svg',
              width: 60,
              height: 8 * configPvd.ratio,
            ),
          ),
          if(widget.filtrationSite.pressureIn != 0.0)
            Positioned(
              top: 30,
              left: 15,
              child: Image.asset(
                'assets/Images/Png/objectId_24.png',
                width: 30,
                height: 30,
              ),
            ),
        ],
      ),
    );
  }
  Widget secondHorizontalPipe(){
    return SizedBox(
      width: 60,
      height: 150 * configPvd.ratio,
      child: Stack(
        children: [
          Positioned(
            bottom: 2 * configPvd.ratio,
            child: SvgPicture.asset(
              'assets/Images/Filtration/horizontal_pipe_4.svg',
              width: 60 * configPvd.ratio,
              height: 8 * configPvd.ratio,
            ),
          ),
          if(widget.filtrationSite.pressureOut != 0.0)
            Positioned(
              right: 15,
              bottom: 10,
              child: Image.asset(
                'assets/Images/Png/objectId_24.png',
                width: 30,
                height: 30,
              ),
            ),

        ],
      ),
    );
  }
  Widget singleFilter(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        firstHorizontalPipe(),
        Stack(
          children: [
            FilterModeSelectionWidget(
              filterIndex: 0,
                filtrationSite: widget.filtrationSite,
                child: SvgPicture.asset(
                  'assets/Images/Filtration/single_filter_4.svg',
                  width: 150,
                  height: 150 * configPvd.ratio,
                )
            ),
            if(widget.filtrationSite.filters[0].filterMode == 2)
              Positioned(
                bottom: 40,
                left: 47,
                child: FilterModeSelectionWidget(
                    filtrationSite: widget.filtrationSite,
                    filterIndex: 0,
                    child: SvgPicture.asset(
                      'assets/Images/Filtration/disc.svg',
                      color: Theme.of(context).primaryColor,
                      width: 50,
                      height: 50 * configPvd.ratio,
                    )
                ),
              ),
            Positioned(
              left : 20,
              top: 6 * configPvd.ratio,
              child: Text(getObjectName(widget.filtrationSite.filters[0].sNo, configPvd).name!,style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),),
            ),
          ],
        ),
        secondHorizontalPipe(),
      ],
    );
  }
  Widget multipleFilter(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        firstHorizontalPipe(),
        if(widget.filtrationSite.filters.isNotEmpty)
          multipleFilterFirstFilter(widget.filtrationSite.filters[0].sNo,),
        if(widget.filtrationSite.filters.length > 2)
          for(var middleFilter = 1;middleFilter < widget.filtrationSite.filters.length - 1;middleFilter++)
            multipleFilterMiddleFilter(widget.filtrationSite.filters[middleFilter].sNo),
        if(widget.filtrationSite.filters.length > 1)
          multipleFilterLastFilter(widget.filtrationSite.filters[widget.filtrationSite.filters.length - 1].sNo),
        secondHorizontalPipe(),
      ],
    );
  }
  Widget multipleFilterFirstFilter(double filterSno){
    DeviceObjectModel filterObject = configPvd.listOfGeneratedObject.firstWhere((object) => object.sNo == filterSno);
    return Stack(
      children: [
        FilterModeSelectionWidget(
            filterIndex: 0,
            filtrationSite: widget.filtrationSite,
            child: SvgPicture.asset(
              'assets/Images/Filtration/multiple_filter_first_4.svg',
              width: 150,
              height: 150 * configPvd.ratio,
            ),
        ),
        if(widget.filtrationSite.filters[0].filterMode == 2)
          Positioned(
            bottom: 40,
            left: 37,
            child: FilterModeSelectionWidget(
                filtrationSite: widget.filtrationSite,
                filterIndex: 0,
                child: SvgPicture.asset(
                  'assets/Images/Filtration/disc.svg',
                  color: Theme.of(context).primaryColor,
                  width: 50,
                  height: 50 * configPvd.ratio,
                )
            ),
          ),
        Positioned(
          top: 20 * configPvd.ratio,
          child: SvgPicture.asset(
            'assets/Images/Filtration/multiple_filter_first_backwash_pipe_0.svg',
            width: 150,
            height: 17.3 * configPvd.ratio,
          ),
        ),
        Positioned(
          left : 20,
          top: 6,
          child: Text(getObjectName(filterSno, configPvd).name!,style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),),
        ),
      ],
    );
  }
  Widget multipleFilterMiddleFilter(double filterSno){
    DeviceObjectModel filterObject = configPvd.listOfGeneratedObject.firstWhere((object) => object.sNo == filterSno);
    int filterIndex = widget.filtrationSite.filters.indexWhere((filter) => filter.sNo == filterSno);
    return Stack(
      children: [
        FilterModeSelectionWidget(
          filterIndex: filterIndex,
          filtrationSite: widget.filtrationSite,
          child: SvgPicture.asset(
            'assets/Images/Filtration/multiple_filter_middle_4.svg',
            width: 150,
            height: 150 * configPvd.ratio,
          ),
        ),
        if(widget.filtrationSite.filters[filterIndex].filterMode == 2)
          Positioned(
            bottom: 40,
            left: 47,
            child: FilterModeSelectionWidget(
                filtrationSite: widget.filtrationSite,
                filterIndex: filterIndex,
                child: SvgPicture.asset(
                  'assets/Images/Filtration/disc.svg',
                  width: 50,
                  height: 50 * configPvd.ratio,
                    color: Theme.of(context).primaryColor
                )
            ),
        ),
        Positioned(
          top: 20 * configPvd.ratio,
          child: SvgPicture.asset(
            'assets/Images/Filtration/multiple_filter_middle_backwash_pipe_0.svg',
            width: 150,
            height: 17.1 * configPvd.ratio,
          ),
        ),
        Positioned(
          left : 20,
          top: 6,
          child: Text(getObjectName(filterSno, configPvd).name!,style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),),
        ),

      ],
    );
  }
  Widget multipleFilterLastFilter(double filterSno){
    DeviceObjectModel filterObject = configPvd.listOfGeneratedObject.firstWhere((object) => object.sNo == filterSno);
    return Stack(
      children: [
        FilterModeSelectionWidget(
          filterIndex: widget.filtrationSite.filters.length - 1,
          filtrationSite: widget.filtrationSite,
          child: SvgPicture.asset(
            'assets/Images/Filtration/multiple_filter_last_4.svg',
            width: 150,
            height: 150 * configPvd.ratio,
          ),
        ),
        if(widget.filtrationSite.filters[widget.filtrationSite.filters.length - 1].filterMode == 2)
          Positioned(
          bottom: 40,
          left: 47,
          child: FilterModeSelectionWidget(
              filtrationSite: widget.filtrationSite,
              filterIndex: widget.filtrationSite.filters.length - 1,
              child: SvgPicture.asset(
                'assets/Images/Filtration/disc.svg',
                width: 50,
                height: 50 * configPvd.ratio,
                color: Theme.of(context).primaryColor,
              )
          ),
        ),
        Positioned(
          bottom: 0,
          child: SvgPicture.asset(
            'assets/Images/Filtration/multiple_filter_last_bottom_filtration_pipe_4.svg',
            width: 150,
            height: 17 * configPvd.ratio,
          ),
        ),
        Positioned(
          left : 20,
          top: 6,
          child: Text(getObjectName(filterSno, configPvd).name!,style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),),
        ),
      ],
    );
  }
}

class FilterModeSelectionWidget extends StatefulWidget {
  final FiltrationModel filtrationSite;
  final Widget child;
  final int filterIndex;
  const FilterModeSelectionWidget({super.key, required this.child, required this.filtrationSite, required this.filterIndex});

  @override
  State<FilterModeSelectionWidget> createState() => _FilterModeSelectionWidgetState();
}

class _FilterModeSelectionWidgetState extends State<FilterModeSelectionWidget> {
  late ConfigMakerProvider configPvd;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: true);
    return InkWell(
      child: widget.child,
      onTap: (){
        showDialog(context: context, builder: (context){
          return StatefulBuilder(builder: (context,stateSetter){
            return AlertDialog(
              title: Text('Select Filter Type'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                      title: const Text("Sand filter"),
                      value: 1,
                      groupValue: widget.filtrationSite.filters[widget.filterIndex].filterMode,
                      onChanged: (value){
                        stateSetter((){
                          setState(() {
                            configPvd.updateFilterMode(widget.filtrationSite, widget.filterIndex, value!);
                          });
                        });

                      }),
                  RadioListTile(
                    title: const Text("Disc filter"),
                    value: 2,
                    groupValue: widget.filtrationSite.filters[widget.filterIndex].filterMode,
                    onChanged: (value) {
                      stateSetter((){
                        setState(() {
                          configPvd.updateFilterMode(widget.filtrationSite, widget.filterIndex, value!);
                        });
                      });

                    },
                  )
                ],
              ),
            );
          });

        });
      },
    );
  }
}