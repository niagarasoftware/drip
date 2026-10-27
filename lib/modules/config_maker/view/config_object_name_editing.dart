import 'package:flutter/material.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';

/// Opens the Edit Object Names screen as a smooth right Side Sheet.
Future<void> showEditObjectNamesSideSheet({
  required BuildContext context,
  required ConfigMakerProvider configPvd,
  required List<DeviceObjectModel> listOfObjectInLine,
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
        child: EditObjectNamesSideSheet(
          configPvd: configPvd,
          listOfObjectInLine: listOfObjectInLine,
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

class EditObjectNamesSideSheet extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  final List<DeviceObjectModel> listOfObjectInLine;

  const EditObjectNamesSideSheet({
    super.key,
    required this.configPvd,
    required this.listOfObjectInLine,
  });

  @override
  State<EditObjectNamesSideSheet> createState() => _EditObjectNamesSideSheetState();
}

class _EditObjectNamesSideSheetState extends State<EditObjectNamesSideSheet> {
  late List<DeviceObjectModel> _editedObjects;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  final List<String> _categoryFilterOptions = [
    'All',
    'Sources',
    'Lines',
    'Pumps',
    'Valves',
    'Filters',
    'Fertilization',
    'Sensors & Others',
  ];

  @override
  void initState() {
    super.initState();
    _editedObjects = widget.listOfObjectInLine
        .map((object) => DeviceObjectModel.fromJson(object.toJson()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getObjectCategory(DeviceObjectModel obj) {
    int id = obj.objectId;
    if (id == AppConstants.sourceObjectId) return 'Sources';
    if (id == AppConstants.irrigationLineObjectId) return 'Lines';
    if (id == AppConstants.pumpObjectId || id == AppConstants.boosterObjectId) return 'Pumps';
    if ([
      AppConstants.valveObjectId,
      AppConstants.mainValveObjectId,
      AppConstants.tankValveObjectId,
      AppConstants.flowControlValveObjectId,
      AppConstants.gateObjectId,
    ].contains(id)) return 'Valves';
    if (id == AppConstants.filterObjectId || id == AppConstants.filterSiteObjectId) return 'Filters';
    if (id == AppConstants.fertilizerSiteObjectId || id == AppConstants.channelObjectId) return 'Fertilization';
    return 'Sensors & Others';
  }

  bool _matchesFilter(DeviceObjectModel obj) {
    final name = (obj.name ?? obj.objectName).toLowerCase();
    if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
      return false;
    }
    if (_selectedCategoryFilter == 'All') return true;
    return _getObjectCategory(obj) == _selectedCategoryFilter;
  }

  void _saveNames() {
    widget.configPvd.updateName(_editedObjects);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final filtered = _editedObjects.where(_matchesFilter).toList();
    final mediaWidth = MediaQuery.of(context).size.width;
    final double sheetWidth = mediaWidth > 640 ? 580 : mediaWidth * 0.92;

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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_note_rounded, size: 22, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Object Names',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Customize display names for sources, lines, valves and sensors',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF8E9BB4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                    child: Text(
                      '${_editedObjects.length} Objects',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
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
            ),

            // ───────────────────────── Search & Category Filters ─────────────────────────
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
                      hintText: 'Search object by name...',
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
                      children: _categoryFilterOptions.map((category) {
                        final bool active = _selectedCategoryFilter == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: active,
                            onSelected: (bool sel) {
                              if (sel) {
                                setState(() => _selectedCategoryFilter = category);
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

            // ───────────────────────── Object Names List ─────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF8E9BB4)),
                            const SizedBox(height: 10),
                            const Text(
                              'No Matching Objects Found',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No objects match "$_searchQuery".',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF8E9BB4)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final category = _getObjectCategory(item);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181C38),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2B335C)),
                          ),
                          child: Row(
                            children: [
                              // Icon Badge
                              Container(
                                width: 36,
                                height: 36,
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                                ),
                                child: SizedImage(
                                  imagePath: '${AppConstants.svgObjectPath}objectId_${item.objectId}.svg',
                                  color: primary,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Default Name & Category
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.objectName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF12162B),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFF2B335C)),
                                          ),
                                          child: Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                              color: primary,
                                            ),
                                          ),
                                        ),
                                        if (item.sNo != null) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            'sNo: ${item.sNo}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF8E9BB4),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Custom Name Input
                              Expanded(
                                flex: 5,
                                child: TextFormField(
                                  initialValue: item.name,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: item.objectName,
                                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    isDense: true,
                                    filled: true,
                                    fillColor: const Color(0xFF12162B),
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
                                  onChanged: (value) {
                                    item.name = value;
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8E9BB4),
                        side: const BorderSide(color: Color(0xFF2B335C)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saveNames,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text(
                        'Save Names',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
}

/// Class wrapper for backwards compatibility with any existing callers.
class ConfigObjectNameEditing extends StatelessWidget {
  final ConfigMakerProvider configPvd;
  final List<DeviceObjectModel> listOfObjectInLine;

  const ConfigObjectNameEditing({
    super.key,
    required this.listOfObjectInLine,
    required this.configPvd,
  });

  @override
  Widget build(BuildContext context) {
    return EditObjectNamesSideSheet(
      configPvd: configPvd,
      listOfObjectInLine: listOfObjectInLine,
    );
  }
}
