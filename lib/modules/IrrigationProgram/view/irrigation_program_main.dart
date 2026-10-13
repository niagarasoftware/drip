import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/preview_screen.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/schedule_screen.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/selection_screen.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/sequence_screen.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/water_and_fertilizer_screen.dart';
import 'package:provider/provider.dart';
import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';
import '../state_management/irrigation_program_provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../widgets/custom_alert_dialog.dart';
import '../widgets/custom_tab.dart';
import 'alarm_screen.dart';
import 'conditions_screen.dart';
import 'done_screen.dart';

class IrrigationProgram extends StatefulWidget {
  final int userId;
  final int customerId;
  final int groupId;
  final int categoryId;
  final int controllerId;
  final String deviceId;
  final int serialNumber;
  final String? programType;
  final bool fromDealer;
  final bool toDashboard;
  final int modelId;
  final String deviceName;
  final String categoryName;
  final List<NodeListModel> nodeList;

  const IrrigationProgram({
    Key? irrigationProgramKey,
    required this.userId,
    required this.controllerId,
    required this.serialNumber,
    this.programType,
    required this.deviceId,
    required this.fromDealer,
    required this.groupId,
    required this.categoryId,
    this.toDashboard = false,
    required this.customerId,
    required this.modelId,
    required this.deviceName,
    required this.categoryName,
    required this.nodeList,
  }) : super(key: irrigationProgramKey);

  @override
  State<IrrigationProgram> createState() => _IrrigationProgramState();
}

