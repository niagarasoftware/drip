import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Screens/Map/oro_map/set_oro_device_location.dart';
import 'package:provider/provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../utils/snack_bar.dart';
import '../set_device_areator_location.dart';
import 'SetSelectAreatorLocation.dart';
import 'SetSelectValveOroLocation.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

import 'map_oro.dart';


class MapConnectionObject extends StatefulWidget {
  const MapConnectionObject({
    Key? key,
    required this.userId,
    required this.customerId,
    required this.controllerId,
    required this.imeiNo,
    required this.modelId,
  }) : super(key: key);

  final int userId, customerId, controllerId,modelId;
  final String imeiNo;

  @override
  State<MapConnectionObject> createState() => _MapConnectionObjectState();
}

class _MapConnectionObjectState extends State<MapConnectionObject> {
  bool _isSaving = false;

  @override
  void dispose() {
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    // Fetch data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchData());
  }

  Future<void> fetchData() async {
    final provider = Provider.of<MqttPayloadProvider>(context, listen: false);
    try {
      final Repository repository = Repository(HttpService());
      final response = await repository.getgeography({
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
      });

      if (response.statusCode == 200) {
        AppLog.log(response.body);
        final jsonData = jsonDecode(response.body);
        print("jsonData: $jsonData");
        provider.updateMapData(jsonData);
      }
    } catch (e) {
      provider.httpError = true;
      debugPrint('Error Fetching Data: $e');
    }
  }

  Future<void> updateMapLocation() async {
    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<MqttPayloadProvider>(context, listen: false);
      final Repository repository = Repository(HttpService());

      final data = provider.mapModelInstance.data?.toJson();
      print("send data : $data");
      print("send data : ${data!['deviceList']}");
      if (data == null) return;
       Map<String, dynamic> body = {
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
        "userGeography": data['deviceList'],
        "createUser": widget.userId
      };


      final response = await repository.creategeography(body);
      final jsonRes = jsonDecode(response.body);

      if (mounted) {
        GlobalSnackBar.show(context, jsonRes['message'] ?? "Success", 200);
      }
    } catch (e) {
      if (mounted) GlobalSnackBar.show(context, "Update failed", 400);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Device List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return  widget.modelId == 72 ?  MapScreendevice() : SetSelectOroDeviceLocation();
                })
            );
            },
          )
        ],
      ),
      body: Consumer<MqttPayloadProvider>(
        builder: (context, mqttProvider, _) {
          final deviceList = mqttProvider.mapModelInstance.data?.deviceList ?? [];

          if (deviceList.isEmpty) {
            return const Center(child: Text('No devices found.'));
          }

          return RefreshIndicator(
            onRefresh: fetchData,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: deviceList.length,
              itemBuilder: (context, index) {
                final device = deviceList[index];
                final lat = device.geography?.lat ?? '0.0';
                final lng = device.geography?.long ?? '0.0';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Image.asset('assets/png/map.png', height: 24),
                    ),
                    title: Text(
                      '${device.deviceName} (${device.connectedObject?.length ?? 0})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('ID: ${device.deviceId} • ${device.categoryName}'),
                        Text('Loc: $lat, $lng', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                         return widget.modelId == 72 ?  MapScreen(index: index) : SetSelectOroLocation(index: index);
                      }),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : updateMapLocation,
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.send),
      ),
    );
  }
}


