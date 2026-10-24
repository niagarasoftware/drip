import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../Widgets/custom_buttons.dart';
import '../../../utils/constants.dart';
import '../model/device_model.dart';
import '../repository/config_maker_repository.dart';
import '../state_management/config_maker_provider.dart';
import 'drop_down_search_field.dart';

/// Interval choices (seconds) – same list the Device List page uses.
const List<int> kNodeIntervalChoices = [5, 10, 15, 20, 25];

// ═════════════════════════════════════════════════════════════════════════════
//  Shared rules (mirrors Device List page so both pages behave the same)
// ═════════════════════════════════════════════════════════════════════════════

/// Nodes that are in stock for this account but not yet attached to the master.
List<DeviceModel> availableNodesFor(ConfigMakerProvider p) {
  final modelId = p.masterData['modelId'];
  const nodeUnderPumpWithValveModel = [15, 17, 23, 25, 42];
  const nodeUnderEcoGemModel = [36, 50, 42];
  const nodeNotUnderGemModel = [48, 49];

  return p.listOfDeviceModel.where((n) => n.masterId == null).where((n) {
    if (AppConstants.pumpWithValveModelList.contains(modelId) && nodeUnderPumpWithValveModel.contains(n.modelId)) {
      return true;
    } else if (AppConstants.ecoGemModelList.contains(modelId) && nodeUnderEcoGemModel.contains(n.modelId)) {
      return true;
    } else if (AppConstants.gemModelList.contains(modelId) && !nodeNotUnderGemModel.contains(n.modelId)) {
      return true;
    } else if (AppConstants.omsGemList.contains(modelId)) {
      return true;
    }
    return false;
  }).toList();
}

bool nodeSupportsExtend(ConfigMakerProvider p, DeviceModel device) {
  return ![44, 45, 46, 47].contains(device.modelId) &&
      p.listOfDeviceModel.any((d) => d.categoryId == 10 && d.masterId != null) &&
      device.interfaceTypeId == 1;
}

List<DeviceModel> extendOptionsFor(ConfigMakerProvider p) {
  return p.listOfDeviceModel
      .where((d) => d.masterId != null && d.categoryId == 10 && !AppConstants.extendLoraList.contains(d.modelId))
      .toList();
}

/// Returns a message when the node may not be removed, otherwise null.
String? nodeDeleteBlocker(ConfigMakerProvider p, DeviceModel device) {
  final bool configured = p.listOfGeneratedObject.any((o) => o.controllerId == device.controllerId);
  final int valveCount = p.listOfGeneratedObject.where((o) => o.objectId == AppConstants.valveObjectId).length;
  final int moistureCount = p.listOfGeneratedObject.where((o) => o.objectId == AppConstants.moistureObjectId).length;
  final modelId = p.masterData['modelId'];

  if (configured) {
    return '${device.deviceName} cannot be removed. Please detach all connected objects first.';
  }
  if (AppConstants.pumpWithValveModelList.contains(modelId)) {
    final bool isSense = AppConstants.senseModelList.contains(device.modelId);
    if (isSense && moistureCount != 0) {
      return '${device.deviceName} cannot be removed. Because Moisture connected to ${device.deviceName}.';
    }
    if (![...AppConstants.pumpWithValveModelList, ...AppConstants.senseModelList].contains(device.modelId) &&
        valveCount > 2) {
      return '${device.deviceName} cannot be removed. Because valve connected to ${device.deviceName}';
    }
  }
  return null;
}

