import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';

import '../modules/config_maker/model/device_object_model.dart';
import '../modules/config_maker/state_management/config_maker_provider.dart';
import '../Widgets/custom_buttons.dart';


void simpleDialogBox({
  required BuildContext context,
  required String title,
  required String message,
  Widget? content,
  List<Widget>? actionButton,
}){
  final lowerTitle = title.toLowerCase();
  IconData iconData = Icons.info_outline_rounded;
  Color iconColor = Theme.of(context).primaryColor;
  Color iconBgColor = Theme.of(context).primaryColor.withOpacity(0.1);

  if (lowerTitle.contains('success')) {
    iconData = Icons.check_circle_rounded;
    iconColor = Colors.teal.shade700;
    iconBgColor = Colors.teal.shade50;
  } else if (lowerTitle.contains('failed') || lowerTitle.contains('error')) {
    iconData = Icons.error_outline_rounded;
    iconColor = Colors.red.shade600;
    iconBgColor = Colors.red.shade50;
  } else if (lowerTitle.contains('alert') || lowerTitle.contains('warning')) {
    iconData = Icons.warning_amber_rounded;
    iconColor = Colors.amber.shade800;
    iconBgColor = Colors.amber.shade50;
  }

  showDialog(
      useRootNavigator: true,
      context: context,
      builder: (context){
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xff1E293B),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: content ?? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/Images/Png/no_data.png',
                    width: 90,
                    height: 90,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.folder_open_rounded,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xff475467),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if(actionButton != null)
              ...actionButton
            else
              const CustomMaterialButton()
          ],
        );
      }
  );
}

