import 'package:flutter/material.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import '../view/connection.dart';
import '../view/utils/connection_colors.dart';

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
    final colors = ConnectionColors.of(context);

    // Reserved pin (D5 - Pulse Input) on category 6
    if (selectedDevice.categoryId == 6 && type == '4' && connectionNo == 5) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _reservedTile(colors),
          const SizedBox(height: 4),
          connector(
            object: object,
            selectedConnector: selectedConnector,
            context: context,
            colors: colors,
            name: name,
          ),
        ],
      );
    }
    return connector(
      object: object,
      selectedConnector: selectedConnector,
      context: context,
      colors: colors,
      name: name,
    );
  }

  Widget _reservedTile(ConnectionColors colors) {
    return Container(
      height: tileHeight,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.isLight ? Colors.grey.shade100 : Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.isLight ? Colors.grey.shade300 : Colors.white24),
      ),
      child: Row(
        children: [
          _pinBadge('D5', Colors.grey.shade500, true, colors),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Pulse (reserved)',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.lock_outline_rounded, size: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _pinBadge(String label, Color bg, bool filled, ConnectionColors colors) {
    final darkBg = const Color(0xFF12162B);
    final lightBg = Colors.white;
    return Container(
      constraints: const BoxConstraints(minWidth: 38),
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: filled
            ? LinearGradient(
                colors: [
                  Color.alphaBlend(bg.withValues(alpha: colors.isLight ? 0.22 : 0.35), colors.isLight ? lightBg : darkBg),
                  Color.alphaBlend(bg.withValues(alpha: colors.isLight ? 0.08 : 0.12), colors.isLight ? lightBg : darkBg),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: colors.isLight
                    ? [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)]
                    : [const Color(0xFF283154), const Color(0xFF1E2542)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: filled
              ? bg
              : (colors.isLight ? const Color(0xFFCBD5E1) : const Color(0xFF283154)),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: filled ? bg : colors.textMuted,
          fontWeight: FontWeight.bold,
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
    required ConnectionColors colors,
    required String? name,
  }) {
    const primary = Color(0xFF7C3AED);
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
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selectedConnector
              ? colors.pinSelectedBg
              : assigned
              ? colors.pinAssignedBg
              : colors.pinUnassignedBg,
          border: Border.all(
            color: selectedConnector
                ? colors.pinSelectedBorder
                : assigned
                ? colors.pinAssignedBorder
                : colors.pinUnassignedBorder,
            width: selectedConnector ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            _pinBadge(
              getSuitableKeyWord(),
              color,
              assigned,
              colors,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                assigned ? name.toString() : 'Empty',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: assigned ? FontWeight.bold : FontWeight.w500,
                  fontStyle: assigned ? FontStyle.normal : FontStyle.italic,
                  color: assigned ? colors.pinAssignedText : colors.pinUnassignedText,
                ),
              ),
            ),
            if (selectedConnector)
              const Padding(
                padding: EdgeInsets.only(right: 4),
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