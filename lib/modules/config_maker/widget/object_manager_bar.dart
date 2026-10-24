import 'package:flutter/material.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../utils/constants.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import '../view/product_limit.dart';


// ═════════════════════════════════════════════════════════════════════════════
//  Rules that decide which objects may be created and how many.
//  They mirror the Product Limit page so both pages stay consistent.
// ═════════════════════════════════════════════════════════════════════════════

/// Model-specific hard cap for an object (null = only hardware capacity limits it).
/// Mirrors ToggleTextFormFieldForProductLimit._updateCount.
int? maxCountForObject(ConfigMakerProvider p, DeviceObjectModel o) {
  final modelId = p.masterData['modelId'];
  final id = o.objectId;

  if (o.type == '-') {
    if (AppConstants.ecoGemModelList.contains(modelId) && id == AppConstants.irrigationLineObjectId) return 1;
    return null;
  }
  if (AppConstants.pumpModelList.contains(modelId)) {
    if ([AppConstants.levelObjectId, AppConstants.waterMeterObjectId].contains(id)) return 1;
    if (id == AppConstants.pressureSensorObjectId) return 2;
    return null;
  }
  if (AppConstants.pumpWithValveModelList.contains(modelId)) {
    if (id == AppConstants.pumpObjectId) return 1;
    if (id == AppConstants.lightObjectId && AppConstants.pumpWithLightModelList.contains(modelId)) return 10;
    if ([
      AppConstants.lightObjectId,
      AppConstants.pressureSensorObjectId,
      AppConstants.pressureSwitchObjectId,
      AppConstants.soilTemperatureObjectId,
    ].contains(id)) {
      return 1;
    }
    return null;
  }
  if (AppConstants.ecoGemModelList.contains(modelId)) {
    if (id == AppConstants.pumpObjectId) return 2;
    if ([AppConstants.filterObjectId, AppConstants.pressureSensorObjectId].contains(id)) return 2;
    if ([AppConstants.channelObjectId, AppConstants.boosterObjectId, AppConstants.levelObjectId].contains(id)) return 1;
  }
  return null;
}

/// Mirrors ProductLimitGridListTile.dependentObjectByCommonObject (which objects
/// exist at all for this master model).
bool isObjectAllowedForModel(ConfigMakerProvider p, int objectId) {
  final modelId = p.masterData['modelId'];

  if (AppConstants.pumpWithValveModelList.contains(modelId)) {
    return true;
  }
  if (AppConstants.ecoGemModelList.contains(modelId) && !AppConstants.ecoGemFlowControlValveModel.contains(modelId)) {
    return const [1, 2, 3, 4, 5, 7, 9, 10, 11, 13, 22, 24, 25, 26, 30, 40].contains(objectId);
  }
  if (AppConstants.aquacultureModelList.contains(modelId)) {
    return const [1, 2, 5, 40].contains(objectId);
  }

  return true;
}

// ═════════════════════════════════════════════════════════════════════════════
//  Widget
// ═════════════════════════════════════════════════════════════════════════════

class ObjectManagerBar extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  final DeviceModel selectedDevice;

  /// Terminal type of the active tab ('1,2', '3', ...). Null lists every type the node supports.
  final String? activeType;
  final VoidCallback onChanged;

  const ObjectManagerBar({
    super.key,
    required this.configPvd,
    required this.selectedDevice,
    required this.activeType,
    required this.onChanged,
  });

  @override
  State<ObjectManagerBar> createState() => _ObjectManagerBarState();
}

class _ObjectManagerBarState extends State<ObjectManagerBar> {
  final TextEditingController _name = TextEditingController();
  int? _selectedObjectId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Object kinds that can be created for the open node / tab.
  List<DeviceObjectModel> _options() {
    final p = widget.configPvd;
    final seen = <int>{};
    return p.listOfSampleObjectModel.where((o) {
      if (o.type == '-') return false;
      if (widget.activeType != null && o.type != widget.activeType) return false;
      if (!widget.selectedDevice.connectingObjectId.contains(o.objectId)) return false;
      if (o.objectId == AppConstants.powerSupplyObjectId) return false; // wired by its own checkbox
      if (o.objectId == AppConstants.pumpObjectId && AppConstants.ecoGemModelList.contains(p.masterData['modelId'])) {
        return false; // eco gem pumps are not wired to nodes
      }
      if (!isObjectAllowedForModel(p, o.objectId)) return false;
      return seen.add(o.objectId);
    }).toList();
  }

