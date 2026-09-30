import 'package:flutter/cupertino.dart';
import 'enums.dart';
import 'environment.dart';

class AppConstants {
  static String apiUrl = Environment.apiUrl;
  static const int timeoutDuration = 30;
  static String mqttUrlMobile = Environment.mqttMobileUrl;
  static String userManualBaseUrl = Environment.userManualBaseUrl;


  static String mqttUrl = Environment.mqttWebUrl;
  static int mqttWebPort = Environment.mqttWebPort;
  static int mqttMobilePort = Environment.mqttMobilePort;
  static String mqttMobileUrl = Environment.mqttMobileUrl;
  static String mqttUserName = Environment.mqttUserName;
  static String mqttPassword = Environment.mqttPassword;

  static String publishTopic = Environment.mqttPublishTopic;
  static String subscribeTopic = Environment.mqttSubscribeTopic;

  static const String appTitle = 'ORO DRIP IRRIGATION';
  static const String appShortContent = 'Drip irrigation is a type of watering system used in agriculture, gardening, and landscaping to efficiently deliver water directly to the roots of plants.';

  static const String formHeaderForAdmin = 'ORO DRIP IRRIGATION';

  static const String fullName = 'Full Name';
  static const String mobileNumber = 'Mobile Number';
  static const String emailAddress = 'Email Address';
  static const String country = 'Country';
  static const String state = 'State';
  static const String city = 'City';
  static const String address = 'Address';
  static const pleaseFillDetails = 'Please fill out all the details correctly.';
  static const enterValidEmail = 'Please enter a valid email';
  static const nameValidationError = 'Name must not contain numbers or special characters';

  static const String pngPath = "assets/png/";
  static const String pngPathMobile = "assets/png/mobile/";
  static const String gifPath = "assets/gif/";
  static const String svgObjectPath = 'assets/Images/Svg/';

  static const String boreWellFirst = "dp_bore_well_first.png";
  static const String boreWellCenter = "dp_bore_well_center.png";

  static const String tankFirst = "dp_tank_first.png";
  static const String tankCenter = "dp_tank_center.png";

  static const String mobileBoreWellFirst = "m_bore_well_first.png";
  static const String mobileBoreWellCenter= "m_bore_well_center.png";

  static const String wellFirst = "dp_well_first.png";
  static const String wellCenter = "dp_well_center.png";
  static const String wellLast = "dp_well_last.png";

  static const String mobileWellFirst = "m_well_first.png";
  static const String mobileWellCenter = "m_well_center.png";

  static const String sumpFirst = "dp_sump_first.png";
  static const String sumpCenter = "dp_sump_center.png";
  static const String sumpLast = "dp_sump_last.png";
  static const String sumpFirstCWS = "dp_sump_first_cws.png";

  static const String mobileSumpFirst = "m_sump_first.png";
  static const String mobileSumpCenter = "m_sump_center.png";

  static const String pumpOFF = "dp_irr_pump.png";
  static const String pumpON = "dp_irr_pump_g.gif";
  static const String pumpNotON = "dp_irr_pump_y.png";
  static const String pumpNotOFF = "dp_irr_pump_r.png";

  static const String frtPumpOFF = "dp_pump.png";
  static const String frtPumpON = "dp_pump_green.gif";
  static const String frtPumpNotON = "dp_pump_orange.png";
  static const String frtPumpNotOFF = "dp_pump_red.png";

  static const String frtValveOFF = "valve_grey_wol.png";
  static const String frtValveON = "valve_green_wol.gif";
  static const String frtValveNotON = "valve_orange_wol.png";
  static const String frtValveNotOFF = "valve_red_wol.png";

  static const String frtBoosterOFF = "booster_pump.png";
  static const String frtBoosterON = "booster_pump_g.gif";
  static const String frtBoosterNotON = "booster_pump_o.png";
  static const String frtBoosterNotOFF = "booster_pump_r.png";

  static const String mblPumpOFF = "m_pump_first_g.png";
  static const String mblPumpON = "m_pump_first.gif";
  static const String mblPumpNotON = "m_pump_first_y.png";
  static const String mblPumpNotOFF = "m_pump_first_r.png";

