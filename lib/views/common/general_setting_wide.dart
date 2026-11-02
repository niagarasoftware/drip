
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import '../../StateManagement/customer_provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/constants.dart';
import '../../utils/enums.dart';
import '../../view_models/customer/general_setting_view_model.dart';
import 'user_profile/create_account.dart';


class GeneralSettingWide extends StatefulWidget {
  const GeneralSettingWide({super.key, required this.customerId,
    required this.controllerId, required this.userId, required this.isSubUser});
  final int customerId, controllerId, userId;
  final bool isSubUser;

  @override
  State<GeneralSettingWide> createState() => _GeneralSettingWideState();
}

class _GeneralSettingWideState extends State<GeneralSettingWide> {
  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      key: ValueKey(Provider.of<CustomerProvider>(context).controllerId),
      create: (_) => GeneralSettingViewModel(Repository(HttpService()))
        ..initIds(customerId: widget.customerId, controllerId: widget.controllerId, userId: widget.userId, isSubUser: widget.isSubUser)
        ..getControllerInfo()
        ..getSubUserList(),
      child: Consumer<GeneralSettingViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: viewModel.isLoading?
            buildLoadingIndicator(true, MediaQuery.sizeOf(context).width):
            generalSetting(context, viewModel),
          );
        },
      ),
    );
  }

  Widget buildLoadingIndicator(bool isVisible, double width) {
    return Visibility(
      visible: isVisible,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: width / 2 - 25),
        child: const LoadingIndicator(
          indicatorType: Indicator.ballPulse,
        ),
      ),
    );
  }

  Widget getSettingTile(BuildContext context, int index) {
    final viewModel = Provider.of<GeneralSettingViewModel>(context);

    switch (index) {
      case 0:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          title: const Text('Farm Name', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(viewModel.farmName),
          leading: const Icon(Icons.label_outline),
          trailing: IconButton(
            onPressed: () {
              showEditControllerDialog(context, 'Farm Name', viewModel.farmName, (newName) {
                viewModel.updateMasterDetails(context);
              });
            },
            icon: const Icon(Icons.edit),
          ),
        );
      case 1:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          title: const Text('Controller Name'),
          subtitle: Text(viewModel.controllerCategory, style: const TextStyle(fontWeight: FontWeight.bold)),
          leading: const Icon(Icons.developer_board),
          trailing: IconButton(
            onPressed: () {
              showEditControllerDialog(context, 'Controller Name', viewModel.farmName, (newName) {
                viewModel.updateMasterDetails(context);
              });
            },
            icon: const Icon(Icons.edit),
          ),
        );
      case 2:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          title: const Text('Device Category'),
          subtitle: Text(viewModel.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
          leading: const Icon(Icons.category),
        );
      case 3:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          title: const Text('Device Model'),
          subtitle: Text(viewModel.modelName, style: const TextStyle(fontWeight: FontWeight.bold)),
          leading: const Icon(Icons.model_training),
        );
      case 4:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          title: const Text('Device ID'),
          subtitle: SelectableText(
            viewModel.deviceId,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: const Icon(Icons.numbers_outlined),
        );
      case 5:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          title: const Text('Controller Version'),
          subtitle: Text(viewModel.controllerVersion, style: const TextStyle(fontWeight: FontWeight.bold)),
          leading: const Icon(Icons.developer_board),
          trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.update)),
        );
      case 6:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          leading: const Icon(Icons.timer_outlined),
          title: const Text('UTC'),
          subtitle: const Text('Time zone setting'),
          trailing: SizedBox(
            width: 175,
            child: DropdownButton<String>(
              hint: const Text('Select Time Zone'),
              value: viewModel.selectedTimeZone,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  viewModel.updateCurrentDateTime(newValue);
                }
              },
              items: viewModel.timeZones
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        );
      case 7:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          leading: const Icon(Icons.date_range),
          title: const Text('Current Date'),
          subtitle: const Text('Date from controller'),
          trailing: Text(
            viewModel.currentDate,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      case 8:
        return ListTile(
          title: const Text('Location'),
          subtitle: const Text('Controller location'),
          leading: const Icon(Icons.location_on_outlined),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(viewModel.controllerLocation, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  showEditControllerDialog(context, 'Location', viewModel.controllerLocation, (newName) {
                    viewModel.updateMasterDetails(context);
                  });
                },
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
        );
      case 9:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          leading: const Icon(Icons.access_time),
          title: const Text('Current UTC Time'),
          subtitle: const Text('Time from controller'),
          trailing: Text(
            viewModel.currentTime,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      case 10:
        return const ListTile(
          title: Text('Time Format'),
          leading: Icon(Icons.av_timer),
          trailing: Text(
            '24 Hrs',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      case 11:
        return const ListTile(
          title: Text('Unit'),
          leading: Icon(Icons.ac_unit_rounded),
          trailing: Text(
            'm3',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget generalSetting(BuildContext context, GeneralSettingViewModel viewModel){

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 385,
                child: Row(
                  children: [
                    Flexible(
                      flex: 1,
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Farm Name'),
                            leading: const Icon(Icons.label_outline),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(viewModel.farmName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: () {
                                    showEditControllerDialog(context, 'Farm Name', viewModel.farmName, (farmName) {
                                      viewModel.farmName = farmName;
                                      viewModel.updateMasterDetails(context);
                                    });
                                  },
                                  icon: const Icon(Icons.edit),
                                ),
                              ],
                            ),
                          ),
                          Divider(color: Colors.grey.shade200),
                          ListTile(
                            title: const Text('Controller Name'),
                            leading: const Icon(Icons.developer_board),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(viewModel.controllerCategory, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: () {
                                    showEditControllerDialog(context, 'Controller Name', viewModel.controllerCategory, (category) {
                                      viewModel.controllerCategory = category;
                                      viewModel.updateMasterDetails(context);
                                    });
                                  },
                                  icon: const Icon(Icons.edit),
                                ),
                              ],
                            ),
                          ),
                          Divider(color: Colors.grey.shade200),
                          ListTile(
                            title: const Text('Device Category'),
                            leading: const Icon(Icons.category_outlined),
                            trailing: Text(
                              viewModel.categoryName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Divider(color: Colors.grey.shade200),
                          ListTile(
                            title: const Text('Model'),
                            leading: const Icon(Icons.model_training),
                            trailing: Text(
                              viewModel.modelName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Divider(color: Colors.grey.shade200),
                          ListTile(
                            title: const Text('Device ID'),
                            leading: const Icon(Icons.numbers_outlined),
                            trailing: SelectableText(
                              viewModel.deviceId,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Divider(color: Colors.grey.shade200),
                          ListTile(
                            title: const Text('Version'),
                            leading: const Icon(Icons.perm_device_info),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  viewModel.controllerVersion,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                viewModel.controllerVersion != viewModel.newVersion
                                    ? SizedBox(
                                  height: 40,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {},
                                    child: AnimatedOpacity(
                                      opacity: viewModel.opacity,
                                      duration: const Duration(seconds: 2),
                                      child: Text(
                                        'New Version available - ${viewModel.newVersion}',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                )
                                    : const SizedBox(),
                              ],
                            ),
                          ),
                          Divider(color: Colors.grey.shade300),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: VerticalDivider(width: 0, color: Colors.grey.shade200),
                    ),
                    Flexible(
                      flex: 1,
                      child: Column(
                        children: [
                          if([...AppConstants.ecoGemModelList, ...AppConstants.pumpList].contains(viewModel.modelId))...[
                            ListTile(
                              title: const Text('Sim card number'),
                              leading: const Icon(Icons.sim_card_outlined),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${viewModel.countryCode} - ${viewModel.simNumber}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    onPressed: () {
                                      showSimEditControllerDialog(context, 'SIM card Number',
                                          viewModel.countryCode ?? '91',viewModel.simNumber ?? '0', (cCode, sNumber) {
                                        viewModel.countryCode = cCode;
                                        viewModel.simNumber = sNumber;
                                        viewModel.updateMasterDetails(context);
                                      });
                                    },
                                    icon: const Icon(Icons.edit),
                                  ),
                                ],
                              ),
                            ),
                            Divider(color: Colors.grey.shade300),
                          ],
                          ListTile(
                            title: const Text('UTC'),
                            leading: const Icon(Icons.timer_outlined),
                            trailing: DropdownButton<String>(
                              hint: const Text('Select Time Zone'),
                              value: viewModel.selectedTimeZone,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  viewModel.updateCurrentDateTime(newValue);
                                }
                              },
                              items: viewModel.timeZones
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                            ),
                          ),
                          Divider(color: Colors.grey.shade200),
                          ListTile(
                            title: const Text('Current Date'),
                            leading: const Icon(Icons.date_range),
                            trailing: Text(
                              viewModel.currentDate,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Divider(color: Colors.grey.shade200),
                          ListTile(
                            title: const Text('Current UTC Time'),
                            leading: const Icon(Icons.date_range),
                            trailing: Text(
                              viewModel.currentTime,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Divider(color: Colors.grey.shade200),
                          ListTile(
                            title: const Text('Controller Location'),
                            leading: const Icon(Icons.location_on_outlined),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(viewModel.controllerLocation, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: () {
                                    showEditControllerDialog(context, 'Location', viewModel.controllerLocation, (location) {
                                      viewModel.controllerLocation = location;
                                      viewModel.updateMasterDetails(context);
                                    });
                                  },
                                  icon: const Icon(Icons.edit),
                                ),
                              ],
                            ),
                          ),
                          Divider(color: Colors.grey.shade200),
                          const ListTile(
                            title: Text('Time Format'),
                            leading: Icon(Icons.date_range),
                            trailing: Text(
                              '24 Hrs',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Divider(color: Colors.grey.shade200),
                          if([...AppConstants.gemModelList].contains(viewModel.modelId))...[
                            const ListTile(
                              title: Text('Unit'),
                              leading: Icon(Icons.ac_unit_rounded),
                              trailing: Text(
                                'm3',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Divider(color: Colors.grey.shade300),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 50,
                width: MediaQuery.sizeOf(context).width,
                child: ListTile(
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MaterialButton(
                        color: Colors.teal,
                        textColor: Colors.white,
                        onPressed: () async {
                        },
                        child: const Text('Restart the controller'),
                      ),
                      const SizedBox(width: 16),
                      MaterialButton(
                        color: Theme.of(context).primaryColorDark,
                        textColor: Colors.white,
                        onPressed: () => viewModel.updateMasterDetails(context),
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
              ),
              if(!widget.isSubUser)...[
                ListTile(
                  leading: const Icon(Icons.supervised_user_circle_outlined),
                  title: const Text(
                    'My Sub users',
                    style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  trailing: widget.userId != 0
                      ? IconButton(
                      tooltip: 'Add new sub user',
                      onPressed: () async {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) {
                            return FractionallySizedBox(
                              heightFactor: 0.84,
                              widthFactor: 0.75,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                                ),
                                child: CreateAccount(userId: widget.userId, role: UserRole.subUser, customerId: widget.customerId, onAccountCreated: viewModel.updateCustomerList),
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.add))
                      : null,
                ),
                Divider(height:0, color: Colors.grey.shade300),
                SizedBox(
                  height: 70,
                  child: viewModel.subUsers.isNotEmpty ?
                  ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: viewModel.subUsers.length,
                    itemBuilder: (context, index) {
                      final user = viewModel.subUsers[index];
                      return SizedBox(
                        width: 250,
                        child: Card(
                          surfaceTintColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: ListTile(
                            title: Text(user['userName']),
                            subtitle: Text(
                                '+${user['countryCode']} ${user['mobileNumber']}'),
                            trailing: IconButton(
                              tooltip: 'User Permission',
                              onPressed: () => _showAlertDialog(
                                  context, viewModel, user['userName'], user['userId']),
                              icon: const Icon(Icons.menu),
                            ),
                          ),
                        ),
                      );
                    },
                  ) :
                  const Center(child: Text('No Sub user available for this controller')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAlertDialog(BuildContext pntContext, GeneralSettingViewModel vm, String cName, int suId) async {

    List<UserGroup> userGroups = [];
    Map<String, Object> body = {
      "userId": widget.customerId,
      "sharedUserId": suId,
    };
    final deviceList = await vm.getSubUserSharedDeviceList(body);
    if (deviceList != null) {
      setState(() {
        userGroups = deviceList.map((i) => UserGroup.fromJson(i)).toList();
      });
    } else {
      debugPrint("No devices found.");
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$cName - Permissions'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Scaffold(
              body: ListView.builder(
                itemCount: userGroups.length,
                itemBuilder: (context, index) {
                  return UserGroupWidget(group: userGroups[index]);
                },
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                List<MasterItem> masterList = [];

                for (int gix = 0; gix < userGroups.length; gix++) {
                  for (int mix = 0; mix < userGroups[gix].master.length; mix++) {
                    final master = userGroups[gix].master[mix];
                    masterList.add(
                      MasterItem(
                        id: master.controllerId,
                        action: master.isSharedDevice,
                        userPermission: master.userPermission,
                        linePermission: master.linePermission,
                      ),
                    );
                  }
                }

                Map<String, Object> body = {
                  "userId": widget.customerId,
                  "sharedUser": suId,
                  "masterList": masterList.map((item) => item.toMap()).toList(),
                  "createUser": widget.userId,
                };

                vm.updatedSubUserPermission(body, suId, pntContext);
              },
            ),
            /*TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                List<MasterItem> masterList = [];
                for(int gix=0; gix<userGroups.length; gix++){
                  for(int mix=0; mix<userGroups[gix].master.length; mix++){
                    masterList.add(MasterItem(id: userGroups[gix].master[mix].controllerId,
                        action: userGroups[gix].master[mix].isSharedDevice,
                        userPermission: userGroups[gix].master[mix].userPermission));
                  }
                }

                Map<String, Object> body = {
                  "userId": widget.customerId,
                  "sharedUser": suId,
                  "masterList": masterList.map((item) => item.toMap()).toList(),
                  "createUser": widget.userId,
                };
                vm.updatedSubUserPermission(body, suId, pntContext);
              },
            ),*/
          ],
        );
      },
    );
  }

  void showEditControllerDialog(BuildContext context, String currentTitle, String currentName, Function(String) onSave) {
    final TextEditingController nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $currentTitle'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: currentTitle,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name cannot be empty')),
                  );
                  return;
                }
                onSave(name);
                Navigator.of(context).pop();
              },
              child: const Text('Save', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void showSimEditControllerDialog(BuildContext context, String currentTitle,
      String cCode, String simNo, Function(String, String) onSave) {

    final TextEditingController cCodeController = TextEditingController(text: cCode);
    final TextEditingController mobileNoController = TextEditingController(text: simNo);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $currentTitle'),
          content: IntlPhoneField(
            decoration: InputDecoration(
              hintText: 'Enter SIM number',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () => mobileNoController.clear(),
              ),
              icon: const Icon(Icons.phone_outlined, color: Colors.black),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              counterText: '',
            ),
            languageCode: "en",
            initialCountryCode: 'IN',
            controller: mobileNoController,
            onChanged: (phone) {},
            onCountryChanged: (country) {
              cCodeController.text = country.dialCode;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                onSave(cCodeController.text, mobileNoController.text.trim());
                Navigator.of(context).pop();
              },
              child: const Text('Save', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }
}

class UserGroup {
  final int userGroupId;
  final String groupName;
  final bool active;
  final List<Master> master;

  UserGroup({required this.userGroupId, required this.groupName, required this.active, required this.master});

  factory UserGroup.fromJson(Map<String, dynamic> json) {
    var list = json['master'] as List;
    List<Master> masterList = list.map((i) => Master.fromJson(i)).toList();
    return UserGroup(
      userGroupId: json['userGroupId'],
      groupName: json['groupName'],
      active: json['active'] == '1',
      master: masterList,
    );
  }
}

class Master {
  final int controllerId;
  final String deviceId;
  final String deviceName;
  bool isSharedDevice;
  final List<UserPermission> userPermission;
  final List<LinePermission> linePermission;

  Master({
    required this.controllerId,
    required this.deviceId,
    required this.deviceName,
    required this.isSharedDevice,
    required this.userPermission,
    required this.linePermission
  });

  factory Master.fromJson(Map<String, dynamic> json) {
    var list = json['userPermission'] as List;
    List<UserPermission> userPermissionList = list.map((i) => UserPermission.fromJson(i)).toList();

    // Handle linePermission (might be null or empty)
    List<LinePermission> linePermissionListData = [];
    if (json['linePermission'] != null) {
      var linePermissionList = json['linePermission'] as List;
      linePermissionListData = linePermissionList.map((i) => LinePermission.fromJson(i)).toList();
    }

    return Master(
      controllerId: json['controllerId'],
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      isSharedDevice: json['isSharedDevice'] ?? false,
      userPermission: userPermissionList,
      linePermission: linePermissionListData,
    );
  }
}

class UserPermission {
  final int sNo;
  final String name;
  bool status;

  UserPermission({required this.sNo, required this.name, required this.status});

  Map<String, dynamic> toMap() {
    return {
      'sNo': sNo,
      'name': name,
      'status': status,
    };
  }

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      sNo: json['sNo'],
      name: json['name'],
      status: json['status'] ?? false,
    );
  }
}

class LinePermission {
  final double sNo;
  final String name;
  bool status;

  LinePermission({required this.sNo, required this.name, required this.status});

  Map<String, dynamic> toMap() {
    return {
      'sNo': sNo,
      'name': name,
      'status': status,
    };
  }

  factory LinePermission.fromJson(Map<String, dynamic> json) {
    return LinePermission(
      sNo: (json['sNo'] as num).toDouble(),
      name: json['name'],
      status: json['status'] ?? false,
    );
  }
}

// Updated UserGroupWidget with line permissions
class UserGroupWidget extends StatefulWidget {
  final UserGroup group;
  const UserGroupWidget({super.key, required this.group});

  @override
  _UserGroupWidgetState createState() => _UserGroupWidgetState();
}

class _UserGroupWidgetState extends State<UserGroupWidget> {
  void toggleGroup(UserGroup group, bool? value) {
    if (value == null) return;
    setState(() {
      for (var master in group.master) {
        master.isSharedDevice = value;
        for (var permission in master.userPermission) {
          permission.status = value;
        }
        for (var linePermission in master.linePermission) {
          linePermission.status = value;
        }
      }
    });
  }

  void toggleMaster(Master master, bool? value) {
    if (value == null) return;
    setState(() {
      master.isSharedDevice = value;
      for (var permission in master.userPermission) {
        permission.status = value;
      }
      for (var linePermission in master.linePermission) {
        linePermission.status = value;
      }
    });
  }

  void toggleUserPermission(Master master, UserPermission permission, bool? value) {
    if (value == null) return;
    setState(() {
      permission.status = value;

      // Update master shared status based on permissions
      bool anyPermissionSelected = master.userPermission.any((p) => p.status) ||
          master.linePermission.any((lp) => lp.status);
      master.isSharedDevice = anyPermissionSelected;
    });
  }

  void toggleLinePermission(Master master, LinePermission permission, bool? value) {
    if (value == null) return;
    setState(() {
      permission.status = value;

      // Update master shared status based on permissions
      bool anyPermissionSelected = master.userPermission.any((p) => p.status) ||
          master.linePermission.any((lp) => lp.status);
      master.isSharedDevice = anyPermissionSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            Checkbox(
              value: widget.group.master.every((m) => m.isSharedDevice),
              onChanged: (value) => toggleGroup(widget.group, value),
            ),
            Expanded(
              child: Text(
                widget.group.groupName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        children: widget.group.master.map((master) {
          return ExpansionTile(
            initiallyExpanded: true,
            title: Row(
              children: [
                Checkbox(
                  value: master.isSharedDevice,
                  onChanged: (value) => toggleMaster(master, value),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        master.deviceName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        master.deviceId,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              // User Permissions Section
              if (master.userPermission.isNotEmpty) ...[

                ...master.userPermission.map((permission) {
                  return ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: permission.status,
                      onChanged: (value) => toggleUserPermission(master, permission, value),
                    ),
                    title: Text(
                      permission.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }),
              ],

              // Line Permissions Section
              if (master.linePermission.isNotEmpty) ...[

                ...master.linePermission.map((permission) {
                  return ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: permission.status,
                      onChanged: (value) => toggleLinePermission(master, permission, value),
                    ),
                    title: Text(
                      permission.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// Updated MasterItem with proper fromJson
class MasterItem {
  final int id;
  final bool action;
  final List<UserPermission> userPermission;
  final List<LinePermission> linePermission;

  MasterItem({
    required this.id,
    required this.action,
    required this.userPermission,
    required this.linePermission,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'userPermission': userPermission.map((perm) => perm.toMap()).toList(),
      'linePermission': linePermission.map((perm) => perm.toMap()).toList(),
    };
  }

  factory MasterItem.fromJson(Map<String, dynamic> json) {
    return MasterItem(
      id: json['id'],
      action: json['action'],
      userPermission: List<UserPermission>.from(
          json['userPermission'].map((x) => UserPermission.fromJson(x))
      ),
      linePermission: json['linePermission'] != null
          ? List<LinePermission>.from(
          json['linePermission'].map((x) => LinePermission.fromJson(x))
      )
          : [],
    );
  }
}