  List<DeviceObjectModel> _generatedOf(int objectId) =>
      widget.configPvd.listOfGeneratedObject.where((o) => o.objectId == objectId).toList();

  void _alert(String message) => simpleDialogBox(context: context, title: 'Alert', message: message);

  void _add(DeviceObjectModel kind) {
    final p = widget.configPvd;
    final int current = int.tryParse(kind.count ?? '') ?? 0;

    final int? cap = maxCountForObject(p, kind);
    if (cap != null && current + 1 > cap) {
      _alert('Only $cap ${kind.objectName} should be connected with ${p.masterData['deviceName']}.');
      return;
    }

    final bool ecoGemPump =
        kind.objectId == AppConstants.pumpObjectId && AppConstants.ecoGemModelList.contains(p.masterData['modelId']);
    if (kind.type != '-' && !ecoGemPump) {
      final int available =
      kind.type == '1,2' ? balanceCountForRelayLatch(p) : balanceCountForInputType(int.parse(kind.type), p);
      if (available <= 0) {
        _alert('No free ${kind.type == '1,2' ? 'relay/latch' : 'input'} capacity is left for ${kind.objectName}. '
            'Add a node with more terminals or remove another object first.');
        return;
      }
    }

    p.updateObjectCount(kind.objectId, '${current + 1}');

    final created = _generatedOf(kind.objectId);
    final String typed = _name.text.trim();
    if (created.isNotEmpty && typed.isNotEmpty) {
      created.last.name = typed;
      p.updateName([created.last]); // keeps ec / ph copies and site models in sync
    }
    _name.clear();
    widget.onChanged();
  }

  void _remove(DeviceObjectModel kind) {
    final p = widget.configPvd;
    final list = _generatedOf(kind.objectId);
    if (list.isEmpty) {
      _alert('There is no ${kind.objectName} to remove.');
      return;
    }
    // the provider always drops the newest object, so only that one may be wired
    final last = list.last;
    if (last.controllerId != null) {
      String where = 'a node';
      for (final d in p.listOfDeviceModel) {
        if (d.controllerId == last.controllerId) where = d.deviceName;
      }
      _alert('${last.name ?? last.objectName} is wired to $where. Detach it first, then remove it.');
      return;
    }
    final int current = int.tryParse(kind.count ?? '') ?? list.length;
    p.updateObjectCount(kind.objectId, '${current - 1}');
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final options = _options();

    if (options.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
        child: Text('No object types can be added to this node.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      );
    }

    if (!options.any((o) => o.objectId == _selectedObjectId)) {
      _selectedObjectId = options.first.objectId;
    }
    final kind = options.firstWhere((o) => o.objectId == _selectedObjectId);
    final generated = _generatedOf(kind.objectId);
    final int unassigned = generated.where((o) => o.controllerId == null).length;

    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF8E9BB4), fontSize: 12),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFF12162B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2A3258))),
      enabledBorder:
      OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2A3258))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.6)),
    );

    Widget stepButton({required IconData icon, required String tooltip, required VoidCallback onTap, required Color bgColor, required Color iconColor, required Color borderColor}) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181C38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF232A4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.playlist_add_rounded, size: 16, color: Color(0xFFC084FC)),
              const SizedBox(width: 6),
              const Text('Manage objects',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFC084FC))),
              const Spacer(),
              Text('In project ${generated.length}  ·  Unassigned $unassigned',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF8E9BB4))),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<int>(
                  value: _selectedObjectId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF181C38),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: deco('Object type'),
                  items: [
                    for (final o in options)
                      DropdownMenuItem<int>(
                        value: o.objectId,
                        child: Text(o.objectName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.white)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _selectedObjectId = v),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _name,
                  maxLength: 30,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: deco('Name (optional)').copyWith(counterText: ''),
                  onSubmitted: (_) => _add(kind),
                ),
              ),
              stepButton(
                icon: Icons.remove_rounded,
                tooltip: 'Remove the newest ${kind.objectName}',
                bgColor: const Color(0xFF311A24),
                iconColor: const Color(0xFFEF4444),
                borderColor: const Color(0xFF6B2332),
                onTap: () => _remove(kind),
              ),
              stepButton(
                icon: Icons.add_rounded,
                tooltip: 'Add ${kind.objectName}',
                bgColor: Theme.of(context).primaryColor,
                iconColor: Colors.white,
                borderColor: Theme.of(context).primaryColor,
                onTap: () => _add(kind),
              ),
            ],
          ),
        ],
      ),
    );
  }
}