  static const String aeratorPumpOFF = "aerators_grey.png";
  static const String aeratorPumpON = "aerators_g.gif";
  static const String aeratorPumpNotON = "aerators_o.png";
  static const String aeratorPumpNotOFF = "aerators_r.png";

  static const String filterOFF = "dp_filter.png";
  static const String filterON = "dp_filter_g.png";
  static const String filterNotON = "dp_filter_y.png";
  static const String filterNotOFF = "dp_filter_r.png";

  static const String mobileFilterOFF = "m_dp_filter.png";
  static const String mobileFilterON = "m_dp_filter_g.png";
  static const String mobileFilterNotON = "m_dp_filter_y.png";
  static const String mobileFilterNotOFF = "m_dp_filter_r.png";

  static const String mobileSandFilterOFF = "ms_dp_filter.png";
  static const String mobileSandFilterON = "ms_dp_filter_g.png";
  static const String mobileSandFilterNotON = "ms_dp_filter_y.png";
  static const String mobileSandFilterNotOFF = "ms_dp_filter_r.png";

  static const String boosterPumpOFF = "dp_frt_booster_pump.png";
  static const String boosterPumpON = "dp_frt_booster_pump_g.gif";
  static const String boosterPumpNotON = "dp_frt_booster_pump_y.png";
  static const String boosterPumpNotOFF = "dp_frt_booster_pump_r.png";

  static const String soilMoistureSensor = "moisture_sensor.png";
  static const String pressureSensor = "pressure_sensor.png";
  static const String levelSensor = "level_sensor.png";

  static const String agitatorOFF = "dp_agitator_right.png";
  static const String agitatorON = "dp_agitator_right_g.gif";
  static const String agitatorNotON = "dp_agitator_right_y.png";
  static const String agitatorNotOFF = "dp_agitator_right_r.png";

  static const String mainValveOFF = "main_valve_gray.png";
  static const String mainValveON = "main_valve_green.png";
  static const String mainValveNotON = "main_valve_orange.png";
  static const String mainValveNotOFF = "main_valve_red.png";

  static const String valveOFF = "valve_gray.png";
  static const String valveRunning = "valve_green.png";
  static const String valveCompleted= "valve_blue.png";
  static const String valveNotON = "valve_orange.png";
  static const String valveNotOFF = "valve_red.png";
  static const String valvePending = "valve_yellow.png";

  static const String valveLjOFF = "valve_gray_lj.png";
  static const String valveLjRunning = "valve_green_lj.png";
  static const String valveLjCompleted= "valve_blue_lj.png";
  static const String valveLjNotON = "valve_orange_lj.png";
  static const String valveLjNotOFF = "valve_red_lj.png";
  static const String valveLjPending = "valve_yellow_lj.png";

  static const String valveCwsOFF = "valve_gray_cws.png";
  static const String valveCwsRunning = "valve_green_cws.png";
  static const String valveCwsCompleted = "valve_blue_cws.png";
  static const String valveCwsNotON = "valve_orange_cws.png";
  static const String valveCwsNotOFF = "valve_red_cws.png";
  static const String valveCwsPending = "valve_yellow_cws.png";

  static const String lightOFF = "light_gray.png";
  static const String lightON = "light_yellow.png";

  static const String mblLightOFF = "m_light_gray.png";
  static const String mblLightON = "m_light_yellow.png";
  static const String mblLightNotOFF = "m_light_orange.png";
  static const String mblLightNotON = "m_light_red.png";

  static const String fanOFF = "fan_grey.png";
  static const String fanON = "fan_green.png";
  static const String fanNotOFF = "fan_orange.png";
  static const String fanNotON = "fan_red.png";

  static const String mblFanOFF = "m_fan_grey.png";
  static const String mblFanON = "m_fan_green.gif";
  static const String mblFanNotOFF = "m_fan_orange.png";
  static const String mblFanNotON = "m_fan_red.png";



  static const String gateOFF = "gate_close.png";
  static const String gateON = "gate_open.png";

  static final Map<UserRole, String> formTitle = {
    UserRole.admin: "Dealer Account Form",
    UserRole.dealer: "Customer Account Form",
    UserRole.subUser: "Sub User Account Form",
  };

