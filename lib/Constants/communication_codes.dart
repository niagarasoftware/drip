import 'dart:ui';

// Todo interface
int getInterfaceStringToCode(String title){
  switch(title){
    case 'MQTT' :
      return 1;
    case 'LoRa' :
      return 2;
    case 'RS485' :
      return 3;
    case 'Wi-Fi' :
      return 4;
    case 'Extend' :
      return 5;
    default :
      return 0;
  }
}
String getInterfaceCodeToString(int? code){
  switch(code){
    case 1 :
      return 'MQTT';
    case 2 :
      return 'LoRa';
    case 3 :
      return 'RS485';
    case 4 :
      return 'Wi-Fi';
    case 5 :
      return 'Extend';
    default :
      return '-';
  }
}

//Todo interval
int getIntervalStringToCode(String title){
  String val = title;
  List<String> stringToList = val.split(' ');
  return int.parse(stringToList[0]);
}
String getIntervalCodeToString(int code, String mergeParameter){
  return '$code $mergeParameter';
}

//Todo objectType
String getObjectTypeCodeToString(int code){
  switch(code){
    case 1 :
      return 'Relay';
    case 2 :
      return 'Latch';
    case 3 :
      return 'Analog Input';
    case 4 :
      return 'Digital Input';
    case 5 :
      return 'Moisture Input';
    case 6 :
      return 'Pulse Input';
    case 7:
      return 'I2C Input';
    default :
      return 'I2C Input';
  }
}
Color getObjectTypeCodeToColor(int code){
  switch(code){
    case 1 :
      return const Color(0xff078BFF);
    case 2 :
      return const Color(0xffD2EAFF);
    case 3 :
      return const Color(0xffEB7C17);
    case 4 :
      return const Color(0xffC41500);
    case 5 :
      return const Color(0xffE73293);
    case 6 :
      return const Color(0xff7F33E1);
    case 7 :
      return const Color(0xff00EEFF);
    default :
      return const Color(0xffDBDEFF);
  }
}


// Todo: tankType
String getTankCodeToString(int code){
  switch(code){
    case 1 :
      return 'Tank';
    case 2 :
      return 'Sump';
    case 3 :
      return 'Well';
    case 4 :
      return 'Bore';
    case 5 :
      return 'Others';
    case 6 :
      return 'Fertilizer Source';
    case 7 :
      return 'Fertilizer Tank';
    default :
      return '-';
  }
}
int getTankStringToCode(String type){
  switch(type){
    case 'Tank' :
      return 1;
    case 'Sump' :
      return 2;
    case 'Well' :
      return 3;
    case 'Bore' :
      return 4;
    case 'Others' :
      return 5;
    case 'Fertilizer Source' :
      return 6;
    case 'Fertilizer Tank' :
      return 7;
    default :
      return 0;
  }
}

// Todo: pumpType
String getPumpTypeCodeToString(int code){
  switch(code){
    case 1 :
      return 'source';
    case 2 :
      return 'irrigation';
    default :
      return 'aerator';
  }
}

int getPumpTypeStringToCode(String type){
  switch(type){
    case 'source' :
      return 1;
    case 'irrigation' :
      return 2;
    default :
      return 3;
  }
}

// Todo: centralOrLocal
String getCentralLocalCodeToString(int code){
  switch(code){
    case 1 :
      return 'Central';
    default :
      return 'Local';
  }
}

int getCentralLocalStringToCode(String type){
  switch(type){
    case 'Central' :
      return 1;
    default :
      return 2;
  }
}