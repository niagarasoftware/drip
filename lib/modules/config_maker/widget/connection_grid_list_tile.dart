import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Widgets/sized_image.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/toggle_text_form_field_connection.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/communication_codes.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../utils/constants.dart';

class ConnectionGridListTile extends StatefulWidget {
  final List<DeviceObjectModel> listOfObjectModel;
  final ConfigMakerProvider configPvd;
  final String title;
  final Color? leadingColor;
  final DeviceModel selectedDevice;

  const ConnectionGridListTile({
    super.key,
    required this.listOfObjectModel,
    required this.title,
    required this.configPvd,
    required this.selectedDevice,
    this.leadingColor,
  });

  @override
  State<ConnectionGridListTile> createState() => _ConnectionGridListTileState();
}

class _ConnectionGridListTileState extends State<ConnectionGridListTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _startBlinking();
  }

  void _startBlinking() async {
    for (int i = 0; i < 2; i++) {
      await _controller.forward();
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.listOfObjectModel.isEmpty) {
      return const SizedBox.shrink();
    }

    Color typeColor = widget.leadingColor ??
        (widget.listOfObjectModel.isNotEmpty && widget.listOfObjectModel.first.type != '-'
            ? getObjectTypeCodeToColor(int.parse(widget.listOfObjectModel.first.type))
            : Theme.of(context).primaryColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.listOfObjectModel.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ResponsiveGridList(
          horizontalGridMargin: 4,
          verticalGridMargin: 6,
          minItemWidth: 280,
          shrinkWrap: true,
          listViewBuilderOptions: ListViewBuilderOptions(
            physics: const NeverScrollableScrollPhysics(),
          ),
          children: [
            for (var object in widget.listOfObjectModel)
              objectTile(object),
          ],
        ),
      ],
    );
  }

  Widget objectTile(DeviceObjectModel object) {
    Color typeColor = widget.leadingColor ?? getObjectTypeCodeToColor(int.parse(object.type));
    int notConfiguredCount = getNotConfiguredObjectByObjectId(object.objectId, widget.configPvd);

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181C38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2A3258),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A2035),
              border: Border.all(color: typeColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: typeColor.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(9),
            child: SizedImage(
              imagePath: '${AppConstants.svgObjectPath}objectId_${object.objectId}.svg',
              color: typeColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  object.objectName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12162B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2A3258)),
                  ),
                  child: Text(
                    'Unassigned: $notConfiguredCount',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8E9BB4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          (widget.selectedDevice.categoryId == 4 && object.objectId != 25)
              ? Checkbox(
                  value: isConnectedToWeather(object),
                  activeColor: typeColor,
                  onChanged: (value) {
                    widget.configPvd.updateObjectConnection(object, value! ? 1 : 0);
                  },
                )
              : (widget.selectedDevice.categoryId == 6 &&
                      object.objectId == AppConstants.powerSupplyObjectId)
                  ? Checkbox(
                      value: powerSupplyConnectedToCategory_6(),
                      activeColor: typeColor,
                      onChanged: (value) {
                        widget.configPvd
                            .updateObjectConnectionForPowerSupply(object, value!);
                      },
                    )
                  : ToggleTextFormFieldForConnection(
                      configPvd: widget.configPvd,
                      initialValue: object.count.toString(),
                      object: object,
                      selectedDevice: widget.selectedDevice,
                    ),
        ],
      ),
    );

    return cardContent;
  }

  bool powerSupplyConnectedToCategory_6() {
    return widget.configPvd.listOfGeneratedObject.any((object) {
      return object.objectId == AppConstants.powerSupplyObjectId &&
          object.controllerId == widget.selectedDevice.controllerId;
    });
  }

  bool isConnectedToWeather(DeviceObjectModel object) {
    return widget.configPvd.listOfGeneratedObject.any((generatedObject) =>
        (generatedObject.objectId == object.objectId &&
            generatedObject.controllerId == widget.selectedDevice.controllerId));
  }
}

int getNotConfiguredObjectByObjectId(int objectId, ConfigMakerProvider configPvd) {
  List<DeviceObjectModel> notConfigured = configPvd.listOfGeneratedObject
      .where((object) => (object.objectId == objectId && object.controllerId == null))
      .toList();
  return notConfigured.length;
}