  static final Map<UserRole, String> nameErrors = {
    UserRole.admin: "Please enter your dealer name",
    UserRole.dealer: "Please enter your customer name",
    UserRole.subUser: "Please enter your sub-user name",
  };

  static final Map<UserRole, String> mobileErrors = {
    UserRole.admin: "Please enter your dealer mobile number",
    UserRole.dealer: "Please enter your customer mobile number",
    UserRole.subUser: "Please enter your sub-user mobile number",
  };

  static final Map<UserRole, String> emailErrors = {
    UserRole.admin: "Please enter your dealer email",
    UserRole.dealer: "Please enter your customer email",
    UserRole.subUser: "Please enter your sub-user email",
  };

  static final Map<UserRole, String> countryErrors = {
    UserRole.admin: "Please select your dealer country",
    UserRole.dealer: "Please select your customer country",
    UserRole.subUser: "Please select your sub-user country",
  };

  static final Map<UserRole, String> stateErrors = {
    UserRole.admin: "Please select your dealer state",
    UserRole.dealer: "Please select your customer state",
    UserRole.subUser: "Please select your sub-user state",
  };

  static final Map<UserRole, String> cityErrors = {
    UserRole.admin: "Please enter your dealer city",
    UserRole.dealer: "Please enter your customer city",
    UserRole.subUser: "Please enter your sub-user city",
  };

  static final Map<UserRole, String> addressErrors = {
    UserRole.admin: "Please enter your dealer address",
    UserRole.dealer: "Please enter your customer address",
    UserRole.subUser: "Please enter your sub-user address",
  };

  final Widget anlOvrView = const Text('Analytics Overview',style: TextStyle(fontSize: 20));
  final Widget txtSNo = const Text('S.No');
  final Widget txtCategory = const Text('Category');
  final Widget txtModel = const Text('Model');
  final Widget txtIMEI = const Text('IMEI');
  final Widget txtMDate = const Text('M.Date');
  final Widget txtWarranty = const Text('Warranty');
  final Widget txtSoldOut = const Text('SOLD OUT',style: TextStyle(fontSize: 18));


  static String getErrorMessage(UserRole role, Map<UserRole, String> errorMap) {
    return errorMap[role] ?? "Invalid role";
  }

  static String getFormTitle(UserRole role) => getErrorMessage(role, formTitle);

  static String getNameError(UserRole role) =>
      getErrorMessage(role, nameErrors);

  static String getMobileError(UserRole role) =>
      getErrorMessage(role, mobileErrors);

  static String getEmailError(UserRole role) =>
      getErrorMessage(role, emailErrors);

  static String getCountryError(UserRole role) =>
      getErrorMessage(role, countryErrors);

  static String getStateError(UserRole role) =>
      getErrorMessage(role, stateErrors);

  static String getCityError(UserRole role) =>
      getErrorMessage(role, cityErrors);

  static String getAddressError(UserRole role) =>
      getErrorMessage(role, addressErrors);

