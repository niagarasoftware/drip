import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../../../Constants/communication_codes.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/product_limit_grid_list_tile.dart';

class ProductLimit extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  final List<DeviceModel> listOfDevices;

  const ProductLimit({
    super.key,
    required this.listOfDevices,
    required this.configPvd,
  });

  @override
  State<ProductLimit> createState() => _ProductLimitState();
}

class _ProductLimitState extends State<ProductLimit> {
  String selectedCategoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCapacitySummary(screenWidth),
          const SizedBox(height: 12),
          _buildCategoryFilterBar(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_shouldShowSection('Common') &&
                      !AppConstants.pumpWithValveModelList.contains(widget.configPvd.masterData['modelId']) &&
                      !AppConstants.weatherGsmModelList.contains(widget.configPvd.masterData['modelId']))
                    commonObject(),
                  if (_shouldShowSection('Output'))
                    outputObject(),
                  if (_shouldShowSection('Analog') && getInputCount(3, widget.listOfDevices) != 0)
                    analogObject(),
                  if (_shouldShowSection('Digital') && getInputCount(4, widget.listOfDevices) != 0)
                    digitalObject(),
                  if (_shouldShowSection('Moisture') && getInputCount(5, widget.listOfDevices) != 0)
                    moistureObject(),
                  if (_shouldShowSection('Pulse') && getInputCount(6, widget.listOfDevices) != 0)
                    pulseObject(),
                  if (_shouldShowSection('I2C') && getInputCount(7, widget.listOfDevices) != 0)
                    i2cObject(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowSection(String category) {
    if (selectedCategoryFilter != 'All' && selectedCategoryFilter != category) {
      return false;
    }
    return true;
  }

  Widget _buildCapacitySummary(double screenWidth) {
    final relayTotal = getRelayLatchCount(widget.listOfDevices);
    final relayBalance = balanceCountForRelayLatch(widget.configPvd);
    final relayUsed = relayTotal - relayBalance;

    final categories = <Map<String, dynamic>>[];

    if (relayTotal > 0) {
      categories.add({
        'title': 'Outputs (Relay/Latch)',
        'used': relayUsed,
        'total': relayTotal,
        'color': AppConstants.outputColor,
      });
    }

    final inputCodes = [
      {'code': 3, 'name': 'Analog Input'},
      {'code': 4, 'name': 'Digital Input'},
      {'code': 5, 'name': 'Moisture Input'},
      {'code': 6, 'name': 'Pulse Input'},
      {'code': 7, 'name': 'I2C Input'},
    ];

    for (var item in inputCodes) {
      final code = item['code'] as int;
      final total = getInputCount(code, widget.listOfDevices);
      if (total > 0) {
        final balance = balanceCountForInputType(code, widget.configPvd);
        final used = total - balance;
        categories.add({
          'title': item['name'],
          'used': used,
          'total': total,
          'color': getObjectTypeCodeToColor(code),
        });
      }
    }

    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.memory_rounded, size: 18, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 10),
              const Text(
                'Hardware Capacity & I/O Allocation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: categories.map((cat) {
              final color = cat['color'] as Color;
              final used = cat['used'] as int;
              final total = cat['total'] as int;
              final ratio = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
              final isFull = used >= total && total > 0;

              return Container(
                width: screenWidth > 700 ? 200 : (screenWidth > 450 ? 170 : double.infinity),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${cat['title']}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff475467),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isFull ? Colors.red.shade50 : color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$used/$total',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isFull ? Colors.red.shade700 : color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 4,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(isFull ? Colors.red.shade600 : color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterBar() {
    final categories = ['All', 'Common', 'Output', 'Analog', 'Digital', 'Moisture', 'Pulse', 'I2C'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final selected = selectedCategoryFilter == cat;
          final primaryColor = Theme.of(context).primaryColor;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: selected,
              onSelected: (isSelected) {
                if (isSelected) {
                  setState(() {
                    selectedCategoryFilter = cat;
                  });
                }
              },
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xff475467),
              ),
              selectedColor: primaryColor,
              backgroundColor: Colors.white,
              elevation: selected ? 1 : 0,
              side: BorderSide(
                color: selected ? primaryColor : Colors.grey.shade300,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              visualDensity: VisualDensity.compact,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget commonObject() {
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel
        .where((object) => (widget.configPvd.masterData['categoryId'] != 2 ? object.type == '-' : object.objectId == 1))
        .toList();

    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'Common Objects',
      leadingColor: AppConstants.commonObjectColor,
      configPvd: widget.configPvd,
    );
  }

  Widget outputObject() {
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel.where((object) {
      return (object.type == '1,2' && widget.configPvd.getPossibleConnectingObjectId().contains(object.objectId));
    }).toList();

    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'Output Objects (Relay/Latch)',
      leadingColor: AppConstants.outputColor,
      configPvd: widget.configPvd,
    );
  }

