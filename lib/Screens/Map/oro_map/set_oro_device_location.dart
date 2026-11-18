import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../modules/config_maker/view/device_list.dart' hide DeviceList;
import '../MapAreaModel.dart' hide Area;
import '../googlemap_model.dart';
import 'getlatlong.dart';

 

class SetSelectOroDeviceLocation extends StatefulWidget {
  const SetSelectOroDeviceLocation({Key? key}) : super(key: key);

  @override
  _SetSelectOroDeviceLocationState createState() => _SetSelectOroDeviceLocationState();
}


class _SetSelectOroDeviceLocationState extends State<SetSelectOroDeviceLocation> {

  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  LatLng? _selectedPosition;
  DeviceList? _selectedDevice;
  int _selectedDeviceIndex = 0;
  double _currentZoom = 15;


  late MqttPayloadProvider mqttPayloadProvider;

  bool _isDrawerOpen = false;
  double _drawerWidth = 280;

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelectedDevice();
      _addAllDeviceMarkers();
    });
  }

  void _initializeSelectedDevice() {
    final devices = mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];
    if (devices.isNotEmpty) {
      // Select first device with valid lat/long
      for (int i = 0; i < devices.length; i++) {
        final dev = devices[i];
        if (dev.geography?.lat != null && dev.geography?.long != null) {
          _selectedDevice = dev;
          _selectedDeviceIndex = i;
          _selectedPosition = LatLng(dev.geography!.lat!, dev.geography!.long!);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedPosition!, 12),
          );
          break;
        }
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_selectedPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedPosition!, 12),
      );
    }
  }

  void _addAllDeviceMarkers() {
    final devices = mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];
    Set<Marker> markers = {};

    for (var device in devices) {
      if (device.geography?.lat != null && device.geography?.long != null) {
        final position = LatLng(device.geography!.lat!, device.geography!.long!);
        final isSelected = device.deviceId == _selectedDevice?.deviceId;

        markers.add(
          Marker(
            markerId: MarkerId(device.deviceId ?? device.controllerId.toString()),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isSelected
                  ? BitmapDescriptor.hueAzure
                  : device.geography!.status == 1
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: device.deviceName ?? 'Device',
              snippet: 'Lat: ${device.geography!.lat}, Long: ${device.geography!.long}',
              onTap: () {
                setState(() {
                  _selectedDevice = device;
                  _selectedPosition = position;
                  _selectedDeviceIndex = devices.indexOf(device);
                });
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, _currentZoom));
              },
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _updateMarker(double lat, double long) {
    final deviceList = mqttPayloadProvider.mapModelInstance.data?.deviceList;
    if (deviceList == null || _selectedDeviceIndex < 0 || _selectedDeviceIndex >= deviceList.length) return;

    final position = LatLng(lat, long);

    setState(() {
      deviceList[_selectedDeviceIndex].geography ??= Geography();
      deviceList[_selectedDeviceIndex].geography!.lat = lat;
      deviceList[_selectedDeviceIndex].geography!.long = long;

      _selectedDevice = deviceList[_selectedDeviceIndex];
      _selectedPosition = position;
    });

    mqttPayloadProvider.notifyListeners();
    _addAllDeviceMarkers();
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, _currentZoom));
  }

  void _searchLocation() async {
    final input = _searchController.text;
    final LatLng? result = await getLatLngFromInput(input);

    if (result != null) {
      _updateMarker(result.latitude, result.longitude);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid area name, map link or lat,long"),
        ),
      );
    }
  }

  LatLng _getInitialCameraPosition() {
    if (_selectedDevice?.geography?.lat != null && _selectedDevice?.geography?.long != null) {
      return LatLng(_selectedDevice!.geography!.lat!, _selectedDevice!.geography!.long!);
    }

    final devices = mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];
    for (var dev in devices) {
      if (dev.geography?.lat != null && dev.geography?.long != null) {
        return LatLng(dev.geography!.lat!, dev.geography!.long!);
      }
    }

    // fallback
    return const LatLng(11.5937, 78.9629);
  }

  @override
  Widget build(BuildContext context) {
    final devices = mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Device Locations'),
        leadingWidth: 110,
        leading: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                });
              },
            ),
            IconButton(
              icon: Icon(_isDrawerOpen ? Icons.close : Icons.menu),
              onPressed: () {
                setState(() {
                  _isDrawerOpen = !_isDrawerOpen;
                });
              },
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          // Side Drawer
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isDrawerOpen ? _drawerWidth : 0,
            color: Colors.white,
            child: _isDrawerOpen
                ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  color: Colors.teal.shade500,
                  child: const Text(
                    "Devices",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                Expanded(
                  child: devices.isEmpty
                      ? const Center(child: Text("No Devices"))
                      : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return ListTile(
                        selected: device.deviceId == _selectedDevice?.deviceId,
                        selectedTileColor: Colors.blue.withOpacity(0.2),
                        title: Text(device.deviceName ?? "Device"),
                        subtitle: Text(
                            "Lat: ${device.geography?.lat ?? '-'}, Long: ${device.geography?.long ?? '-'}\nStatus: ${device.geography?.status ?? 'Unknown'}"),
                        onTap: () {
                          final position = device.geography?.lat != null &&
                              device.geography?.long != null
                              ? LatLng(device.geography!.lat!, device.geography!.long!)
                              : _getInitialCameraPosition();

                          setState(() {
                            _selectedDevice = device;
                            _selectedDeviceIndex = index;
                            _selectedPosition = position;
                          });

                          _addAllDeviceMarkers();

                          _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(position, 12));
                        },
                      );
                    },
                  ),
                ),
              ],
            )
                : null,
          ),

          // Map Area
          Expanded(
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search Area (lat,long or name)',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) => _searchLocation(),
                        ),
                      ),
                      TextButton(
                        onPressed: _searchLocation,
                        child: const Text('Search', style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                ),

                // Map
                Expanded(
                  child: GoogleMap(
                    mapType: MapType.hybrid,
                    onMapCreated: _onMapCreated,
                    onCameraMove: (CameraPosition position) {
                      _currentZoom = position.zoom;
                    },
                    initialCameraPosition:
                    CameraPosition(target: _getInitialCameraPosition(), zoom: _currentZoom),
                    markers: _markers,
                    onTap: (LatLng latLng) => _updateMarker(latLng.latitude, latLng.longitude),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}