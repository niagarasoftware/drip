
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../googlemap_model.dart';
import 'getlatlong.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';


class SetSelectOroLocation extends StatefulWidget {
  const SetSelectOroLocation({Key? key, required this.index}) : super(key: key);
  final int index;
  @override
  _SetSelectOroLocationState createState() => _SetSelectOroLocationState();
}

class _SetSelectOroLocationState extends State<SetSelectOroLocation> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  LatLng? _objectPosition;
  double _currentZoom = 17;

  late MqttPayloadProvider mqttPayloadProvider;
  ConnectedObject? _selectedObject;
  bool _isDrawerOpen = false;
  double _drawerWidth = 280;

  List<LatLng> _points = [];
  Set<Marker> _vertices = {};
  Set<Polyline> _lines = {};
  Set<Polygon> _polygons = {};

  bool _isClosed = false;
  bool _isEditMode = false;
  List<List<LatLng>> _undoStack = [];
  List<List<LatLng>> _redoStack = [];
  List<LatLng> _finalPolygonPoints = [];
  List<LatLng> _redoPoints = [];


  @override
  void initState() {
    super.initState();
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllMarkers();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    controller.animateCamera(CameraUpdate.newLatLngZoom(
      _getInitialCameraPosition(), _currentZoom,
    ));
  }

  /// Load all markers from device's connected objects
  void _loadAllMarkers() {
    final device =
    mqttPayloadProvider.mapModelInstance.data?.deviceList?[widget.index];
    AppLog.log("load all markers ${device?.geography?.lat}");
    AppLog.log('Device index: ${widget.index}');
    AppLog.log('Device geography: ${device?.geography}');
    AppLog.log('Device geography lat: ${device?.geography?.lat}');
    AppLog.log('Device geography long: ${device?.geography?.long}');
    final objects = device?.connectedObject;
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
    if (_selectedObject == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select Object first"),
        ),
      );
      return null;
    }

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
    print("call _getInitialCameraPosition");
    // 1. First priority: Selected object
    if (_selectedObject != null &&
        _selectedObject!.lat != null &&
        _selectedObject!.long != null &&
        _selectedObject!.lat != 0 &&
        _selectedObject!.long != 0) {
      return LatLng(
        _selectedObject!.lat!,
        _selectedObject!.long!,
      );
    }

    final device =
    mqttPayloadProvider.mapModelInstance.data?.deviceList?[widget.index];

    print('device---lat-->${device?.geography?.lat}');
    print('device---long-->${device?.geography?.long}');

    // 2. Second priority: First valid connected object
    final objects = device?.connectedObject;

    if (objects != null && objects.isNotEmpty) {
      for (final obj in objects) {
        if (obj.lat != null &&
            obj.long != null &&
            obj.lat != 0 &&
            obj.long != 0) {
          return LatLng(
            obj.lat!,
            obj.long!,
          );
        }
      }
    }

    // 3. Third priority: Device Geography
    final device1 =
    mqttPayloadProvider.mapModelInstance.data?.deviceList?[0];
    final geography = device1?.geography;

    if (geography?.lat != null &&
        geography?.long != null &&
        geography!.lat != 0 &&
        geography.long != 0) {
      return LatLng(
        geography.lat!,
        geography.long!,
      );
    }

    // 4. Final fallback: Existing default location
    return const LatLng(11.1271, 78.6569);
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
          //MARK:- Side Drawer Panel (Resizable)
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
                    "Connected Objects",
                    style:
                    TextStyle(color: Colors.white, fontSize: 18),
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
                      final hasArea = obj.area != null && obj.area!.isNotEmpty;
                      final first = hasArea ? obj.area!.first : null;
                      return ListTile(
                        selected: obj == _selectedObject,
                        selectedTileColor:
                        Colors.blue.withOpacity(0.2),
                        title: Text(obj.name ??
                            obj.objectName ??
                            "Object"),
                        subtitle: Text(
                          "Lat: ${first?.latitude ?? '-'}, "
                              "Long: ${first?.longitude ?? '-'}\n"
                              "Status: ${obj.status ?? ''}",
                        ),
                        onTap: () {
                          setState(() {
                            _selectedObject = obj;
                            AppLog.log("_selectedObject:${_selectedObject!.name},${_selectedObject!.lat},${_selectedObject!.long},obj:${obj.name},${obj.lat},${obj.long}");

                            // ✅ RESET OLD POLYGON (IMPORTANT)
                            _points.clear();
                            _vertices.clear();
                            _lines.clear();
                            _polygons.clear();
                            _isClosed = false;
                            _isEditMode = false;
                            _finalPolygonPoints.clear();
                            _undoStack.clear();
                            _redoStack.clear();
                            _redoPoints.clear();

                            // ✅ LOAD EXISTING AREA (optional)
                            if (obj.area != null && obj.area!.isNotEmpty) {
                              _points = obj.area!
                                  .map((e) => LatLng(e.latitude!, e.longitude!))
                                  .toList();

                              _isClosed = _points.length >= 3;
                              _finalPolygonPoints = List.from(_points);
                            }
                          });

                          _drawPolygon();

                          if (obj.lat != null && obj.long != null) {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(obj.lat!, obj.long!),
                                _currentZoom,
                              ),
                            );
                          }
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
                Container(
                  height: 40,
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(Icons.undo),
                        onPressed: _points.isEmpty ? null : _undo,
                      ),

                      IconButton(
                        icon: Icon(Icons.redo),
                        onPressed: _redoPoints.isEmpty ? null : _redo,
                      ),
                      IconButton(
                        tooltip: _isEditMode ? 'Done Editing' : 'Edit Polygon',
                        icon: Icon(
                          _isEditMode ? Icons.check_circle : Icons.edit,
                          color: _isEditMode ? Colors.green : Colors.blue,
                        ),
                        onPressed: _toggleEditMode,
                      ),
                      IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: _deletePolygon),
                      IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: _closePolygon),
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
                    markers: {
                      ..._markers,
                      ..._vertices,           // edit points
                      ..._buildPolygonLabels(), // ✅ polygon names
                    },// vertices visible
                    polylines: _lines,
                    polygons: {
                      ..._buildAllPolygons(),
                      ..._polygons,
                    },
                    onTap: (LatLng latLng) {
                      _addPoint(latLng); // ✅ polygon point add
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
  // Edit an existing closed polygon without removing its closing edge.
  // An unfinished polyline stays open until the user manually closes it.
  void _toggleEditMode() {
    if (_selectedObject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Object first')),
      );
      return;
    }
    setState(() {
      // Keep the original manual-close state while editing.
      // Edit does not automatically close an open polyline.
      _isEditMode = !_isEditMode;
      _finalPolygonPoints = List<LatLng>.from(_points);
      _syncPointsToObject();
    });
    _drawPolygon();
  }

  void _closePolygon() {
    if (_selectedObject == null || _points.length < 3) return;
    setState(() {
      _isClosed = true;
      _isEditMode = false;
      _finalPolygonPoints = List<LatLng>.from(_points);
      _syncPointsToObject();
    });
    _drawPolygon();
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
            (_selectedObject?.area != null &&
                _selectedObject!.area!.isNotEmpty)
                ? "Lat: ${_selectedObject!.area!.first.latitude}  "
                "Long: ${_selectedObject!.area!.first.longitude}"
                : "Lat: -  Long: -",
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
    // _updateMarker(position.latitude, position.longitude);
    _addPoint(LatLng(position.latitude, position.longitude));
  }

  void _addPoint(LatLng point) {
    if (_selectedObject == null) return;
    if (_isClosed && !_isEditMode) return;

    _saveState();
    setState(() {
      _points.add(point);
      _redoPoints.clear();
      // Do NOT auto-close at three points. Only first marker or green
      // check button closes the shape. Editing an already closed shape
      // keeps it closed as more points are appended.
      _finalPolygonPoints = List<LatLng>.from(_points);
      _syncPointsToObject();
    });
    _drawPolygon();
  }

  void _drawPolygon() {
    _vertices.clear();
    _lines.clear();
    _polygons.clear();

    if (_selectedObject == null) return;

    // 🔹 MARKERS (editable)
    for (int i = 0; i < _points.length; i++) {
      bool isFirst = i == 0;

      _vertices.add(
        Marker(
          markerId: MarkerId("point_$i"),
          position: _points[i],
          draggable: _isEditMode || !_isClosed,
          consumeTapEvents: true,
          zIndexInt: 100,

          icon: BitmapDescriptor.defaultMarkerWithHue(
            isFirst
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueAzure,
          ),

          onTap: () {
            if (isFirst && !_isClosed && _points.length >= 3) {
              _closePolygon();
            }
          },

          onDragEnd: (newPos) {
            if (!_isEditMode && _isClosed) return;
            _saveState();

            setState(() {
              // ✅ Update point
              _points[i] = newPos;

              // ✅ Sync to object (IMPORTANT)
              _syncPointsToObject();

              // ✅ If polygon already closed → update final shape also
              _finalPolygonPoints = List.from(_points);
            });

            _drawPolygon();
          },
        ),
      );
    }

    // 🔹 LINE (always from editing points)
    List<LatLng> path = List.from(_points);

    if (_isClosed && _points.length >= 3) {
      path.add(_points.first);
    }

    _lines.add(
      Polyline(
        polylineId: const PolylineId("line"),
        points: path,
        color: Colors.yellow,
        width: 3,
      ),
    );

    // BLUE AREA FILL: show automatically from the third point onward.
    // This does NOT change _isClosed: only the first marker or green check
    // closes the yellow polyline. Editing keeps the fill up to date.
    if (_points.length >= 3) {
      _polygons.add(
        Polygon(
          polygonId: const PolygonId("editing"),
          points: List<LatLng>.from(_points),
          fillColor: Colors.blue.withOpacity(0.4),
          strokeWidth: 2,
          strokeColor: Colors.blue,
        ),
      );
    }

    setState(() {});
  }
  Set<Marker> _buildPolygonLabels() {
    Set<Marker> labels = {};

    final objects = mqttPayloadProvider
        .mapModelInstance.data?.deviceList?[widget.index].connectedObject ?? [];

    for (var obj in objects) {
      // Keep the selected object's polygon/vertex markers unobstructed.
      if (obj == _selectedObject) continue;
      final area = obj.area;

      if (area != null && area.isNotEmpty) {
        final firstPoint = area.first;

        labels.add(
          Marker(
            markerId: MarkerId("label_${obj.name}"),
            position: LatLng(firstPoint.latitude!, firstPoint.longitude!),
            infoWindow: InfoWindow(
              title: obj.name ?? obj.objectName ?? "Area",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              obj == _selectedObject
                  ? BitmapDescriptor.hueAzure
                  : BitmapDescriptor.hueYellow,
            ),
          ),
        );
      }
    }

    return labels;
  }
  void _saveState() {
    _undoStack.add(List.from(_points));
    _redoStack.clear();
  }
  void _undo() {
    if (_points.isEmpty) return;

    setState(() {
      _redoPoints.add(_points.last);
      _points.removeLast();
    });

    // Preserve manual close status; a shape with fewer than 3 points
    // cannot remain a closed polygon after undo.
    if (_points.length < 3) _isClosed = false;
    _syncPointsToObject();
    _finalPolygonPoints = List.from(_points);
    _drawPolygon();
  }
  void _redo() {
    if (_redoPoints.isEmpty) return;

    setState(() {
      _points.add(_redoPoints.removeLast());
    });

    // Preserve manual close status; a shape with fewer than 3 points
    // cannot remain a closed polygon after undo.
    if (_points.length < 3) _isClosed = false;
    _syncPointsToObject();
    _finalPolygonPoints = List.from(_points);
    _drawPolygon();
  }
  Set<Polygon> _buildAllPolygons() {
    Set<Polygon> polygons = {};

    final objects = mqttPayloadProvider
        .mapModelInstance.data?.deviceList?[widget.index].connectedObject ?? [];

    for (var obj in objects) {
      // Keep the selected object's polygon/vertex markers unobstructed.
      if (obj == _selectedObject) continue;
      final area = obj.area;

      if (area != null && area.isNotEmpty) {
        final points = area
            .map((e) => LatLng(e.latitude!, e.longitude!))
            .toList();

        final isSelected = obj == _selectedObject;

        polygons.add(
          Polygon(
            polygonId: PolygonId(obj.name ?? obj.objectName ?? "obj"),

            points: points,

            fillColor: isSelected
                ? Colors.blue.withOpacity(0.4)   // ✅ Selected
                : Colors.yellow.withOpacity(0.3), // ✅ Others

            strokeColor:
            isSelected ? Colors.blue : Colors.grey,

            strokeWidth: isSelected ? 3 : 1,
          ),
        );
      }
    }

    return polygons;
  }
  void _deletePolygon() {
    if (_selectedObject == null) return;

    setState(() {
      _points.clear();
      _finalPolygonPoints.clear(); // ✅ IMPORTANT
      _vertices.clear();
      _lines.clear();
      _polygons.clear();
      _isClosed = false;
      _isEditMode = false;
      _redoPoints.clear();
      _redoStack.clear();
      _undoStack.clear();
      _selectedObject!.area = [];
    });
  }
  void _syncPointsToObject() {
    if (_selectedObject == null) return;

    _selectedObject!.area = _points
        .map((p) => Area(
      latitude: p.latitude,
      longitude: p.longitude,
    ))
        .toList();
  }

}
