import 'package:flutter/cupertino.dart';

class OverAllUse extends ChangeNotifier{
  TextEditingController hourController = TextEditingController();
  TextEditingController minController = TextEditingController();
  TextEditingController secController = TextEditingController();
  int hrs = 0;
  int min = 0;
  int sec = 0;
  int other = 0;
  String am_pm = '';
  int userId = 8;
  int sharedUserId = 0;
  bool takeSharedUserId = false;
  int createUser = 0;
  int controllerId = 13;
  String deviceId = '';
  int userGroupId = 0;
  int controllerType = 0;
  int customerId = 8;
  int dealerId = 0;
  String imeiNo = '';
  bool fromDealer = false;
  int selectedMenu = 0;
  List<int> menuIdList = [80, 78, 72, 79, 127, 75, 74, 69, 67, 68, 66, 71];
   String getTime(){
    return '${hrs.toString().padLeft(2, '0')}'
        ':${min.toString().padLeft(2, '0')}'
        ':${sec.toString().padLeft(2, '0')}';
  }

  void updateSelectedMenu(int currentMenuId) {
    print("currentMenuId $currentMenuId");

    int currentIndex = menuIdList.indexWhere((element) => element == currentMenuId);
    if (currentIndex != -1) {
      int nextIndex = (currentIndex + 1) % menuIdList.length;
      selectedMenu = menuIdList[nextIndex];
    } else {
      print("currentMenuId not found in menuIdList");
      selectedMenu = 0;
    }

    print("selectedMenu $selectedMenu");
    notifyListeners();
  }


  int getUserId(){
    if(takeSharedUserId){
      return sharedUserId;
    }else{
      return userId;
    }
  }
  void editUserId(int value){
    userId = value;
    notifyListeners();
  }
  void edituserGroupId(int value){
    userGroupId = value;
    notifyListeners();
  }
  void editSharedUserId(int value){
    sharedUserId = value;
    notifyListeners();
  }
  void editTakeSharedUserId(bool value){
    takeSharedUserId = value;
    notifyListeners();
  }
  void editCustomerId(int value){
    customerId = value;
    notifyListeners();
  }

  void editCreateUser(int value){
    createUser = value;
    notifyListeners();
  }

  void editImeiNo(String value){
    imeiNo = value;
    notifyListeners();
  }

  void editControllerId(int value){
    controllerId = value;
    notifyListeners();
  }
  void editDeviceId(String value){
    deviceId = value;
    notifyListeners();
  }

  void editControllerType(int value){
    print("editControllerType --->$value");
    controllerType = value;
    notifyListeners();
  }


  bool keyBoardAppears = false;

  void editKeyBoardAppears(bool val){
    keyBoardAppears = val;
    notifyListeners();
  }

  void editTimeAll(){
    hrs = 0;
    min = 0;
    sec = 0;
    other = 1;
    am_pm = '';
    notifyListeners();
  }
  void edit_am_pm(String value){
    am_pm = value;
    notifyListeners();
  }
  void editTime(String title, int value){
    switch (title){
      case ('hrs') :{
        hrs = value;
        hourController.text = value.toString();
        break;
      }
      case ('min') :{
        min = value;
        minController.text = value.toString();
        break;
      }
      case ('sec') :{
        sec = value;
        secController.text = value.toString();
        break;
      }
      case ('other') :{
        print(other);
        other = value;
        break;
      }
    }
    notifyListeners();
  }

}