/// Detaches the node from the master. Callers must check [nodeDeleteBlocker] first.
void detachNodeFromMaster(ConfigMakerProvider p, DeviceModel device) {
  final int removedId = device.controllerId;
  device.masterId = null;
  device.serialNumber = null;
  device.extendControllerId = null;
  device.select = false;
  if (device.categoryId == 10) {
    // anything that was extended through this node falls back to direct
    for (final d in p.listOfDeviceModel) {
      if (d.extendControllerId != null && d.extendControllerId == removedId) {
        d.extendControllerId = null;
      }
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Add node
// ═════════════════════════════════════════════════════════════════════════════

Future<void> showAddNodeDialog({
  required BuildContext context,
  required ConfigMakerProvider configPvd,
  required VoidCallback onChanged,
}) async {
  final candidates = availableNodesFor(configPvd);
  if (candidates.isEmpty) {
    simpleDialogBox(
      context: context,
      title: 'Alert',
      message: 'There are no available nodes to configure at the moment',
    );
    return;
  }

  final primary = Theme.of(context).primaryColor;
  final picked = <int>{}; // controllerIds

  final bool? added = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final bool allSelected = picked.length == candidates.length;
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.hub_rounded, color: primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Node',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1E293B))),
                    SizedBox(height: 2),
                    Text('Select nodes to configure under the master controller',
                        style: TextStyle(fontSize: 12, color: Color(0xff64748B), fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(ctx).size.width >= 550 ? 550 : double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Checkbox(
                          value: allSelected,
                          activeColor: primary,
                          onChanged: (_) => setLocal(() {
                            if (allSelected) {
                              picked.clear();
                            } else {
                              picked.addAll(candidates.map((n) => n.controllerId));
                            }
                          }),
                        ),
                        const Text('Select all available nodes',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff334155))),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${picked.length} selected',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final node in candidates)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: picked.contains(node.controllerId) ? primary.withOpacity(0.04) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: picked.contains(node.controllerId) ? primary : Colors.grey.shade200,
                          width: picked.contains(node.controllerId) ? 1.5 : 1.0,
                        ),
                      ),
                      child: CheckboxListTile(
                        activeColor: primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        value: picked.contains(node.controllerId),
                        onChanged: (v) => setLocal(() {
                          if (v == true) {
                            picked.add(node.controllerId);
                          } else {
                            picked.remove(node.controllerId);
                          }
                        }),
                        title: Text(node.deviceName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1E293B))),
                        subtitle: Wrap(
                          spacing: 8,
                          children: [
                            Text(node.modelDescription,
                                style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w500)),
                            Text('•  ID: ${node.deviceId}',
                                style: const TextStyle(color: Color(0xff64748B), fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xff475467))),
            ),
            CustomMaterialButton(
              title: 'Add Selected',
              icon: Icons.add_rounded,
              onPressed: () {
                if (picked.isEmpty) return;
                // keep the running serial number in sync with what is already attached
                for (final d in configPvd.listOfDeviceModel) {
                  if (d.serialNumber != null && d.masterId != null && configPvd.serialNumber < d.serialNumber!) {
                    configPvd.serialNumber = d.serialNumber!;
                  }
                }
                for (final d in configPvd.listOfDeviceModel) {
                  if (picked.contains(d.controllerId)) {
                    configPvd.serialNumber += 1;
                    d.masterId = configPvd.masterData['controllerId'];
                    d.serialNumber = configPvd.serialNumber;
                    d.select = false;
                  }
                }
                configPvd.listOfDeviceModel.sort((a, b) {
                  if (a.serialNumber == null && b.serialNumber == null) return 0;
                  if (a.serialNumber == null) return 1; // nulls last
                  if (b.serialNumber == null) return -1;
                  return a.serialNumber!.compareTo(b.serialNumber!);
                });
                Navigator.pop(ctx, true);
              },
            ),
          ],
        );
      },
    ),
  );

  if (added == true) onChanged();
}

// ═════════════════════════════════════════════════════════════════════════════
//  Edit node  (extend / interval / device id / delete)
// ═════════════════════════════════════════════════════════════════════════════

enum _NodeEditAction { cancel, save, delete, replaceId, replaceFromStock }

