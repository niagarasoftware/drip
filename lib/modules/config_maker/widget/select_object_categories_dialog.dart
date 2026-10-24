import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../utils/constants.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import '../view/product_limit.dart';
import 'object_manager_bar.dart';

/// Opens the Select Configurable Objects screen as a smooth right Side Sheet.
Future<void> showSelectObjectCategoriesSideSheet({
  required BuildContext context,
  required ConfigMakerProvider configPvd,
  required DeviceModel selectedDevice,
  required VoidCallback onChanged,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim1, anim2) {
      return Align(
        alignment: Alignment.centerRight,
        child: SelectObjectCategoriesSideSheet(
          configPvd: configPvd,
          selectedDevice: selectedDevice,
          onChanged: onChanged,
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
  );
}

/// Alias for backwards compatibility.
Future<void> showSelectObjectCategoriesDialog({
  required BuildContext context,
  required ConfigMakerProvider configPvd,
  required DeviceModel selectedDevice,
  required VoidCallback onChanged,
}) =>
    showSelectObjectCategoriesSideSheet(
      context: context,
      configPvd: configPvd,
      selectedDevice: selectedDevice,
      onChanged: onChanged,
    );

class SelectObjectCategoriesSideSheet extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  final DeviceModel selectedDevice;
  final VoidCallback onChanged;

  const SelectObjectCategoriesSideSheet({
    super.key,
    required this.configPvd,
    required this.selectedDevice,
    required this.onChanged,
  });

  @override
  State<SelectObjectCategoriesSideSheet> createState() =>
      _SelectObjectCategoriesSideSheetState();
}

class _SelectObjectCategoriesSideSheetState
    extends State<SelectObjectCategoriesSideSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTypeFilter = 'All';

  final List<String> _typeFilterOptions = [
    'All',
    'Outputs (Relay/Latch)',
    'Analog Input',
    'Digital Input',
    'Moisture Input',
    'Pulse Input',
    'I2C Input',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DeviceObjectModel> _getAvailableCategories() {
    final p = widget.configPvd;
    final possibleConnectingIds = p.getPossibleConnectingObjectId().toSet();
    final seen = <int>{};

    return p.listOfSampleObjectModel.where((o) {
      if (o.type == '-') return false;
      if (o.objectId == AppConstants.powerSupplyObjectId) return false;
      if (o.objectId == AppConstants.pumpObjectId &&
          AppConstants.ecoGemModelList.contains(p.masterData['modelId'])) {
        return false;
      }
      if (!possibleConnectingIds.contains(o.objectId)) return false;
      if (!isObjectAllowedForModel(p, o.objectId)) return false;
      return seen.add(o.objectId);
    }).toList();
  }

  String _getTypeName(String type) {
    switch (type) {
      case '1,2':
        return 'Relay/Latch';
      case '3':
        return 'Analog Input';
      case '4':
        return 'Digital Input';
      case '5':
        return 'Moisture Input';
      case '6':
        return 'Pulse Input';
      case '7':
        return 'I2C Input';
      default:
        return 'I/O';
    }
  }

  Color _getTypeColor(String type) {
    return type == '1,2'
        ? AppConstants.outputColor
        : getObjectTypeCodeToColor(int.parse(type));
  }

  bool _matchesFilter(DeviceObjectModel o) {
    if (_searchQuery.isNotEmpty &&
        !o.objectName.toLowerCase().contains(_searchQuery.toLowerCase())) {
      return false;
    }
    if (_selectedTypeFilter == 'All') return true;
    if (_selectedTypeFilter == 'Outputs (Relay/Latch)' && o.type == '1,2') {
      return true;
    }
    if (_selectedTypeFilter == 'Analog Input' && o.type == '3') return true;
    if (_selectedTypeFilter == 'Digital Input' && o.type == '4') return true;
    if (_selectedTypeFilter == 'Moisture Input' && o.type == '5') return true;
    if (_selectedTypeFilter == 'Pulse Input' && o.type == '6') return true;
    if (_selectedTypeFilter == 'I2C Input' && o.type == '7') return true;
    return false;
  }

  void _alert(String message) {
    simpleDialogBox(context: context, title: 'Alert', message: message);
  }

  void _toggleCategory(DeviceObjectModel kind) {
    final p = widget.configPvd;
    final generated = p.listOfGeneratedObject
        .where((g) => g.objectId == kind.objectId)
        .toList();
    final bool isSelected = generated.isNotEmpty;

    if (isSelected) {
      // User wants to remove this category
      final wiredCount = generated.where((g) => g.controllerId != null).length;
      if (wiredCount > 0) {
        _alert(
            '$wiredCount ${kind.objectName}(s) are currently wired to nodes. Please detach them from nodes first before removing this category.');
        return;
      }
      p.updateObjectCount(kind.objectId, '0');
    } else {
      // User wants to select/add 1 object for this category
      final int? cap = maxCountForObject(p, kind);
      if (cap != null && cap < 1) {
        _alert('Cannot add ${kind.objectName} for this master controller model.');
        return;
      }

      final bool ecoGemPump = kind.objectId == AppConstants.pumpObjectId &&
          AppConstants.ecoGemModelList
              .contains(p.masterData['modelId']);
      if (kind.type != '-' && !ecoGemPump) {
        final int available = kind.type == '1,2'
            ? balanceCountForRelayLatch(p)
            : balanceCountForInputType(int.parse(kind.type), p);
        if (available <= 0) {
          _alert(
              'No free ${kind.type == '1,2' ? 'relay/latch' : 'input'} terminal capacity is left for ${kind.objectName}.');
          return;
        }
      }
      p.updateObjectCount(kind.objectId, '1');
    }

    widget.onChanged();
    setState(() {});
  }

  Widget _buildCompactObjectCard(DeviceObjectModel kind) {
    final generated = widget.configPvd.listOfGeneratedObject
        .where((g) => g.objectId == kind.objectId)
        .toList();
    final int count = generated.length;
    final bool isSelected = count > 0;
    final Color typeColor = _getTypeColor(kind.type);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _toggleCategory(kind),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Color.alphaBlend(typeColor.withValues(alpha: 0.18), const Color(0xFF181C38))
              : const Color(0xFF181C38),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? typeColor : const Color(0xFF2B335C),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: typeColor.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A2035),
                border: Border.all(color: typeColor, width: 1.5),
              ),
              padding: const EdgeInsets.all(7),
              child: SvgPicture.asset(
                'assets/Images/Svg/objectId_${kind.objectId}.svg',
                colorFilter: ColorFilter.mode(typeColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kind.objectName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _getTypeName(kind.type),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? typeColor : const Color(0xFF8E9BB4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected ? typeColor.withValues(alpha: 0.18) : const Color(0xFF12162B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isSelected ? '$count in project' : 'Not added',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? typeColor : const Color(0xFF8E9BB4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final allAvailable = _getAvailableCategories();
    final filtered = allAvailable.where(_matchesFilter).toList();

    final int selectedTotal = allAvailable
        .where((o) => widget.configPvd.listOfGeneratedObject
            .any((g) => g.objectId == o.objectId))
        .length;

    final mediaWidth = MediaQuery.of(context).size.width;
    final double sheetWidth = mediaWidth > 640 ? 560 : mediaWidth * 0.92;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: sheetWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0C0F1D),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // ───────────────────────── Header Bar ─────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF13172E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF20274B)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.tune_rounded, size: 20, color: primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Configurable Objects',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Nodes under ${widget.configPvd.masterData['deviceName'] ?? 'Master'}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF8E9BB4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 13, color: primary),
                            const SizedBox(width: 5),
                            Text(
                              '$selectedTotal / ${allAvailable.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: const Color(0xFF8E9BB4),
                        tooltip: 'Close',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ───────────────────────── Search & Filter Controls ─────────────────────────
            Container(
              color: const Color(0xFF13172E),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 12.5, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search category...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF8E9BB4)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF8E9BB4)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF8E9BB4)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFF181C38),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF2B335C)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF2B335C)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Filter Chips Carousel
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _typeFilterOptions.map((option) {
                        final bool active = _selectedTypeFilter == option;
                        return Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: ChoiceChip(
                            label: Text(option),
                            selected: active,
                            onSelected: (bool sel) {
                              if (sel) {
                                setState(() => _selectedTypeFilter = option);
                              }
                            },
                            selectedColor: primary,
                            elevation: 0,
                            pressElevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: active ? primary : const Color(0xFF2B335C),
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: active ? Colors.white : const Color(0xFF8E9BB4),
                              fontWeight: active ? FontWeight.bold : FontWeight.w600,
                              fontSize: 11,
                            ),
                            backgroundColor: const Color(0xFF181C38),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFF20274B)),

            // ───────────────────────── Object Categories Grid ─────────────────────────
            Expanded(
              child: allAvailable.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hub_outlined, size: 40, color: Color(0xFF8E9BB4)),
                            const SizedBox(height: 10),
                            const Text(
                              'No Configurable Nodes Available',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Please add a node under master first to select available object categories.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF8E9BB4)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No objects match your search.',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF8E9BB4)),
                          ),
                        )
                      : ResponsiveGridList(
                          horizontalGridMargin: 10,
                          verticalGridMargin: 6,
                          minItemWidth: 155,
                          children: filtered.map(_buildCompactObjectCard).toList(),
                        ),
            ),

            // ───────────────────────── Footer Action Bar ─────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF13172E),
                border: Border(
                  top: BorderSide(color: Color(0xFF20274B)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(
                    'Done ($selectedTotal Categories Configured)',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
