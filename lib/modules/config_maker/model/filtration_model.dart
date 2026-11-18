import 'device_object_model.dart';
import 'irrigation_line_model.dart';

class FiltrationModel {
  DeviceObjectModel commonDetails;
  int siteMode;
  List<Filter> filters;
  double pressureIn;
  double pressureOut;
  double backWashValve;

  FiltrationModel({
    required this.commonDetails,
    this.siteMode = 1,
    required this.filters,
    this.pressureIn = 0.0,
    this.pressureOut = 0.0,
    this.backWashValve = 0.0,
  });

  factory FiltrationModel.fromJson(data){
    DeviceObjectModel deviceObjectModel = DeviceObjectModel.fromJson(data);
    List<Filter> listOfFilter = [];
    for(var filter in data["filters"]){
      if(filter is double){
        listOfFilter.add(Filter.fromJson({"sNo" : filter, "filterMode" : 1}));
      }else{
        listOfFilter.add(Filter.fromJson(filter));
      }
    }
    return FiltrationModel(
        commonDetails: deviceObjectModel,
        siteMode: data['siteMode'],
        filters: listOfFilter,
        pressureIn: intOrDoubleValidate(data['pressureIn']),
        pressureOut: intOrDoubleValidate(data['pressureOut']) ,
        backWashValve: intOrDoubleValidate(data['backWashValve']),
    );
  }

  void updateObjectIdIfDeletedInProductLimit(List<double> objectIdToBeDeleted){
    filters = filters.where((objectId) => !objectIdToBeDeleted.contains(objectId.sNo)).toList();
    pressureIn = objectIdToBeDeleted.contains(pressureIn) ? 0.0 : pressureIn;
    pressureOut = objectIdToBeDeleted.contains(pressureOut) ? 0.0 : pressureOut;
    backWashValve = objectIdToBeDeleted.contains(backWashValve) ? 0.0 : backWashValve;
  }

  Map<String, dynamic> toJson(){
    var commonInfo = commonDetails.toJson();
    commonInfo.addAll({
      'siteMode' : siteMode,
      'filters' : filters.map((filter) => filter.toJson()).toList(),
      'pressureIn' : pressureIn,
      'pressureOut' : pressureOut,
      'backWashValve' : backWashValve,
    });
    return commonInfo;
  }
}

class Filter{
  final double sNo;
  int filterMode;
  Filter({
    required this.sNo,
    this.filterMode = 1,
  });

  factory Filter.fromJson(data){
    return Filter(
        sNo: data['sNo'],
        filterMode: data['filterMode'] ?? 1
    );
  }


  Map<String, dynamic> toJson(){
    return {
      'sNo' : sNo,
      'filterMode' : filterMode
    };
  }
}