class _IrrigationProgramState extends State<IrrigationProgram> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> labels;
  late List<IconData> icons;
  late MqttPayloadProvider mqttPayloadProvider;
  bool _isDialogShowing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final irrigationProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);

    final result = irrigationProvider.getLabelAndIcon(
      sno: widget.serialNumber,
      programType: widget.programType,
      conditionLibrary: irrigationProvider.conditionsLibraryIsNotEmpty,
    );
    labels = result.labels;
    icons = result.icons;

    _tabController = TabController(length: labels.length, vsync: this);
    _tabController.addListener(() {
      irrigationProvider.updateTabIndex(_tabController.index);
    });

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchData();
      });
    }
  }

  void _showLoadingDialog() {
    if (_isDialogShowing) return;
    _isDialogShowing = true;
    showAdaptiveDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading program data...", style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              Text("Please wait while we sync your settings", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (_isDialogShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      _isDialogShowing = false;
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _errorMessage = null;
    });

    _showLoadingDialog();

    try {
      final irrigationProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
      irrigationProvider.updateTabIndex(0);

      // Fetch sequence data first as other data might depend on it
      await irrigationProvider.getUserProgramSequence(
        userId: widget.customerId,
        controllerId: widget.controllerId,
        serialNumber: widget.serialNumber,
        groupId: widget.groupId,
        categoryId: widget.categoryId,
        modelId: widget.modelId,
      );

      // Fetch other data in parallel
      await Future.wait([
        irrigationProvider.doneData(widget.customerId, widget.controllerId, widget.serialNumber),
        irrigationProvider.scheduleData(widget.customerId, widget.controllerId, widget.serialNumber),
        irrigationProvider.getUserProgramCondition(widget.customerId, widget.controllerId, widget.serialNumber),
        irrigationProvider.getWaterAndFertData(
          userId: widget.customerId,
          controllerId: widget.controllerId,
          serialNumber: widget.serialNumber,
        ),
        irrigationProvider.getUserProgramSelection(widget.customerId, widget.controllerId, widget.serialNumber),
        irrigationProvider.getUserProgramAlarm(widget.customerId, widget.controllerId, widget.serialNumber),
      ]);

      if (mounted) {
        final result = irrigationProvider.getLabelAndIcon(
          sno: widget.serialNumber,
          programType: widget.programType,
          conditionLibrary: irrigationProvider.conditionsLibraryIsNotEmpty,
        );
        setState(() {
          labels = result.labels;
          icons = result.icons;
          if (_tabController.length != labels.length) {
            final oldIndex = _tabController.index;
            _tabController.dispose();
            _tabController = TabController(
              length: labels.length,
              vsync: this,
              initialIndex: oldIndex < labels.length ? oldIndex : 0,
            );
            _tabController.addListener(() {
              irrigationProvider.updateTabIndex(_tabController.index);
            });
          }
        });
        _hideLoadingDialog();
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        setState(() {
          _errorMessage = "Failed to load irrigation program data.";
        });
        _showErrorDialog();
      }
    }
  }

  void _showErrorDialog() {
    showAdaptiveDialog(
      context: context,
      builder: (context) => CustomAlertDialog(
        title: "Error",
        content: "Some data failed to load. Would you like to try again or go back?",
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _fetchData();
            },
            child: const Text("Try Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Go Back", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToTab(int tabIndex) {
    if (_tabController.index != tabIndex) {
      _tabController.animateTo(tabIndex);
    }
  }

  void _navigateToNextTab() {
    _tabController.animateTo((_tabController.index + 1) % _tabController.length);
  }

  void _navigateToPreviousTab() {
    _tabController.animateTo((_tabController.index - 1 + _tabController.length) % _tabController.length);
  }

  bool _validateBeforeGoingTo(int targetIndex, IrrigationProgramMainProvider mainProvider) {
    if (widget.programType != "Irrigation Program") {
      return true;
    }

    final threshold = labels.length == 7 ? 2 : 3;
    if (targetIndex <= threshold) {
      return true;
    }

    if (!mainProvider.selectedObjects!.any((element) => element.objectId == 2)) {
      _showValidationAlert(content: "Please select at least one head unit!");
      return false;
    }

    if (!mainProvider.isPumpStationMode && mainProvider.pump!.isNotEmpty && !mainProvider.selectedObjects!.any((element) => element.objectId == 5) && !AppConstants.ecoGemFlowControlValveModel.contains(widget.modelId)) {
      if (!mainProvider.ignoreValidation) {
        final hasMultiplePumps = mainProvider.pump!.length > 1;
        _showValidationAlert(
          content: "Are you sure to proceed without pump selection?",
          showConfirm: hasMultiplePumps,
          onConfirm: () {
            mainProvider.ignoreValidation = true;
            _navigateToTab(targetIndex);
          },
          targetIndex: targetIndex,
        );
        return false;
      }
      return true;
    }

    if (mainProvider.isPumpStationMode) {
      final result = mainProvider.calculateTotalFlowRate();
      if (result['sequenceData'].isNotEmpty) {
        _showFlowRateWarning(result);
        return false;
      }
    }

    return true;
  }

  void _showValidationAlert({
    required String content,
    bool showConfirm = false,
    VoidCallback? onConfirm,
    int? targetIndex,
  }) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => CustomAlertDialog(
        title: "Warning",
        content: content,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (showConfirm && onConfirm != null && targetIndex != null) {
                onConfirm();
              }
            },
            child: Text(showConfirm ? "Yes" : "OK"),
          ),
          if (showConfirm)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("No", style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  void _showFlowRateWarning(Map<String, dynamic> validationData) {
    final mainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            Text("Warning!", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Pump station range is not sufficient for zone's valve flow rate!",
              style: TextStyle(fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pump station range', style: TextStyle(color: Colors.black)),
                const SizedBox(width: 20),
                Text(
                  '${validationData['pumpFlowRate']} L/hr',
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for(var seq in validationData['sequenceData'])
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${seq['name']}', style: const TextStyle(color: Colors.black)),
                  const SizedBox(width: 20),
                  Text(
                    '${seq['flowrate']} L/hr',
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _handleTabNavigation(int targetIndex) {
    final mainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    if (_tabController.index == 0 && mainProvider.irrigationLine!.sequence.any((element) => element['valve'].isEmpty)) {
      _showSequenceWarning(mainProvider);
    } else if (_validateBeforeGoingTo(targetIndex, mainProvider)) {
      _navigateToTab(targetIndex);
    }
  }

  void _showSequenceWarning(IrrigationProgramMainProvider mainProvider) {
    final indexWhereEmpty = mainProvider.irrigationLine!.sequence.indexWhere((element) => element['valve'].isEmpty);
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning!'),
        content: RichText(
          text: TextSpan(
            children: [
              const TextSpan(text: 'There is no valve configured at ', style: TextStyle(color: Colors.black)),
              TextSpan(
                text: '${mainProvider.irrigationLine!.sequence[indexWhereEmpty]['name']}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final mainProvider = Provider.of<IrrigationProgramMainProvider>(context);
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: true);

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Error"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Try Again"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (mainProvider.irrigationLine != null && mainProvider.programDetails != null) {
      final isIrrigationProgram = (mainProvider.programDetails!.programType == "Irrigation Program") ||
          (mainProvider.selectedProgramType == "Irrigation Program");

      final programName = widget.serialNumber == 0
          ? "New Program"
          : mainProvider.programDetails!.programName.isNotEmpty
          ? (mainProvider.programName == '' ? "Program ${mainProvider.programCount + 1}" : mainProvider.programName)
          : mainProvider.programDetails!.defaultProgramName;

      return LayoutBuilder(
        builder: (context, constraints) {
          return DefaultTabController(
            length: labels.length,
            child: Scaffold(
              appBar: MediaQuery.of(context).size.width < 600
                  ? AppBar(
                title: Text(programName),
                centerTitle: true,
                leading: IconButton(
                  onPressed: () {
                    mainProvider.programLibraryData(widget.customerId, widget.controllerId);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                bottom: constraints.maxWidth < 600
                    ? PreferredSize(
                  preferredSize: const Size.fromHeight(80.0),
                  child: TabBar(
                    controller: _tabController,
                    tabAlignment: TabAlignment.start,
                    isScrollable: true,
                    tabs: [
                      for (int i = 0; i < labels.length; i++)
                        InkWell(
                          onTap: () => _handleTabNavigation(i),
                          child: CustomTab(
                            height: 80,
                            label: labels[i],
                            content: icons[i],
                            tabIndex: i,
                            selectedTabIndex: mainProvider.selectedTabIndex,
                          ),
                        ),
                    ],
                  ),
                )
                    : null,
              )
                  : const PreferredSize(preferredSize: Size(0, 0), child: SizedBox()),
              body: Row(
                children: [
                  if (constraints.maxWidth > 500)
                    Container(
                      width: constraints.maxWidth * 0.15,
                      color: Theme.of(context).primaryColorDark,
                      child: ListView(
                        padding: const EdgeInsets.all(10),
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const BackButton(color: Colors.white),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      programName,
                                      style: TextStyle(
                                        fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          for (int i = 0; i < labels.length; i++)
                            Material(
                              type: MaterialType.transparency,
                              child: ListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: constraints.maxWidth > 500 && constraints.maxWidth <= 600
                                    ? null
                                    : Text(labels[i], style: const TextStyle(color: Colors.white)),
                                leading: Icon(icons[i], color: Colors.white),
                                selected: _tabController.index == i,
                                selectedTileColor: _tabController.index == i ? Theme.of(context).primaryColorLight : null,
                                hoverColor: _tabController.index == i ? Theme.of(context).primaryColorLight : null,
                                onTap: () => _handleTabNavigation(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (int i = 0; i < labels.length; i++)
                          _buildTabContent(
                            index: i,
                            isIrrigationProgram: isIrrigationProgram,
                            conditionsLibraryIsNotEmpty: (mainProvider.conditionsLibraryIsNotEmpty),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (mainProvider.selectedTabIndex != 0)
                    _buildActionButton(
                      key: "prevPage",
                      icon: Icons.navigate_before,
                      onPressed: _navigateToPreviousTab,
                      context: context,
                    ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    child: Text(
                      "${mainProvider.selectedTabIndex + 1}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (mainProvider.selectedTabIndex != labels.length - 1)
                    _buildActionButton(
                      key: "nextPage",
                      icon: Icons.navigate_next,
                      context: context,
                      onPressed: () {
                        final nextIndex = _tabController.index + 1;
                        final mainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
                        if (_tabController.index == 0 &&
                            mainProvider.irrigationLine!.sequence.any((element) => element['valve'].isEmpty)) {
                          _showSequenceWarning(mainProvider);
                        } else if (_validateBeforeGoingTo(nextIndex, mainProvider)) {
                          _navigateToNextTab();
                        }
                      },
                    ),
                ],
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            ),
          );
        },
      );
    } else {
      final title = widget.serialNumber == 0 ? "New Program" : "Program ${widget.serialNumber}";
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: Container(
          color: Colors.grey[50],
        ),
      );
    }
  }

  /*Widget _buildTabContent({required int index, required bool isIrrigationProgram, required bool conditionsLibraryIsNotEmpty}) {
    switch (index) {
      case 0:
        return SequenceScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, serialNumber: widget.serialNumber);
      case 1:
        return ScheduleScreen(serialNumber: widget.serialNumber,);
      case 2:
        return isIrrigationProgram
            ? conditionsLibraryIsNotEmpty
            ? ConditionsScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, serialNumber: widget.serialNumber, deviceId: widget.deviceId,)
            : const SelectionScreen()
            : WaterAndFertilizerScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, serialNumber: widget.serialNumber, isIrrigationProgram: isIrrigationProgram,);
      case 3:
        return isIrrigationProgram
            ? conditionsLibraryIsNotEmpty
            ? const SelectionScreen()
            : WaterAndFertilizerScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, serialNumber: widget.serialNumber, isIrrigationProgram: isIrrigationProgram,)
            : const NewAlarmScreen2();
      case 4:
        return isIrrigationProgram
            ? conditionsLibraryIsNotEmpty
            ? WaterAndFertilizerScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, serialNumber: widget.serialNumber, isIrrigationProgram: isIrrigationProgram,)
            : const NewAlarmScreen2()
            : AdditionalDataScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, deviceId: widget.deviceId, serialNumber: widget.serialNumber, toDashboard: widget.toDashboard, fromDealer: widget.fromDealer, programType: widget.programType, conditionsLibraryIsNotEmpty: widget.conditionsLibraryIsNotEmpty, isIrrigationProgram: isIrrigationProgram,);
      case 5:
        return isIrrigationProgram
            ? conditionsLibraryIsNotEmpty
            ? const NewAlarmScreen2()
            : AdditionalDataScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, deviceId: widget.deviceId, serialNumber: widget.serialNumber, toDashboard: widget.toDashboard, fromDealer: widget.fromDealer, programType: widget.programType, conditionsLibraryIsNotEmpty: widget.conditionsLibraryIsNotEmpty, isIrrigationProgram: isIrrigationProgram,)
            : PreviewScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, deviceId: widget.deviceId, serialNumber: widget.serialNumber, toDashboard: widget.toDashboard, fromDealer: widget.fromDealer, programType: widget.programType, conditionsLibraryIsNotEmpty: widget.conditionsLibraryIsNotEmpty,);
      case 6:
        return conditionsLibraryIsNotEmpty
            ? AdditionalDataScreen(userId: overAllPvd.userId, controllerId: widget.controllerId, deviceId: widget.deviceId, serialNumber: widget.serialNumber, toDashboard: widget.toDashboard, fromDealer: widget.fromDealer, programType: widget.programType, conditionsLibraryIsNotEmpty: widget.conditionsLibraryIsNotEmpty, isIrrigationProgram: isIrrigationProgram,)
            : PreviewScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, deviceId: widget.deviceId, serialNumber: widget.serialNumber, toDashboard: widget.toDashboard, fromDealer: widget.fromDealer, programType: widget.programType, conditionsLibraryIsNotEmpty: widget.conditionsLibraryIsNotEmpty,);
      case 7:
        return conditionsLibraryIsNotEmpty
            ? PreviewScreen(userId: overAllPvd.takeSharedUserId ? overAllPvd.sharedUserId : overAllPvd.userId, controllerId: widget.controllerId, deviceId: widget.deviceId, serialNumber: widget.serialNumber, toDashboard: widget.toDashboard, fromDealer: widget.fromDealer, programType: widget.programType, conditionsLibraryIsNotEmpty: widget.conditionsLibraryIsNotEmpty,)
            : Container();
      default:
        return Container();
    }
  }
}*/

  Widget _buildTabContent({
    required int index,
    required bool isIrrigationProgram,
    required bool conditionsLibraryIsNotEmpty,
  }) {
    if (index < 0 || index >= labels.length) {
      return const SizedBox();
    }

    final label = labels[index];

    switch (label) {
      case 'Sequence':
        return SequenceScreen(
          userId: widget.customerId,
          controllerId: widget.controllerId,
          serialNumber: widget.serialNumber,
          deviceId: widget.deviceId,
          modelId: widget.modelId,
        );
      case 'Schedule':
        return ScheduleScreen(
          serialNumber: widget.serialNumber,
          modelId: widget.modelId,
        );
      case 'Conditions':
        return ConditionsScreen(
          userId: widget.userId,
          controllerId: widget.controllerId,
          serialNumber: widget.serialNumber,
          deviceId: widget.deviceId,
          customerId: widget.customerId,
        );
      case 'Selection':
        return SelectionScreen(
          modelId: widget.modelId,
          nodeList: widget.nodeList,
        );
      case 'Water & Fert':
      case 'Settings':
        return WaterAndFertilizerScreen(
          userId: widget.customerId,
          controllerId: widget.controllerId,
          serialNumber: widget.serialNumber,
          isIrrigationProgram: isIrrigationProgram,
          modelId: widget.modelId,
        );
      case 'Alarm':
        return AlarmScreen(
          modelId: widget.modelId,
        );
      case 'Additional':
        return AdditionalDataScreen(
          userId: widget.userId,
          controllerId: widget.controllerId,
          deviceId: widget.deviceId,
          serialNumber: widget.serialNumber,
          toDashboard: widget.toDashboard,
          fromDealer: widget.fromDealer,
          programType: widget.programType,
          isIrrigationProgram: isIrrigationProgram,
          customerId: widget.customerId,
          groupId: widget.groupId,
          categoryId: widget.categoryId,
          modelId: widget.modelId,
          deviceName: widget.deviceName,
          categoryName: widget.categoryName,
        );
      case 'Preview':
        return PreviewScreen(
          userId: widget.userId,
          controllerId: widget.controllerId,
          deviceId: widget.deviceId,
          serialNumber: widget.serialNumber,
          toDashboard: widget.toDashboard,
          fromDealer: widget.fromDealer,
          programType: widget.programType,
          customerId: widget.customerId,
          groupId: widget.groupId,
          categoryId: widget.categoryId,
          modelId: widget.modelId,
          deviceName: widget.deviceName,
          categoryName: widget.categoryName,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildActionButton({
    required String key,
    required IconData icon,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    return MaterialButton(
      key: Key(key),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: Theme.of(context).primaryColor,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}