  Widget analogObject() {
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel
        .where((object) => (object.type == '3' && widget.configPvd.getPossibleConnectingObjectId().contains(object.objectId)))
        .toList();

    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'Analog Inputs',
      configPvd: widget.configPvd,
    );
  }

  Widget digitalObject() {
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel.where((object) {
      return (object.type == '4' && widget.configPvd.getPossibleConnectingObjectId().contains(object.objectId));
    }).toList();

    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'Digital Inputs',
      configPvd: widget.configPvd,
    );
  }

  Widget moistureObject() {
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel
        .where((object) => object.objectId == AppConstants.moistureObjectId)
        .toList();

    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'Moisture Inputs',
      configPvd: widget.configPvd,
    );
  }

  Widget pulseObject() {
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel
        .where((object) => (object.type == '6' && widget.configPvd.getPossibleConnectingObjectId().contains(object.objectId)))
        .toList();

    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'Pulse Inputs',
      configPvd: widget.configPvd,
    );
  }

  Widget i2cObject() {
    List<DeviceObjectModel> filteredList = widget.configPvd.listOfSampleObjectModel
        .where((object) => (object.type == '7' && widget.configPvd.getPossibleConnectingObjectId().contains(object.objectId)))
        .toList();

    return ProductLimitGridListTile(
      listOfObjectModel: filteredList,
      title: 'I2C Inputs',
      configPvd: widget.configPvd,
    );
  }
}

int getRelayLatchCount(List<DeviceModel> listOfDevices) {
  int count = 0;
  for (var node in listOfDevices) {
    if (node.masterId != null) {
      count += node.noOfRelay;
      count += node.noOfLatch;
    }
  }
  return count;
}

int balanceCountForRelayLatch(ConfigMakerProvider configPvd) {
  int totalCount = getRelayLatchCount(configPvd.listOfDeviceModel);
  for (var object in configPvd.listOfSampleObjectModel) {
    if (object.type == '1,2') {
      int objectCount = [null, ''].contains(object.count) ? 0 : int.parse(object.count!);
      totalCount -= object.objectId == AppConstants.pumpObjectId && AppConstants.ecoGemModelList.contains(configPvd.masterData['modelId']) ? 0 : objectCount;
    }
  }
  return totalCount;
}

int getInputCount(int code, List<DeviceModel> listOfDevices) {
  int count = 0;
  for (var node in listOfDevices) {
    if (node.masterId != null) {
      if (code == 3) {
        count += node.noOfAnalogInput;
      } else if (code == 4) {
        count += node.noOfDigitalInput;
      } else if (code == 5) {
        count += node.noOfMoistureInput;
      } else if (code == 6) {
        count += node.noOfPulseInput;
      } else {
        count += node.noOfI2CInput;
      }
    }
  }
  return count;
}

int balanceCountForInputType(int code, ConfigMakerProvider configPvd) {
  int totalCount = getInputCount(code, configPvd.listOfDeviceModel);
  for (var object in configPvd.listOfSampleObjectModel) {
    if (object.type == '$code' && object.objectId != AppConstants.powerSupplyObjectId) {
      int objectCount = [null, ''].contains(object.count) ? 0 : int.parse(object.count!);
      totalCount -= objectCount;
    }
  }
  return totalCount;
}