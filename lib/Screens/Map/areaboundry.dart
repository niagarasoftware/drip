
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oro_drip_irrigation/Screens/Map/MapAreaModel.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import 'oro_map/getlatlong.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';


 // MapScreenArea widget
class MapScreenArea extends StatefulWidget {
  const MapScreenArea({super.key,
    required this.userId,
    required this.customerId,
    required this.controllerId,
    required this.imeiNo});
  final int userId, customerId, controllerId;
  final String imeiNo;

  @override
  State<MapScreenArea> createState() => _MapScreenAreaState();
}

class _MapScreenAreaState extends State<MapScreenArea> {
  GoogleMapController? _mapController;
  bool _isDrawerOpen = false;
  final double _drawerWidth = 280;
  double _currentZoom = 15;
  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  Map<String, Valve> _valves = {};
  Valve? selectedValve;
  final TextEditingController _searchController = TextEditingController();

  ValveResponseModel _valveResponseModel = ValveResponseModel();


  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    AppLog.log('fetchData');
    try{
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.getgeographyArea({
        "userId": widget.customerId,
        "controllerId" : widget.controllerId
      });
      // AppLog.log('getUserDetails${getUserDetails.body.runtimeType}');
      // final jsonData = jsonDecode(getUserDetails.body);
      if (getUserDetails.statusCode == 200) {
        setState(() {
          var jsonData = getUserDetails.body;
          AppLog.log('jsonData${jsonData.runtimeType}');

          _valveResponseModel = valveResponseModelFromJson(jsonData);
          setState(() {
            _valves = {
              for (var mapobject in _valveResponseModel.data?.valveGeographyArea ?? [])
                mapobject.name!: Valve.fromMapobject(mapobject, _valveResponseModel.data?.liveMessage)
            };
            _updatePolygons();
          });
        });
      } else {
        //_showSnackBar(response.body);
      }
    }
    catch (e, stackTrace) {
      AppLog.log(' Error overAll getData => ${e.toString()}');
      AppLog.log(' trace overAll getData  => $stackTrace');
    }
  }

  Future<void> _saveAreas() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_valves.map((key, valve) {
      return MapEntry(key, valve.toJson());
    }));
    await prefs.setString('saved_areas', encoded);
  }

  void _selectValve(String? valveName) {
    setState(() {
      selectedValve = valveName != null ? _valves[valveName] : null;
      _updatePolygons();
    });
  }

  List<Map<String, dynamic>> convertValvesToJson() {
    List<Valve> valveList = _valves.values.toList();
    List<Map<String, dynamic>> jsonList = valveList.map((v) => v.toJson()).toList();
    return jsonList;
  }
  Future<void> _sendSelectedValveToServer() async {
    await _saveValveArea();
    try {

      List<Map<String, dynamic>> jsondata = convertValvesToJson();
      AppLog.log('\n json: $jsondata');
      Map<String, dynamic> body = {
        "userId": widget.customerId,
        "controllerId" : widget.controllerId,
        "valveGeographyArea" : jsondata,
        "modifyUser" : widget.userId
      };
      AppLog.log('\n body:$body');

      final Repository repository = Repository(HttpService());
      final response = await repository.updategeographyArea(body);
      AppLog.log('response:${response.body}');
      if (response.statusCode != 200) {
        AppLog.log('Failed to send valve : ${response.body}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All valves sent successfully!')),
      );
    } catch (e) {
      AppLog.log('Error sending valves: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send valves')),
      );
    }
  }


  Future<void> _searchLocation() async {
    try {
      final input = _searchController.text.trim();

      final LatLng? result = await getLatLngFromInput(input);

      if (result != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(result, 15),
        );
      } else {
        throw Exception("Invalid location");
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter valid area name, map link, DMS, or "lat, long"',
          ),
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
  void _updatePolygons() {
    setState(() {
      _polygons.clear();
      _markers.clear();

      for (var valve in _valves.values) {
        if (valve.area.length >= 3) {
          _polygons.add(Polygon(
            polygonId: PolygonId(valve.name),
            points: valve.area,
            strokeColor: valve.status == 1 ? Colors.green : Colors.red,
            strokeWidth: 1,
            fillColor: valve.status == 1 ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
          ));
        }

        if (selectedValve != null && selectedValve!.name == valve.name) {
          valve.area.asMap().forEach((index, point) {
            _markers.add(
              Marker(
                markerId: MarkerId('${valve.name}_point_$index'),
                position: point,
                infoWindow: InfoWindow(title: 'Valve ${valve.name}'),
                draggable: true,
                onDragEnd: (newPosition) => _onMarkerDragEnd(newPosition, index),
              ),
            );
          });
        }
      }
    });
  }

  void _onMapTapped(LatLng position) {
    if (selectedValve == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valve from the dropdown')),
      );
      return;
    }
    setState(() {
      selectedValve!.area.add(position);
      _updatePolygons();
    });
    _saveAreas();
  }

  void _onMarkerDragEnd(LatLng newPosition, int index) {
    if (selectedValve != null && index >= 0 && index < selectedValve!.area.length) {
      setState(() {
        selectedValve!.area[index] = newPosition;
        _updatePolygons();
      });
      _saveAreas();
    }
  }

  Future<void> _saveValveArea() async {
    if (selectedValve != null) {
      setState(() {
        _valves[selectedValve!.name] = selectedValve!;
      });
      _saveAreas();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Valve "${selectedValve!.name}" saved')),
      );
    }
  }

  void _undo() {
    if (selectedValve != null && selectedValve!.area.isNotEmpty) {
      setState(() {
        selectedValve!.area.removeLast();
        _updatePolygons();
      });
      _saveAreas();
    }
  }

  void _clearBoundary() {
    if (selectedValve != null) {
      setState(() {
        selectedValve!.area.clear();
        _updatePolygons();
      });
      _saveAreas();
    }
  }

  void _zoomToValves() {
    if (_valves.isEmpty) return;
    final allPoints = _valves.values.expand((v) => v.area).toList();
    if (allPoints.isEmpty) return;
    final bounds = _calculateBounds(allPoints);
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points[0].latitude, maxLat = points[0].latitude;
    double minLng = points[0].longitude, maxLng = points[0].longitude;
    for (var point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  CameraPosition _getInitialCameraPosition() {
    // 1️⃣ If selected valve has at least one valid point
    if (selectedValve != null && selectedValve!.area.isNotEmpty) {
      final firstPoint = selectedValve!.area.first;
      return CameraPosition(
        target: firstPoint,
        zoom:_currentZoom
        ,
      );
    }

    // 2️⃣ If any valve has valid area points
    for (var valve in _valves.values) {
      if (valve.area.isNotEmpty) {
        return CameraPosition(
          target: valve.area.first,
          zoom: _currentZoom,
        );
      }
    }

    // 3️⃣ Final fallback (Safe default)
    return  CameraPosition(
      target: const LatLng(11.1387361, 76.9764367),
      zoom: _currentZoom,
    );
  }

  Widget _buildTopSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchLocation(),
              decoration: const InputDecoration(
                hintText:
                'Search Area (e.g., 11.1326952, 76.9767822,Coimbatore)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          TextButton(
            onPressed: _searchLocation,
            child: const Text(
              'Search',
              style: TextStyle(color: Colors.blue),
            ),
          ),

          IconButton(onPressed: _getCurrentLocation, icon: const Icon(Icons.my_location, color: Colors.blue)),
        ],
      ),
    );
  }
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable Location Services')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // 🚨 Important: Check valve selected
    if (selectedValve == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a valve first')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    // ✅ Add point to polygon
    setState(() {
      selectedValve!.area.add(currentLatLng);
      _updatePolygons();
    });

    _saveAreas();

    // ✅ Move camera
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentLatLng, _currentZoom),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            'Set Valves Area',
            maxLines: 1,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
         centerTitle: true, // 👈 important
         leadingWidth: 96,
        leading: SizedBox(
          width: 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              IconButton(
                icon: Icon(_isDrawerOpen ? Icons.close : Icons.menu),
                onPressed: () {
                  setState(() => _isDrawerOpen = !_isDrawerOpen);
                },
              ),
            ],
          ),
        ),

        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
          IconButton(icon: const Icon(Icons.clear), onPressed: _clearBoundary),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveValveArea),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendSelectedValveToServer),
        ],
      ),


      body: Row(
        children: [
          /// ✅ Side Drawer
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isDrawerOpen ? _drawerWidth : 0,
            color: Colors.white,
            child: _isDrawerOpen
                ? Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.teal,
                  child: const Text(
                    "Valves",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18),
                  ),
                ),
                Expanded(
                  child: _valves.isEmpty
                      ? const Center(child: Text("No Valves"))
                      : ListView.builder(
                    itemCount: _valves.length,
                    itemBuilder: (context, index) {
                      final valve =
                      _valves.values.toList()[index];

                      return ListTile(
                        selected:
                        selectedValve?.name ==
                            valve.name,
                        selectedTileColor:
                        Colors.blue.withValues(alpha: 0.2),
                        title: Text(valve.name),
                        subtitle: Text(
                            "Points: ${valve.area.length}\nStatus: ${valve.status == 1 ? "ON" : "OFF"}"),
                        onTap: () {
                          _selectValve(valve.name);

                          if (valve.area.isNotEmpty) {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                valve.area.first,
                                _currentZoom,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                )
              ],
            )
                : null,
          ),

          /// ✅ Map Section
          Expanded(
            child: Column(
              children: [
                _buildTopSearchBar(),
                SizedBox(height: 30,child: Text(selectedValve?.name ?? ''),),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition:
                    _getInitialCameraPosition(),
                    onCameraMove: (CameraPosition position) {
                      _currentZoom = position.zoom;
                    },
                    onMapCreated:
                        (GoogleMapController controller) {
                      _mapController = controller;
                      if (_valves.isNotEmpty) {
                        _zoomToValves();
                      }
                    },
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    compassEnabled: true,
                    mapType: MapType.hybrid,
                    markers: _markers,
                    polygons: _polygons,
                    onTap: _onMapTapped,
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