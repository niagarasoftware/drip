import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Widgets/sized_image.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../view/connection.dart';
import '../state_management/config_maker_provider.dart';
import '../../../utils/constants.dart';

/// Compact single-pin tile: [badge] — name  [icon]
class ConnectorWidget extends StatelessWidget {
  final ConfigMakerProvider configPvd;
  final String type;
  final int connectionNo;
  final String keyWord;
  final DeviceModel selectedDevice;
  final Color color;
  const ConnectorWidget({
    super.key,
    required this.connectionNo,
    required this.selectedDevice,
    required this.configPvd,
    required this.type,
    required this.keyWord,
    required this.color,
  });

  static const double tileHeight = 30;

  @override
  Widget build(BuildContext context) {
    DeviceObjectModel? object = configPvd.listOfGeneratedObject.cast<DeviceObjectModel?>().firstWhere(
          (object) =>
      object?.controllerId == selectedDevice.controllerId &&
          object?.connectionNo == connectionNo &&
          object?.type == type,
      orElse: () => null as DeviceObjectModel?,
    );
    String? name = object?.name;
    bool selectedConnector = (configPvd.selectedModelControllerId == selectedDevice.controllerId &&
        configPvd.selectedType == type &&
        configPvd.selectedConnectionNo == connectionNo);
    bool isLight = Theme.of(context).brightness == Brightness.light;

    // Reserved pin (D5 - Pulse Input) on category 6
    if (selectedDevice.categoryId == 6 && type == '4' && connectionNo == 5) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _reservedTile(isLight),
          const SizedBox(height: 4),
          connector(
            object: object,
            selectedConnector: selectedConnector,
            context: context,
            themeMode: isLight,
            name: name,
          ),
        ],
      );
    }
    return connector(
      object: object,
      selectedConnector: selectedConnector,
      context: context,
      themeMode: isLight,
      name: name,
    );
  }

  Widget _reservedTile(bool isLight) {
    return Container(
      height: tileHeight,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isLight ? Colors.grey.shade100 : Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _pinBadge('D5', Colors.grey.shade500, true),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Pulse (reserved)',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.lock_outline_rounded, size: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _pinBadge(String label, Color bg, bool filled) {
    return Container(
      constraints: const BoxConstraints(minWidth: 38),
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : Colors.grey.shade700,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget connector({
    required DeviceObjectModel? object,
    required bool selectedConnector,
    required BuildContext context,
    required bool themeMode,
    required String? name,
  }) {
    final primary = Theme.of(context).primaryColor;
    final bool assigned = object != null;
    final bool isAuto = configPvd.selectedSelectionMode == SelectionMode.auto;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onDoubleTap: isAuto
          ? null
          : () {
        if (object != null) {
          configPvd.removeSingleObjectFromConfigureToNotConfigure(object);
        }
      },
      onTap: isAuto
          ? null
          : () {
        configPvd.updateSelectedConnectionNoAndItsType(connectionNo, type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: tileHeight,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selectedConnector
              ? primary.withOpacity(0.10)
              : assigned
              ? color.withOpacity(0.07)
              : (themeMode ? Colors.grey.shade50 : Colors.white10),
          border: Border.all(
            color: selectedConnector
                ? primary
                : assigned
                ? color.withOpacity(0.35)
                : Colors.grey.shade300,
            width: selectedConnector ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            _pinBadge(
              getSuitableKeyWord(),
              assigned ? color : Colors.grey.shade200,
              assigned,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                assigned ? name.toString() : 'Empty',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: assigned ? FontWeight.w700 : FontWeight.w500,
                  fontStyle: assigned ? FontStyle.normal : FontStyle.italic,
                  color: assigned ? const Color(0xff0F172A) : Colors.grey.shade500,
                ),
              ),
            ),
            if (assigned)
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 2),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: SizedImageSmall(imagePath: '${AppConstants.svgObjectPath}objectId_${object.objectId}.svg'),
              )
            else if (selectedConnector)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.touch_app_rounded, size: 14, color: primary),
              ),
          ],
        ),
      ),
    );
  }

  String getSuitableKeyWord() {
    String specificSensor = '';
    if (connectionNo == 5 && selectedDevice.categoryId == 6 && selectedDevice.modelId == 3 && type == '3') {
      specificSensor = '(Ph)';
    } else if (connectionNo == 6 && selectedDevice.categoryId == 6 && selectedDevice.modelId == 3 && type == '3') {
      specificSensor = '(Ph)';
    } else if (connectionNo == 7 && selectedDevice.categoryId == 6 && selectedDevice.modelId == 3 && type == '3') {
      specificSensor = '(Ec)';
    } else if (connectionNo == 8 && selectedDevice.categoryId == 6 && selectedDevice.modelId == 3 && type == '3') {
      specificSensor = '(Ec)';
    } else if (connectionNo == 9 && selectedDevice.categoryId == 6 && type == '3') {
      specificSensor = '(ps)';
    }
    String editConnectionNo = '$connectionNo';
    if (connectionNo == 9 && selectedDevice.categoryId == 6 && type == '3') {
      editConnectionNo = '';
    }
    if (connectionNo == 5 && selectedDevice.categoryId == 6 && type == '4') {
      editConnectionNo = '6';
    }
    return '$keyWord$editConnectionNo$specificSensor';
  }
}