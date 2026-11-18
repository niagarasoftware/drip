import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../StateManagement/mqtt_payload_provider.dart';
import 'googlemap_model.dart';
import 'oro_map/getlatlong.dart';

class MapScreendevice extends StatefulWidget {
  const MapScreendevice({Key? key}) : super(key: key);

  @override
  _MapScreendeviceState createState() => _MapScreendeviceState();
}

class _MapScreendeviceState extends State<MapScreendevice> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  Set<Marker> _markers = {};
  Set<Marker> _vertices = {};
  Set<Polyline> _lines = {};
  Set<Polygon> _polygons = {};

  LatLng? _selectedPosition;
  DeviceList? _selectedDevice;
  int _selectedDeviceIndex = 0;

  late MqttPayloadProvider mqttPayloadProvider;

  bool _isDrawerOpen = false;
  double _drawerWidth = 280;
  double _currentZoom = 15;

  // 🔥 AREA MODE
   bool _isClosed = false;
  List<LatLng> _areaPoints = [];
  List<List<LatLng>> _undoStack = [];
  List<List<LatLng>> _redoStack = [];


  @override
  void initState() {
    super.initState();
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelectedDevice();
      _addAllDeviceMarkers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------- INIT ----------------

  void _initializeSelectedDevice() {
    final devices =
        mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];

    for (int i = 0; i < devices.length; i++) {
      final dev = devices[i];
      if (dev.geography?.lat != null &&
          dev.geography?.long != null) {
        _selectedDevice = dev;
        _selectedDeviceIndex = i;
        _selectedPosition =
            LatLng(dev.geography!.lat!, dev.geography!.long!);
        break;
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (_selectedPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedPosition!, _currentZoom),
      );
    }
  }

  // ---------------- MARKER MODE ----------------

  void _updateMarker(double lat, double long) {
    final deviceList =
        mqttPayloadProvider.mapModelInstance.data?.deviceList;

    if (deviceList == null) return;

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

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, _currentZoom),
    );
  }

  void _addAllDeviceMarkers() {
    final devices =
        mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];

    Set<Marker> markers = {};

    for (var device in devices) {
      if (device.geography?.lat != null &&
          device.geography?.long != null) {
        final pos = LatLng(
            device.geography!.lat!, device.geography!.long!);

        final isSelected =
            device.deviceId == _selectedDevice?.deviceId;

        markers.add(
          Marker(
            markerId: MarkerId(device.deviceId ??
                device.controllerId.toString()),
            position: pos,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isSelected
                  ? BitmapDescriptor.hueAzure
                  : device.geography!.status == 1
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
            onTap: () {
              setState(() {
                _selectedDevice = device;
                _selectedPosition = pos;
                _selectedDeviceIndex =
                    devices.indexOf(device);
              });

              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(pos, _currentZoom),
              );
            },
          ),
        );
      }
    }

    setState(() => _markers = markers);
  }

  // ---------------- AREA MODE ----------------

  void _addAreaPoint(LatLng point) {
    if (_isClosed) return;

    setState(() {
      _areaPoints.add(point);
    });

    _drawArea();
  }

  void _drawArea() {
    _vertices.clear();
    _lines.clear();
    // _polygons.clear();

    for (int i = 0; i < _areaPoints.length; i++) {
      _vertices.add(
        Marker(
          markerId: MarkerId("point_$i"),
          position: _areaPoints[i],
          draggable: true, // ✅ IMPORTANT

          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueAzure,
          ),

          onTap: () {
            if (i == 0 && _areaPoints.length >= 3) {
              _closePolygon();
            }
          },

          // ✅ HANDLE DRAG
          onDragEnd: (newPosition) {
            _saveState(); // undo support

            setState(() {
              _areaPoints[i] = newPosition;
            });

            _drawArea();
            _saveAreaToDevice();
          },
        ),
      );
    }

    List<LatLng> path = List.from(_areaPoints);

    if (_isClosed) path.add(_areaPoints.first);

    _lines.add(
      Polyline(
        polylineId: const PolylineId("line"),
        points: path,
        color: Colors.yellow,
        width: 3,
      ),
    );

    if (_isClosed && _areaPoints.length >= 3) {
      _polygons.add(
        Polygon(
          polygonId: const PolygonId("area"),
          points: _areaPoints,
          fillColor: Colors.blue.withOpacity(0.3),
          strokeWidth: 0,
        ),
      );
    }

    setState(() {});
  }

  void _closePolygon() {
    if (_areaPoints.length < 3) return;

    setState(() {
      _isClosed = true;
    });

    _saveAreaToDevice();
    _drawArea();
  }

  void _saveAreaToDevice() {
    final deviceList =
        mqttPayloadProvider.mapModelInstance.data?.deviceList;

    if (deviceList == null) return;

    deviceList[_selectedDeviceIndex].geography ??= Geography();

    deviceList[_selectedDeviceIndex].geography!.area =
        _areaPoints
            .map((p) => Area(
            latitude: p.latitude,
            longitude: p.longitude))
            .toList();

    mqttPayloadProvider.notifyListeners();
  }

  // ---------------- SEARCH ----------------

  void _searchLocation() async {
    final input = _searchController.text;
    final LatLng? result = await getLatLngFromInput(input);

    if (result != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(result, _currentZoom),
      );
    }
  }

  LatLng _getInitialCameraPosition() {
    final area = _selectedDevice?.geography?.area;

    if (area != null &&
        area.isNotEmpty &&
        area[0].latitude != null &&
        area[0].longitude != null) {
      return LatLng(
        area[0].latitude!,
        area[0].longitude!,
      );
    }

    return const LatLng(11.5937, 78.9629);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final devices =
        mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];

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
          // Drawer
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
                        selectedTileColor: Colors.red.withOpacity(0.2),
                        title: Text(device.deviceName ?? "Device"),
                        subtitle: Text(
                          (device.geography?.area != null &&
                              device.geography!.area!.isNotEmpty)
                              ? "Lat: ${device.geography!.area!.first.latitude}, Long: ${device.geography!.area!.first.longitude}\nStatus: ${device.geography?.status ?? 'Unknown'}"
                              : "Lat: -, Long: -\nStatus: ${device.geography?.status ?? 'Unknown'}",
                        ),
                        onTap: () {
                          final position = device.geography?.lat != null &&
                              device.geography?.long != null
                              ? LatLng(device.geography!.lat!, device.geography!.long!)
                              : _getInitialCameraPosition();

                          setState(() {
                            _selectedDevice = device;
                            _selectedDeviceIndex = index;
                            _selectedPosition = position;

                            // 🔥 LOAD EXISTING AREA
                            final area = device.geography?.area;

                            if (area != null && area.isNotEmpty) {
                              _areaPoints = area
                                  .map((e) => LatLng(e.latitude!, e.longitude!))
                                  .toList();

                              _isClosed = _areaPoints.length >= 3;
                            } else {
                              _areaPoints = [];
                              _isClosed = false;
                            }
                          });

                          _drawArea();

                          _addAllDeviceMarkers();

                          _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(position, _currentZoom));
                        },
                      );
                    },
                  ),
                ),
              ],
            )
                : null,
          ),

          Expanded(
            child: Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration:
                          const InputDecoration(
                            hintText:
                            'Search lat,long or place',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _searchLocation,
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                ),
                  Container(
                    height: 40,
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(icon: Icon(Icons.undo), onPressed: _undo),
                        IconButton(icon: Icon(Icons.redo), onPressed: _redo),
                        IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: _clearArea),
                        IconButton(
                            icon: Icon(Icons.check, color: Colors.green),
                            onPressed: _closePolygon),
                      ],
                    ),
                  ),

                // MAP
                Expanded(
                  child: GoogleMap(
                    mapType: MapType.hybrid,
                    onMapCreated: _onMapCreated,
                    onCameraMove: (CameraPosition position) {
                      _currentZoom = position.zoom;
                    },
                    initialCameraPosition:
                    CameraPosition(
                        target:
                        _getInitialCameraPosition(),
                        zoom: _currentZoom),

                    markers: {
                      ..._markers,
                      ..._vertices,
                    },

                    polylines: _lines,
                    polygons: {
                      ..._buildAllDevicePolygons(),
                      ..._polygons,
                    },
                    onTap: (latLng) {
                         _addAreaPoint(latLng);

                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Set<Polygon> _buildAllDevicePolygons() {
    Set<Polygon> polygons = {};

    final devices =
        mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];

    for (var device in devices) {
      final area = device.geography?.area;

      if (area != null && area.length >= 3) {
        List<LatLng> points = area
            .map((e) => LatLng(e.latitude!, e.longitude!))
            .toList();

        final isSelected =
            device.deviceId == _selectedDevice?.deviceId;

        polygons.add(
          Polygon(
            polygonId: PolygonId(
                device.deviceId ?? device.controllerId.toString()),
            points: points,

            fillColor: isSelected
                ? Colors.blue.withOpacity(0.4)
                : Colors.yellow.withOpacity(0.4),

            strokeColor:
            isSelected ? Colors.yellow : Colors.white,

            strokeWidth: isSelected ? 3 : 3,
          ),
        );
      }
    }

    return polygons;
  }
  void _undo() {
    if (_undoStack.isEmpty) return;

    setState(() {
      _redoStack.add(List.from(_areaPoints));
      _areaPoints = _undoStack.removeLast();
      _isClosed = false;
    });

    _drawArea();
    _saveAreaToDevice();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    setState(() {
      _undoStack.add(List.from(_areaPoints));
      _areaPoints = _redoStack.removeLast();
    });

    _drawArea();
    _saveAreaToDevice();
  }

  void _clearArea() {
    if (_areaPoints.isEmpty) return;

    _saveState();

    setState(() {
      _areaPoints.clear();
      _isClosed = false;
      _polygons.clear();
      _lines.clear();
      _vertices.clear();
    });

    _saveAreaToDevice();
  }
  void _saveState() {
    _undoStack.add(List.from(_areaPoints));
    _redoStack.clear();
  }
}