Future<void> showEditNodeDialog({
  required BuildContext context,
  required ConfigMakerProvider configPvd,
  required DeviceModel node,
  required bool canEditDeviceId,
  required VoidCallback onChanged,
}) async {
  final primary = Theme.of(context).primaryColor;
  final bool showExtend = nodeSupportsExtend(configPvd, node);
  final extendOptions = extendOptionsFor(configPvd).where((d) => d.controllerId != node.controllerId).toList();

  int? extendId = extendOptions.any((d) => d.controllerId == node.extendControllerId) ? node.extendControllerId : null;
  bool extendTouched = false;
  int interval = node.interfaceInterval ?? 5;
  final idController = TextEditingController(text: node.deviceId);

  InputDecoration deco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: primary, size: 20),
    filled: true,
    fillColor: Colors.grey.shade50,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder:
    OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary, width: 2)),
  );

  Widget sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(text.toUpperCase(),
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.grey.shade600)),
  );

  final _NodeEditAction? action = await showDialog<_NodeEditAction>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final intervalItems = {...kNodeIntervalChoices, interval}.toList()..sort();
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.edit_rounded, color: primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.deviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xff1E293B))),
                    Text(node.modelDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xff64748B), fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(ctx).size.width >= 460 ? 420 : double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionLabel('Communication'),
                  if (showExtend)
                    DropdownButtonFormField<int?>(
                      value: extendId,
                      isExpanded: true,
                      decoration: deco('Extend through', Icons.cell_tower_rounded),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('None (direct)')),
                        for (final d in extendOptions)
                          DropdownMenuItem<int?>(
                            value: d.controllerId,
                            child: Text('${d.deviceName}  ·  ${d.deviceId}', overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (v) => setLocal(() {
                        extendId = v;
                        extendTouched = true;
                      }),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Extend is not available for this node.',
                          style: TextStyle(fontSize: 12, color: Color(0xff64748B))),
                    ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: interval,
                    isExpanded: true,
                    decoration: deco('Interval', Icons.timer_outlined),
                    items: [for (final e in intervalItems) DropdownMenuItem<int>(value: e, child: Text('$e Sec'))],
                    onChanged: (v) => setLocal(() => interval = v ?? interval),
                  ),
                  sectionLabel('Device ID'),
                  if (canEditDeviceId) ...[
                    TextFormField(
                      controller: idController,
                      decoration: deco('Device ID', Icons.developer_board_rounded),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final v = idController.text.trim();
                          if (v.isEmpty || v == node.deviceId) return;
                          Navigator.pop(ctx, _NodeEditAction.replaceId);
                        },
                        icon: const Icon(Icons.find_replace_rounded, size: 16),
                        label: const Text('Replace ID'),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SelectableText(node.deviceId,
                          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5, color: primary)),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx, _NodeEditAction.replaceFromStock),
                        icon: const Icon(Icons.find_replace_rounded, size: 16),
                        label: const Text('Replace device'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(ctx, _NodeEditAction.delete),
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete node'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, _NodeEditAction.cancel),
              child: const Text('Cancel', style: TextStyle(color: Color(0xff475467))),
            ),
            CustomMaterialButton(
              title: 'Save',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pop(ctx, _NodeEditAction.save),
            ),
          ],
        );
      },
    ),
  );

  final String newId = idController.text.trim();
  idController.dispose();

  if (action == null || action == _NodeEditAction.cancel) return;
  if (!context.mounted) return;

  switch (action) {
    case _NodeEditAction.save:
      node.interfaceInterval = interval;
      if (showExtend && extendTouched) node.extendControllerId = extendId;
      onChanged();
      break;

    case _NodeEditAction.delete:
      final String? blocker = nodeDeleteBlocker(configPvd, node);
      if (blocker != null) {
        simpleDialogBox(context: context, title: 'Alert', message: blocker);
        return;
      }
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete node?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Text('${node.deviceName} (${node.deviceId}) will be removed from this configuration.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        detachNodeFromMaster(configPvd, node);
        onChanged();
      }
      break;

    case _NodeEditAction.replaceId:
      await _replaceDeviceId(context, configPvd, node, newId, onChanged);
      break;

    case _NodeEditAction.replaceFromStock:
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Replace Node Device',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1E293B))),
          content: DropDownSearchField(productStock: configPvd.productStock, oldDevice: node.toJson(), masterOrNode: 2),
        ),
      );
      onChanged();
      break;

    case _NodeEditAction.cancel:
      break;
  }
}

// ─────────────────────────── device-id replacement flow ───────────────────────────

void _showLoading(BuildContext context) {
  showDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 3, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 18),
            const Text('Updating device configuration...', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ),
  );
}

Future<void> _replaceDeviceId(
    BuildContext context,
    ConfigMakerProvider p,
    DeviceModel node,
    String newId,
    VoidCallback onChanged,
    ) async {
  final nav = Navigator.of(context, rootNavigator: true);
  _showLoading(context);
  int status = 400;
  try {
    final response = await ConfigMakerRepository().checkProduct({'deviceId': newId});
    final Map<String, dynamic> json = jsonDecode(response.body);
    Map<String, dynamic> newDevice = {'deviceId': newId, 'modelId': null};

    if (response.statusCode == 200 && json['code'] == 200) {
      // the id already exists as a product – confirm with its registered owner first
      final data = json['data'][0];
      nav.pop(); // hide loader while asking
      if (!context.mounted) return;
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Device already registered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${json['message']}'),
              const SizedBox(height: 12),
              Text('Registered owner: ${data['userName']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Mobile: ${data['mobileNumber']}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Replace')),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      _showLoading(context);
      newDevice = {'deviceId': data['deviceId'], 'modelId': data['modelId']};
    }

    status = await p.replaceDevice(
      newDevice: newDevice,
      oldDevice: {'deviceId': node.deviceId, 'modelId': node.modelId, 'controllerId': node.controllerId},
      masterOrNode: 2,
    );
  } catch (e) {
    debugPrint('replace device id failed :: $e');
  }

  nav.pop(); // hide loader
  if (!context.mounted) return;
  simpleDialogBox(
    context: context,
    title: status == 200 ? 'Success' : 'Failed',
    message: status == 200 ? 'Product updated successfully..' : 'Product not updated..',
  );
  onChanged();
}