  static Widget getAsset(String keyOne, int keyTwo, String keyThree, int cpr) {
    String imagePathFinal;
    switch (keyOne) {
      case 'source':
        imagePathFinal = _getSourceImagePath(keyTwo, keyThree);
      case 'mobile source':
        imagePathFinal = _getMobileSourceImagePath(keyTwo, keyThree);
        break;
      case 'pump':
        imagePathFinal = _getPumpImagePath(keyTwo);
        break;
      case 'mobile pump':
        imagePathFinal = _getMobilePumpImagePath(keyTwo, keyThree);
        break;
      case 'aerator':
        imagePathFinal = _getAeratorPumpImagePath(keyTwo, keyThree);
        break;
      case 'filter':
        imagePathFinal = _getFilterImagePath(keyTwo);
        break;
      case 'mobile filter':
        imagePathFinal = _getMobileFilterImagePath(keyTwo, int.parse(keyThree));
        break;
      case 'booster':
        imagePathFinal = _getBoosterImagePath(keyTwo);
      case 'sensor':
        imagePathFinal = _getSensorImagePath(keyThree);
        break;
      case 'agitator':
        imagePathFinal = _getAgitatorImagePath(keyTwo);
        break;
      case 'main_valve':
        imagePathFinal = _getMainValveImagePath(keyTwo);
      case 'valve':
        imagePathFinal = _getValveImagePath(keyTwo, cpr);
        break;
      case 'valve_lj':
        imagePathFinal = _getValveLjImagePath(keyTwo, cpr);
        break;
      case 'valve_cws':
        imagePathFinal = _getValveCWSImagePath(keyTwo, cpr);
        break;
      case 'light':
        imagePathFinal = _getLightImagePath(keyTwo);
        break;
      case 'light_mbl':
        imagePathFinal = _getLightImagePathMobile(keyTwo);
        break;
      case 'fan':
        imagePathFinal = _getFanImagePath(keyTwo);
        break;
      case 'fan_mbl':
        imagePathFinal = _getFanImagePathMobile(keyTwo);
        break;
      case 'gate':
        imagePathFinal = _getGateImagePath(keyTwo);
        break;

      default:
        imagePathFinal = '';
    }

    if (imagePathFinal.contains('.gif')) {
      return Image.asset(
        '$gifPath$imagePathFinal',
        key: UniqueKey(),
        fit: BoxFit.fill,
      );
    }

    return Image.asset(
      '${(keyOne == 'mobile pump' || keyOne == 'mobile source'
          || keyOne == 'mobile filter'|| keyOne == 'mobile booster'|| keyOne == 'fan_mbl') ?
      pngPathMobile : pngPath}$imagePathFinal',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.fill,
    );
  }

  static Widget getAssetForFrtLive(String item, int status) {
    String imagePathFinal;
    switch (item) {
      case 'pump':
        imagePathFinal = _getFLPPumpImagePath(status);
      case 'valve':
        imagePathFinal = _getFLPValveImagePath(status);
        break;
      case 'booster':
        imagePathFinal = _getFLPBoosterImagePath(status);
        break;

      default:
        imagePathFinal = '';
    }

    return Image.asset(
      '$pngPath$imagePathFinal',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.fill,
    );
  }

  static String _getSourceImagePath(int type, String position) {
    switch (position) {
      case 'First':
        return type==4 ? boreWellFirst : type==3 ? wellFirst : type==1 ? tankFirst : sumpFirst;
      case 'Center':
        return type==4 ? boreWellCenter : type==3 ? wellCenter : type==1 ? tankCenter : sumpCenter;
      case 'Last':
        return type==4 ? boreWellCenter : type==3 ? wellLast :  type==1 ? tankCenter : sumpLast;
      case 'After Valve':
        return sumpFirstCWS;
      default:
        return '';
    }
  }

  static String _getMobileSourceImagePath(int type, String position) {
    switch (position) {
      case 'First':
        return type==4 ? mobileBoreWellFirst : type==3 ? mobileWellFirst : mobileSumpFirst;
      case 'Center':
        return type==4 ? mobileBoreWellCenter : type==3 ? mobileWellCenter : mobileSumpCenter;
      case 'Last':
        return type==4 ? mobileBoreWellCenter : type==3 ? mobileWellCenter : mobileSumpCenter;
      case 'After Valve':
        return sumpFirstCWS;
      default:
        return '';
    }
  }

  static String _getPumpImagePath(int status) {
    switch (status) {
      case 0:
        return pumpOFF;
      case 1:
        return pumpON;
      case 2:
        return pumpNotON;
      case 3:
        return pumpNotOFF;
      default:
        return '';
    }
  }

  static String _getFLPPumpImagePath(int status) {
    switch (status) {
      case 0:
        return frtPumpOFF;
      case 1:
        return frtPumpON;
      case 2:
        return frtPumpNotON;
      case 3:
        return frtPumpNotOFF;
      default:
        return '';
    }
  }

  static String _getFLPValveImagePath(int status) {
    switch (status) {
      case 0:
        return frtValveOFF;
      case 1:
        return frtValveON;
      case 2:
        return frtValveNotON;
      case 3:
        return frtValveNotOFF;
      default:
        return '';
    }
  }

  static String _getFLPBoosterImagePath(int status) {
    switch (status) {
      case 0:
        return frtBoosterOFF;
      case 1:
        return frtBoosterON;
      case 2:
        return frtBoosterNotON;
      case 3:
        return frtBoosterNotOFF;
      default:
        return '';
    }
  }

  static String _getMobilePumpImagePath(int status, String position) {
    switch (status) {
      case 0:
        return mblPumpOFF;
      case 1:
        return mblPumpON;
      case 2:
        return mblPumpNotON;
      case 3:
        return mblPumpNotOFF;
      default:
        return '';
    }
  }

  static String _getAeratorPumpImagePath(int status, String position) {
    switch (status) {
      case 0:
        return aeratorPumpOFF;
      case 1:
        return aeratorPumpON;
      case 2:
        return aeratorPumpNotON;
      case 3:
        return aeratorPumpNotOFF;
      default:
        return '';
    }
  }

  static String _getFilterImagePath(int status) {
    switch (status) {
      case 0:
        return filterOFF;
      case 1:
        return filterON;
      case 2:
        return filterNotON;
      case 3:
        return filterNotOFF;
      default:
        return '';
    }
  }

  static String _getMobileFilterImagePath(int status, int type) {
    switch (status) {
      case 0:
        return type==1? mobileSandFilterOFF : mobileFilterOFF;
      case 1:
        return type==1? mobileSandFilterON : mobileFilterON;
      case 2:
        return type==1? mobileSandFilterNotON : mobileFilterNotON;
      case 3:
        return type==1? mobileSandFilterNotOFF : mobileFilterNotOFF;
      default:
        return '';
    }
  }

  static String getFertilizerChannelImage(int cIndex, int status,
      int cheLength, List agitatorList, bool isMobile) {

    String imageName;

    if(cIndex == cheLength - 1){
      if(agitatorList.isNotEmpty){
        imageName = 'dp_frt_channel_last_aj';
      }else{
        imageName = 'dp_frt_channel_last';
      }
    }else{
      if(agitatorList.isNotEmpty){
        if(cIndex==0){
          imageName = 'dp_frt_channel_first_aj';
        }else{
          imageName = 'dp_frt_channel_center_aj';
        }
      }else{
        imageName = 'dp_frt_channel_center';
      }
    }

    switch (status) {
      case 0:
        imageName += '.png';
        break;
      case 1:
        imageName += '_g.png';
        break;
      case 2:
        imageName += '_y.png';
        break;
      case 3:
        imageName += '_r.png';
        break;
      case 4:
        imageName += '.png';
        break;
      default:
        imageName += '.png';
    }

    return 'assets/png/$imageName';

  }

  static String _getBoosterImagePath(int status) {
    switch (status) {
      case 0:
        return boosterPumpOFF;
      case 1:
        return boosterPumpON;
      case 2:
        return boosterPumpNotON;
      case 3:
        return boosterPumpNotOFF;
      default:
        return '';
    }
  }


  static String _getSensorImagePath(String type) {
    if (type.contains('SM')) {
      return soilMoistureSensor;
    }
    if (type.contains('LV')) {
      return levelSensor;
    } else {
      return pressureSensor;
    }
  }

  static String _getAgitatorImagePath(int status) {
    switch (status) {
      case 0:
        return agitatorOFF;
      case 1:
        return agitatorON;
      case 2:
        return agitatorNotON;
      case 3:
        return agitatorNotOFF;
      default:
        return '';
    }
  }

  static String _getMainValveImagePath(int status) {
    switch (status) {
      case 0:
        return mainValveOFF;
      case 1:
        return mainValveON;
      case 2:
        return mainValveNotON;
      case 3:
        return mainValveNotOFF;
      default:
        return '';
    }
  }

  static String _getValveImagePath(int status, cPer) {
    switch (status) {
      case 0:
        if (cPer == 100) {
          return valveCompleted;
        }else if (cPer > 0 && cPer < 100) {
          return valvePending;
        }
        return valveOFF;
      case 1:
        return valveRunning;
      case 2:
        return valveNotON;
      case 3:
        return valveNotOFF;
      default:
        return '';
    }
  }



  static String _getValveLjImagePath(int status, int cPer) {
    switch (status) {
      case 0:
        if (cPer == 100) {
          return valveLjCompleted;
        }else if (cPer > 0 && cPer < 100) {
          return valveLjPending;
        }
        return valveLjOFF;
      case 1:
        return valveLjRunning;
      case 2:
        return valveLjNotON;
      case 3:
        return valveLjNotOFF;
      default:
        return '';
    }
  }

  static String _getValveCWSImagePath(int status, int cPer) {
    switch (status) {
      case 0 :
        if (cPer == 100) {
          return valveCwsCompleted;
        }else if (cPer > 0 && cPer < 100) {
          return valveCwsPending;
        }
        return valveCwsOFF;
      case 1:
        return valveCwsRunning;
      case 2:
        return valveCwsNotON;
      case 3:
        return valveCwsNotOFF;
      default:
        return '';
    }
  }

  static String _getLightImagePath(int status) {
    switch (status) {
      case 0:
        return lightOFF;
      case 1:
        return lightON;
      case 2:
        return lightOFF;
      case 3:
        return lightOFF;
      default:
        return '';
    }
  }

  static String _getFanImagePath(int status) {
    switch (status) {
      case 0:
        return fanOFF;
      case 1:
        return fanON;
      case 2:
        return fanNotOFF;
      case 3:
        return fanNotON;
      default:
        return '';
    }
  }

  static String _getFanImagePathMobile(int status) {
    switch (status) {
      case 0:
        return mblFanOFF;
      case 1:
        return mblFanON;
      case 2:
        return mblFanNotOFF;
      case 3:
        return mblFanNotON;
      default:
        return '';
    }
  }

  static String _getLightImagePathMobile(int status) {
    switch (status) {
      case 0:
        return mblLightOFF;
      case 1:
        return mblLightON;
      case 2:
        return mblLightNotOFF;
      case 3:
        return mblLightNotON;
      default:
        return '';
    }
  }


  static String _getGateImagePath(int status) {
    switch (status) {
      case 0:
        return gateOFF;
      case 1:
        return gateON;
      default:
        return '';
    }
  }

  static String getSettingsSummary(String title) {
    switch (title) {
      case 'General':
        return 'Includes controller name, category, model, version, and UTC time settings.';
      case 'Preference':
        return 'Configure pump settings, voltage, current limits, timers, and calibration.';
      case 'Constant':
        return 'Displays controller’s fixed setup: pumps, valve, and sensor. Useful for system overview.';
      case 'Name':
        return 'Change names of pumps, sensors, filters, and other components.';
      case 'Condition Library':
        return 'Sensor-based conditions such as moisture, pressure, time-based triggers, and program ON/OFF logic.';
      case 'Valve Group':
        return 'Group valves under a controller for simplified scheduling, monitoring, and centralized activity logs.';
      case 'Calibration':
        return 'Calibrate the available sensor.';
      case 'Pump Condition':
        return 'Pump-based conditions such as program ON/OFF logic.';
      case 'Controller Log':
        return 'Controller live trace and Logs';
      case 'Crop Advisory':
        return 'Get AI-powered guidance for your crop';
      default:
        return 'No additional information available.';
    }
  }

  static dynamic findLocation({required data, required double objectSno, required String key}) {
    String name = '';
    double sNo = 0.0;
    try {
      for (var key in data.keys) {
        if (![
          'isNewConfig',
          'controllerReadStatus',
          'configObject',
          'connectionCount',
          'productLimit',
          'userId',
          'controllerId',
          'groupId',
          'isNewConfig',
          'productLimit',
          'connectionCount',
          'deviceList',
          'hardware',
          'controllerReadStatus',
          'createUser',
        ].contains(key)) {
          for (var place in data[key]) {
            for (var placeKey in place.keys) {
              if (place[placeKey] is double) {
                if (place[placeKey] == objectSno) {
                  if(key == 'name'){
                    name = place['name'];
                  }else{
                    sNo = place['sNo'];
                  }
                  break;
                }
              }
              else if (place[placeKey] is List<double>) {
                if (place[placeKey].contains(objectSno)) {
                  if(key == 'name'){
                    name = place['name'];
                  }else{
                    sNo = place['sNo'];
                  }
                  break;
                }
              }else if(place[placeKey] is List<Map<String, dynamic>>){
                if(place[placeKey].any((obj) => obj['sNo'] == objectSno)){
                  if(key == 'name'){
                    name = place['name'];
                  }else{
                    sNo = place['sNo'];
                  }
                  break;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('error : $e');
    }

    if(key == 'name'){
      return name;
    }else{
      return sNo;
    }
  }

  static String buildUserManualUrl(String? link) {
    if (link == null || link.isEmpty) return '';
    if (link.startsWith('http')) return link;
    if (userManualBaseUrl.isEmpty) return link;
    return '$userManualBaseUrl/${link.replaceFirst(RegExp(r'^/+'), '')}';
  }

  static Color outputColor = const Color(0xff14AE5C);
  static Color commonObjectColor = const Color(0xff0070D8);
  static String analogCode = '3';
  static String digitalCode = '4';
  static String moistureCode = '5';
  static String pulseCode = '6';
  static String i2cCode = '7';
  static int generalInConstant = 80;
  static int waterSourceInConstant = 81;
  static int levelSensorInConstant = 82;
  static int pumpInConstant = 83;
  static int filterSiteInConstant = 84;
  static int filterInConstant = 85;
  static int fertilizerSiteInConstant = 86;
  static int fertilizerChannelInConstant = 87;
  static int ecPhInConstant = 88;
  static int waterMeterInConstant = 89;
  static int pressureSensorInConstant = 90;
  static int mainValveInConstant = 91;
  static int valveInConstant = 92;
  static int moistureSensorInConstant = 93;
  static int analogSensorInConstant = 94;
  static int normalCriticalInConstant = 95;
  static int globalAlarmInConstant = 96;
  static int sourceObjectId = 1;
  static int pumpObjectId = 5;
  static int filterSiteObjectId = 4;
  static int filterObjectId = 11;
  static int mainValveObjectId = 14;
  static int valveObjectId = 13;
  static int levelObjectId = 26;
  static int floatObjectId = 40;
  static int irrigationLineObjectId = 2;
  static int waterMeterObjectId = 22;
  static int analogWaterMeterObjectId = 46;
  static int pressureSensorObjectId = 24;
  static int pressureSwitchObjectId = 23;
  static int windDirectionObjectId = 31;
  static int windSpeedObjectId = 32;
  static int ldrObjectId = 35;
  static int luxObjectId = 34;
  static int atmosphericPressureObjectId = 39;
  static int leafWetnessObjectId = 37;
  static int rainFallObjectId = 38;
  static int fertilizerSiteObjectId = 3;
  static int channelObjectId = 10;
  static int boosterObjectId = 7;
  static int agitatorObjectId = 9;
  static int ecObjectId = 27;
  static int phObjectId = 28;
  static int moistureObjectId = 25;
  static int soilTemperatureObjectId = 30;
  static int pesticideObjectId = 18;
  static int ventObjectId = 18;
  static int co2ObjectId = 33;
  static int screenObjectId = 21;
  static int humidityObjectId = 36;
  static int heaterObjectId = 17;
  static int foggerObjectId = 16;
  static int mistObjectId = 44;
  static int fanObjectId = 15;
  static int temperatureObjectId = 29;
  static int powerSupplyObjectId = 42;
  static int lightObjectId = 19;
  static int gateObjectId = 43;
  static int flowControlValveObjectId = 45;
  static int dosingMeterObjectId = 47;

  static List<int> smartPlusEcPhModel = [33];
  static List<int> ecModel = [64];
  static List<int> phModel = [65];
  static List<int> pumpWithValveModelList = [48, 49, 52, 53, 54, 55, ...pumpWithLightModelList, ...singlePhaseShineModel, ...singlePhaseElitePlusModel];
  static List<int> pumpWithLightModelList = [76,77];
  static List<int> shine2V = [48, 49];
  static List<int> shine4V = [52, 53];
  static List<int> elite10V = [54, 55];
  static List<int> ecoGemFlowControlValveModel = [89, 90];
  static List<int> omsGemList = [91];
  static List<int> omsRtuList = [92];
  static List<int> ecoGemModelList = [56, 57, 58, 59, 60, 61, 62, 63, ...ecoGemFlowControlValveModel, ...singlePhaseEcoGemModel, ...singlePhaseEcoGemPlusModel];
  static List<int> ecoGemPlusModelList = [60, 61, 62, 63];
  static List<int> ecoGemAndPlusModelList = [...ecoGemModelList, ...ecoGemPlusModelList];
  static List<int> gemModelList = [1, 2, 4, 72, 73, 74, 75];
  static List<int> weatherModelList = [13, 14];
  static List<int> weatherGsmModelList = [14];
  static List<int> gsmModelList = [6, 9, 94, 67, 70];
  static List<int> pumpModelList = [5, 6, 7, ...pumpPlusModelList, ...wlcModelList, ...aquaculturePumpModelList, ...singlePhasePumpModel, ...singlePhasePumpPlusModel];
  static List<int> singlePhasePumpModel = [66, 67, 68];
  static List<int> singlePhasePumpPlusModel = [69, 70, 71];
  static List<int> singlePhaseShineModel = [96, 97, 98, 99];
  static List<int> singlePhaseElitePlusModel = [100, 101];
  static List<int> singlePhaseEcoGemModel = [102, 103, 104, 105];
  static List<int> singlePhaseEcoGemPlusModel = [106, 107, 108, 109];
  static List<int> pumpPlusModelList = [8, 9, 10, ...wlcModelList, ...aquaculturePumpModelList];
  static List<int> wlcModelList = [76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88];
  static List<int> wlc1010sdModelList = [87, ];
  static List<int> pumpWifiDefault = [7, 10];
  static List<int> pumpList = [
    ...pumpWithValveModelList,
    ...pumpModelList,
    ...shine2V,
    ...shine4V,
    ...elite10V,
    ...pumpPlusModelList
  ];
  static List<int> senseModelList = [41, 42, 43, 44, 45];
  static List<int> ecoNodeList = [36];
  static List<int> extendLoraList = [46];
  static List<int> extendGsmList = [47];
  static List<int> extendList = [...extendLoraList, ...extendGsmList];
  static List<int> aquacultureModelList = [72];
  static List<int> aquaculturePumpModelList = [93, 94, 95];
  static List<int> twoPhaseSetting = [201, 601, 701, 801, 901, 1001, 1101, 1201, 1301, 1401, 1501, 1601, 1701, 1801, 1901, 2001, 2101, 2201];
  static List<int> timerSetting = [202, 602, 702, 802, 902, 1002, 1102, 1202, 1302, 1402, 1502, 1602, 1702, 1802, 1902, 2002, 2102, 2202];
  static List<int> currentSetting = [203, 603, 703, 803, 903, 1003, 1103, 1203, 1303, 1403, 1503, 1603, 1703, 1803, 1903, 2003, 2103, 2203];
  static List<int> voltageSetting = [204, 604, 704, 804, 904, 1004, 1104, 1204, 1304, 1404, 1504, 1604, 1704, 1804, 1904, 2004, 2104, 2204];
  static List<int> additionalSetting = [205, 605, 705, 805, 905, 1005, 1105, 1205, 1305, 1405, 1505, 1605, 1705, 1805, 1905, 2005, 2105, 2205];
  static List<int> otherSetting = [206, 606, 706, 806, 906, 1006, 1106, 1206, 1306, 1406, 1506, 1606, 1706, 1806, 1906, 2006, 2106, 2206];
  static List<int> levelSetting = [207, 607, 707, 807, 907, 1007, 1107, 1207, 1307, 1407, 1507, 1607, 1707, 1807, 1907, 2007, 2107, 2207];
  static List<int> voltageCalibration = [208, 608, 708, 808, 908, 1008, 1108, 1208, 1308, 1408, 1508, 1608, 1708, 1808, 1908, 2008, 2108, 2208];
  static List<int> currentCalibration = [209, 609, 709, 809, 909, 1009, 1109, 1209, 1309, 1409, 1509, 1609, 1709, 1809, 1909, 2009, 2109, 2209];
  static List<int> otherCalibration = [210, 610, 710, 810, 910, 1010, 1110, 1210, 1310, 1410, 1510, 1610, 1710, 1810, 1910, 2010, 2110, 2210];
  static List<int> singlePhaseWlcModelList = [78, 79, 87, 88];
  static List<int> threePhaseWlcModelList = [80, 83, 84, 85];
  static List<int> singleOrThreePhaseWlcModelList = [81, 82, 86];
}