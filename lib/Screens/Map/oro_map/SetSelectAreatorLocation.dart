import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../googlemap_model.dart';
import 'getlatlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key, required this.index}) : super(key: key);
  final int index;

  @override
  _MapScreenState createState() => _MapScreenState();
}


class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
   double _currentZoom = 15;
  bool _isAreaMode = false;
  late MqttPayloadProvider mqttPayloadProvider;
  ConnectedObject? _selectedObject;
  bool _isDrawerOpen = false;
  double _drawerWidth = 280;

  List<LatLng> _points = [];
  bool _isClosed = false;
  Set<Marker> _vertices = {};
  Set<Polyline> _lines = {};
  Set<Polygon> _fill = {};
  BitmapDescriptor? _dotIcon;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    _createMarkerImage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllMarkers();
    });
  }

  Future<void> _createMarkerImage() async {
    const double size = 10;

    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.circle.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: Icons.circle.fontFamily,
        color: Colors.white, // dot color
      ),
    );

    textPainter.layout();
    textPainter.paint(canvas, const Offset(0, 0));

    final image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );

    final byteData = await image.toByteData(format: ImageByteFormat.png);

    _dotIcon = BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Load all markers from device's connected objects
  void _loadAllMarkers() {
    final device =
    mqttPayloadProvider.mapModelInstance.data?.deviceList?[widget.index];

    final objects = device?.connectedObject;

    AppLog.log('Device index: ${widget.index}');
    AppLog.log('Device geography: ${device?.geography}');
    AppLog.log('Device geography lat: ${device?.geography?.lat}');
    AppLog.log('Device geography long: ${device?.geography?.long}');
    AppLog.log('Connected objects: ${objects?.length ?? 0}');

    if (objects == null || objects.isEmpty) return;

    Set<Marker> newMarkers = {};

    for (var obj in objects) {
      if (obj.lat != null && obj.long != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(obj.name ?? obj.objectName ?? 'object_${objects.indexOf(obj)}'),
            position: LatLng(obj.lat!, obj.long!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              obj == _selectedObject
                  ? BitmapDescriptor.hueAzure
                  : obj.status == 1
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: obj.name ?? 'Connected Object',
              snippet:
              'Lat: ${obj.lat}, Long: ${obj.long}, Status: ${obj.status ?? "Unknown"}',
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  /// Update only the selected marker's position
  void _updateMarker(double lat, double long) {
    if (_selectedObject == null) return;

    final position = LatLng(lat, long);

    setState(() {
      // Remove old marker of selected object
      _markers.removeWhere((marker) =>
      marker.markerId.value ==
          (_selectedObject!.name ?? _selectedObject!.objectName));

      // Add updated marker with info always visible
      _markers.add(
        Marker(
          markerId: MarkerId(
              _selectedObject!.name ?? _selectedObject!.objectName ?? 'selected'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: _selectedObject?.name ?? 'Connected Object',
            snippet:
            'Lat: ${_selectedObject?.lat}, Long: ${_selectedObject?.long}, Status: ON',
          ),
        ),
      );
    });

    AppLog.log('Lat: ${_selectedObject?.lat}, Long: ${_selectedObject?.long}');
    AppLog.log('Lat: ${lat}, Long: ${long}');
    AppLog.log('_selectedObject:${_selectedObject?.name} ${_selectedObject?.objectId}');
    _selectedObject!.lat = lat;
    _selectedObject!.long = long;
    _selectedObject!.status = 1;

    mqttPayloadProvider.notifyListeners();

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, _currentZoom),
    );
  }

  /// Search location and update marker
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

  String extractCoordinates(String input) {
    final regExp = RegExp(r"@(-?\d+\.\d+),(-?\d+\.\d+)");
    final match = regExp.firstMatch(input);

    if (match != null) {
      return '${match.group(1)},${match.group(2)}';
    }

    var coords = input.split(",");
    if (coords.length == 2) {
      return '${coords[0].trim()},${coords[1].trim()}';
    }

    return "Invalid coordinates format.";
  }


  LatLng _getInitialCameraPosition() {
    // 1️⃣ If selected object has valid lat/long → use it
    if (_selectedObject != null &&
        _selectedObject!.lat != null &&
        _selectedObject!.long != null &&
        _selectedObject!.lat != 0 &&
        _selectedObject!.long != 0) {
      return LatLng(_selectedObject!.lat!, _selectedObject!.long!);
    }

    // 2️⃣ Otherwise use first valid object
    final device =
    mqttPayloadProvider.mapModelInstance.data?.deviceList?[widget.index];

    final objects = device?.connectedObject;

    if (objects != null && objects.isNotEmpty) {
      for (var obj in objects) {
        if (obj.lat != null &&
            obj.long != null &&
            obj.lat != 0 &&
            obj.long != 0) {
          return LatLng(obj.lat!, obj.long!);
        }
      }
    }

    // 3️⃣ Final fallback (safe location)
    return const LatLng(11.1271, 78.6569);
  }


  Future<void> _checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status == PermissionStatus.granted) {
      setState(() {});
    }
  }

  void _refreshLayers() {
    setState(() {
      _vertices.clear();
      _lines.clear();
      _fill.clear();

      // Step A: Create interactive, DRAGGABLE dots (Vertices)
      for (int i = 0; i < _points.length; i++) {
        bool isStartPoint = (i == 0);

        _vertices.add(
          Marker(
            markerId: MarkerId("vertex_$i"),
            position: _points[i],
            draggable: true, // 🚀 THE KEY OPTION
            anchor: const Offset(0.5, 0.5), // Center the dot on the point
            // Visual style: Start point is Yellow (if open), others are Azure/Asset
            icon: (isStartPoint && !_isClosed)
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow)
                : (_dotIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),

            // Interaction: Closing the Loop
            onTap: () {
              // If tapping the start point, have 3+ points, and it's not closed, fill it!
              if (isStartPoint && _points.length >= 3 && !_isClosed) {
                setState(() => _isClosed = true);
                _refreshLayers();
              }
            },

            // Interaction: DRAGGING
            onDragEnd: (newPos) {
              // 🚀 Update the master point list with the new position
              setState(() {
                _points[i] = newPos;
                _selectedObject!.area![i].latitude = newPos.latitude;
                _selectedObject!.area![i].longitude = newPos.longitude;
                _refreshLayers();
              });
            },
          ),
        );
      }

      // Step B: Create the Lines (The Path)
      List<LatLng> linePath = List.from(_points);
      // Visually close the loop if the state is closed
      if (_isClosed && _points.isNotEmpty) {
        linePath.add(_points.first); // Join last point back to first
      }
      _lines.add(Polyline(
        polylineId: const PolylineId("path"),
        points: linePath,
        color: Colors.yellow,
        width: 3,
        jointType: JointType.round,
      ));

      if (_isClosed && _points.length >= 3) {
        _fill.add(Polygon(
          polygonId: const PolygonId("area_fill"),
          points: _points,
          strokeWidth: 0, // Border is handled by Polyline
          fillColor: Colors.blue.withOpacity(0.3),
        ));
      }
    });
  }

  void _handleMapTap(LatLng pos) {
    if (_isClosed) return;

    setState(() {
      _points.add(pos);
      _refreshLayers();
    });


  }

  @override
  Widget build(BuildContext context) {
    final objects = mqttPayloadProvider
        .mapModelInstance.data?.deviceList?[widget.index].connectedObject;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Location'),
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
          // ✅ Side Drawer Panel (Resizable)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isDrawerOpen ? _drawerWidth : 0,
            color: Colors.white,
            child: _isDrawerOpen
                ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  width: double.infinity,
                  color: Colors.teal.shade500,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Connected Objects",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      // 🚀 THE SINGLE TOGGLE ICON
                      IconButton(
                        icon: Icon(
                          _isAreaMode ? Icons.polyline : Icons.location_on,
                          color: Colors.white,
                        ),
                        tooltip: _isAreaMode ? "Switch to Marker Mode" : "Switch to Area Mode",
                        onPressed: () {
                          setState(() {
                            _isAreaMode = !_isAreaMode;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isAreaMode ? "Area Mode Active" : "Marker Mode Active"),
                              duration: const Duration(milliseconds: 600),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: objects == null || objects.isEmpty
                      ? const Center(
                      child: Text("No Connected Objects"))
                      : ListView.builder(
                    itemCount: objects.length,
                    itemBuilder: (context, index) {
                      final obj = objects[index];

                      return ListTile(
                        selected: obj == _selectedObject,
                        selectedTileColor:
                        Colors.blue.withOpacity(0.2),
                        title: Text(obj.name ??
                            obj.objectName ??
                            "Object"),
                        subtitle: Text(
                            "Lat: ${obj.lat}, Long: ${obj.long}\nStatus: ${obj.status ?? "Unknown"}"),
                        onTap: () {
                          setState(() {
                            _selectedObject = obj;
                          });

                          if (obj.lat != null &&
                              obj.long != null) {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(
                                    obj.lat!, obj.long!),
                                _currentZoom,
                              ),
                            );
                          }

                          _loadAllMarkers();
                        },
                      );
                    },
                  ),
                ),
              ],
            )
                : null,
          ),

          // ✅ Map Area (Auto Resizes)
          Expanded(
            child: Column(
              children: [
                _buildSelectedObjectBar(),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText:
                            'Search Area (e.g., 11.1326952, 76.9767822)',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) {
                            _searchLocation();
                          },
                        ),
                      ),
                      TextButton(
                        onPressed: _searchLocation,
                        child: const Text(
                          'Search',
                          style:
                          TextStyle(color: Colors.blue),
                        ),
                      ),
                      IconButton(onPressed: _getCurrentLocation, icon: const Icon(Icons.my_location, color: Colors.blue)),
                    ],
                  ),
                ),
                // Google Map
                Expanded(
                  child: GoogleMap(
                    mapType: MapType.hybrid,
                    onMapCreated: _onMapCreated,
                    onCameraMove: (CameraPosition position) {
                      _currentZoom = position.zoom;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _getInitialCameraPosition(),
                      zoom: _currentZoom,
                    ),
                    // ✅ CONDITION: Switch between object markers and boundary vertices
                    // markers: _isAreaMode ? _vertices : _markers,
                    markers: {
                      ..._markers,  // The device pins (Green/Red/Azure)
                      ..._vertices, // The boundary dots (Yellow/Blue)
                    },

                    // ✅ CONDITION: Only show lines and fills when in Area Mode
                    polylines: _lines ,
                    polygons: _fill ,

                    // ✅ CONDITION: Change what happens when the user taps the map
                    onTap: (LatLng latLng) {
                      if (_isAreaMode) {
                        _handleMapTap(latLng);
                        // _updateArea(Area(latitude: latLng.latitude,longitude: latLng.longitude)); // Boundary Logic
                      } else {
                        _updateMarker(latLng.latitude, latLng.longitude); // Marker Logic
                      }
                    },

                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    compassEnabled: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSelectedObjectBar() {
    if (_selectedObject == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(5),
        color: Colors.grey.shade200,
        child: const Text(
          "No Object Selected",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      color: Colors.teal.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedObject!.name ??
                _selectedObject!.objectName ??
                "Connected Object",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Lat: ${_selectedObject!.lat ?? "-"}  "
                "Long: ${_selectedObject!.long ?? "-"}",
          ),
          Text(
            "Status: ${_selectedObject!.status == 1 ? "ON" : "OFF"}",
          ),
        ],
      ),
    );
  }
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable Location Services')),
      );
      return;
    }

    // Check Permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get Position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // ✅ Add marker
    _updateMarker(position.latitude, position.longitude);
  }

}