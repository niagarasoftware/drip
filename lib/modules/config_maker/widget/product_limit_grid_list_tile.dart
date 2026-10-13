import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Widgets/sized_image.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/toggle_text_form_field_product_limit.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/communication_codes.dart';
import '../model/device_object_model.dart';
import '../view/product_limit.dart';
import '../state_management/config_maker_provider.dart';
import '../../../utils/constants.dart';
import 'blinking_container.dart';

class ProductLimitGridListTile extends StatefulWidget {
  final List<DeviceObjectModel> listOfObjectModel;
  final ConfigMakerProvider configPvd;
  final String title;
  final Color? leadingColor;

  const ProductLimitGridListTile({
    super.key,
    required this.listOfObjectModel,
    required this.title,
    required this.configPvd,
    this.leadingColor,
  });

  @override
  State<ProductLimitGridListTile> createState() => _ProductLimitGridListTileState();
}

class _ProductLimitGridListTileState extends State<ProductLimitGridListTile> with SingleTickerProviderStateMixin {
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
    final visibleObjects = widget.listOfObjectModel.where((object) {
      final isTypeAllowed = ['-', '1,2'].contains(object.type) ||
          getInputCount(int.parse(object.type), widget.configPvd.listOfDeviceModel) != 0;
      return isTypeAllowed && dependentObjectByCommonObject(object.objectId);
    }).toList();

    if (visibleObjects.isEmpty) {
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
                  color: Color(0xff1E293B),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${visibleObjects.length}',
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
            for (var object in visibleObjects)
              objectTile(object),
          ],
        ),
      ],
    );
  }

  Widget objectTile(DeviceObjectModel object) {
    Color typeColor = widget.leadingColor ?? getObjectTypeCodeToColor(int.parse(object.type));
    int configuredCount = getConfiguredObjectByObjectId(object.objectId);
    bool hasConfigured = configuredCount > 0;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: typeColor.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: typeColor,
              boxShadow: [
                BoxShadow(
                  color: typeColor.withOpacity(0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(9),
            child: SizedImage(
              imagePath: '${AppConstants.svgObjectPath}objectId_${object.objectId}.svg',
              color: Colors.white,
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
                    color: Color(0xff0F172A),
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasConfigured ? const Color(0xffDCFCE7) : const Color(0xffF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: hasConfigured ? const Color(0xffBBF7D0) : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasConfigured) ...[
                        const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xff15803D)),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        'Configured: $configuredCount',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: hasConfigured ? const Color(0xff15803D) : const Color(0xff64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ToggleTextFormFieldForProductLimit(
            leadingColor: typeColor,
            configPvd: widget.configPvd,
            initialValue: object.count.toString(),
            object: object,
          ),
        ],
      ),
    );

    if (widget.configPvd.noticeableObjectId.contains(object.objectId)) {
      return BlinkingContainer(child: cardContent);
    } else {
      return cardContent;
    }
  }

  int getConfiguredObjectByObjectId(int objectId) {
    List<DeviceObjectModel> configured = widget.configPvd.listOfGeneratedObject
        .where((object) => (object.objectId == objectId && object.controllerId != null))
        .toList();
    return configured.length;
  }

  bool dependentObjectByCommonObject(int objectId) {
    bool visible = true;
    /*hide waterSource for pump with valve model*/
    if (AppConstants.pumpWithValveModelList.contains(widget.configPvd.masterData['modelId'])) {
      if (kDebugMode) {
        print('master ::: pump with valve model');
      }
    } else if (AppConstants.ecoGemModelList.contains(widget.configPvd.masterData['modelId']) &&
        !AppConstants.ecoGemFlowControlValveModel.contains(widget.configPvd.masterData['modelId'])) {
      if (kDebugMode) {
        print('master ::: eco gem');
      }
      List<int> objectThatConfigureToEcoGemModel = [1, 2, 3, 4, 5, 7, 9, 10, 11, 13, 22, 24, 25, 26, 30, 40];
      if (objectThatConfigureToEcoGemModel.contains(objectId)) {
        visible = true;
      } else {
        visible = false;
      }
    } else if (AppConstants.aquacultureModelList.contains(widget.configPvd.masterData['modelId'])) {
      if (kDebugMode) {
        print('master ::: BCH gem');
      }
      List<int> objectThatConfigureToBchModel = [1, 2, 5, 40];
      if (objectThatConfigureToBchModel.contains(objectId)) {
        visible = true;
      } else {
        visible = false;
      }
    } else {
      if (kDebugMode) {
        print('master ::: gem');
      }
      if (objectIdDependsOnDosing.contains(objectId)) {
        //filter object by dosing site
        DeviceObjectModel dosingObject = widget.configPvd.listOfSampleObjectModel.firstWhere((object) => object.objectId == 3);
        if (dosingObject.count == '0') {
          visible = false;
        }
      } else if (objectIdDependsOnFiltration.contains(objectId)) {
        DeviceObjectModel filtrationObject = widget.configPvd.listOfSampleObjectModel.firstWhere((object) => object.objectId == 4);
        if (filtrationObject.count == '0') {
          visible = false;
        }
      } else if (objectIdDependsOnTank.contains(objectId)) {
        DeviceObjectModel tankObject = widget.configPvd.listOfSampleObjectModel.firstWhere((object) => object.objectId == 1);
        if (tankObject.count == '0') {
          visible = false;
        }
      } else if ([31, 32, 34, 35, 37, 38].contains(objectId)) {
        bool weatherDeviceAvailable = widget.configPvd.listOfDeviceModel.any((device) => device.categoryId == 4);
        if (!weatherDeviceAvailable) {
          visible = false;
        }
      }
    }

    if (kDebugMode) {
      print('objectId ($objectId) - $visible');
    }

    return visible;
  }
}

List<int> objectIdDependsOnDosing = [7, 8, 10, 27, 28];
List<int> objectIdDependsOnFiltration = [11, 12];
List<int> objectIdDependsOnTank = [5, 26, 40];