void selectionDialogBox({
  required BuildContext context,
  required String title,
  required bool singleSelection,
  required void Function()? onPressed,
  required List<DeviceObjectModel> listOfObject,
}){
  String searchQuery = '';
  final searchController = TextEditingController();

  showDialog(
      context: context,
      builder: (context){
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Consumer<ConfigMakerProvider>(
              builder: (BuildContext context, ConfigMakerProvider configPvd, Widget? child) {
                final validObjects = listOfObject.where((object) {
                  bool matchesModel = false;
                  if (AppConstants.ecoGemModelList.contains(configPvd.masterData['modelId']) && object.objectId == AppConstants.pumpObjectId) {
                    matchesModel = true;
                  } else {
                    if ([AppConstants.fertilizerSiteObjectId, AppConstants.filterSiteObjectId, AppConstants.sourceObjectId].contains(object.objectId)) {
                      matchesModel = true;
                    } else {
                      matchesModel = object.controllerId != null;
                    }
                  }
                  if (!matchesModel) return false;

                  if (searchQuery.isNotEmpty) {
                    return object.name != null && object.name!.toLowerCase().contains(searchQuery.toLowerCase());
                  }
                  return true;
                }).toList();

                if (validObjects.length == 1) {
                  if (singleSelection) {
                    if (configPvd.selectedSno == 0.0) {
                      configPvd.selectedSno = validObjects.first.sNo ?? 0.0;
                    }
                  } else {
                    if (configPvd.listOfSelectedSno.isEmpty && validObjects.first.sNo != null) {
                      configPvd.listOfSelectedSno.add(validObjects.first.sNo!);
                    }
                  }
                }

                int selectedCount = singleSelection
                    ? (configPvd.selectedSno != 0.0 ? 1 : 0)
                    : configPvd.listOfSelectedSno.length;

                double screenWidth = MediaQuery.of(context).size.width;
                double screenHeight = MediaQuery.of(context).size.height;
                double dialogWidth = screenWidth >= 550 ? 520 : screenWidth * 0.9;
                double dialogHeight = screenHeight * 0.75;
                if (dialogHeight > 520) dialogHeight = 520;

                return Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 10,
                  child: SizedBox(
                    width: dialogWidth,
                    height: dialogHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.touch_app_rounded,
                                  color: Theme.of(context).primaryColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xff1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      singleSelection
                                          ? (selectedCount > 0 ? '1 item selected' : 'Select an item')
                                          : '$selectedCount item${selectedCount == 1 ? '' : 's'} selected',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                                tooltip: 'Close',
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Search & Controls Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: TextField(
                                        controller: searchController,
                                        onChanged: (val) {
                                          setDialogState(() {
                                            searchQuery = val;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Search items...',
                                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade600),
                                          suffixIcon: searchQuery.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                                  onPressed: () {
                                                    setDialogState(() {
                                                      searchController.clear();
                                                      searchQuery = '';
                                                    });
                                                  },
                                                )
                                              : null,
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!singleSelection) ...[
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        configPvd.updateRangeMode(!configPvd.rangeMode);
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: configPvd.rangeMode
                                              ? Theme.of(context).primaryColor.withOpacity(0.12)
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: configPvd.rangeMode
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              configPvd.rangeMode
                                                  ? Icons.check_box_rounded
                                                  : Icons.check_box_outline_blank_rounded,
                                              size: 18,
                                              color: configPvd.rangeMode
                                                  ? Theme.of(context).primaryColor
                                                  : Colors.grey.shade700,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Range',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: configPvd.rangeMode
                                                    ? Theme.of(context).primaryColor
                                                    : Colors.grey.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (!singleSelection && validObjects.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        for (var obj in validObjects) {
                                          if (obj.sNo != null && !configPvd.listOfSelectedSno.contains(obj.sNo)) {
                                            configPvd.listOfSelectedSno.add(obj.sNo!);
                                          }
                                        }
                                        configPvd.listOfSelectedSno.sort();
                                        setDialogState(() {});
                                      },
                                      icon: const Icon(Icons.select_all_rounded, size: 16),
                                      label: const Text('Select All', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        configPvd.listOfSelectedSno.clear();
                                        setDialogState(() {});
                                      },
                                      icon: const Icon(Icons.deselect_rounded, size: 16),
                                      label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Content Area (Grid / List)
                        Expanded(
                          child: validObjects.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.device_unknown_outlined,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No objects available',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'There are no available items to select for this parameter.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: validObjects.map((object) {
                                      final isSelected = singleSelection
                                          ? configPvd.selectedSno == object.sNo
                                          : configPvd.listOfSelectedSno.contains(object.sNo);

                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(10),
                                          onTap: () {
                                            if (!singleSelection) {
                                              if (configPvd.rangeMode) {
                                                List<double> list = validObjects.map((obj) => obj.sNo!).toList();
                                                configPvd.updateListOfSelectedSnoWhenRangeMode(list, list.indexOf(object.sNo!));
                                              } else {
                                                configPvd.updateListOfSelectedSno(object.sNo!);
                                              }
                                            } else {
                                              configPvd.updateSelectedSno(object.sNo!);
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: isSelected
                                                  ? Theme.of(context).primaryColor
                                                  : Colors.grey.shade100,
                                              border: Border.all(
                                                color: isSelected
                                                    ? Theme.of(context).primaryColor
                                                    : Colors.grey.shade300,
                                                width: 1.2,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
                                                      )
                                                    ]
                                                  : [],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isSelected
                                                      ? Icons.check_circle_rounded
                                                      : (singleSelection
                                                          ? Icons.radio_button_unchecked_rounded
                                                          : Icons.check_box_outline_blank_rounded),
                                                  size: 18,
                                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  object.name ?? '',
                                                  style: TextStyle(
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                    color: isSelected ? Colors.white : const Color(0xff334155),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ),

                        // Footer Actions
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                singleSelection
                                    ? (configPvd.selectedSno != 0.0 ? '1 item selected' : 'No selection')
                                    : '${configPvd.listOfSelectedSno.length} selected',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Row(
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      elevation: 2,
                                    ),
                                    onPressed: onPressed,
                                    child: const Text(
                                      'Apply',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }
  );
}
