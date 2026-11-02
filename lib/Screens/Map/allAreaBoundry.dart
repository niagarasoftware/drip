import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oro_drip_irrigation/Screens/Map/MapAreaModel.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import 'areaboundry.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';


class MapScreenAllArea extends StatefulWidget {
  const MapScreenAllArea({
    super.key,
    required this.userId,
    required this.customerId,
    required this.controllerId,
    required this.imeiNo,
  });

  final int userId, customerId, controllerId;
  final String imeiNo;

  @override
  State<MapScreenAllArea> createState() => _MapScreenAllAreaState();
}

class _MapScreenAllAreaState extends State<MapScreenAllArea> {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  bool _isLoading = true;  // To track loading state

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(11.1387361, 76.9764367),
    zoom: 15,
  );

  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  Map<String, Valve> _valves = {};

  final List<Color> _areaColors = [
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.cyan,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    AppLog.log('Fetching geography data...');
    try {
      final repository = Repository(HttpService());
      final response = await repository.getgeographyArea({
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
      });

      if (response.statusCode == 200) {
        final mapAreaModel = valveResponseModelFromJson(response.body);

        _valves = {
          for (var mapobject in mapAreaModel.data?.valveGeographyArea ?? [])
            mapobject.name!: Valve.fromMapobject(mapobject, mapAreaModel.data?.liveMessage),
        };

        await _updatePolygons();
      } else {
        AppLog.log('Failed to load data: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLog.log('Error fetching data: $e');
      AppLog.log('StackTrace: $stackTrace');
    } finally {
      setState(() {
        _isLoading = false;  // Set loading to false once data is fetched
      });
    }
  }

  Future<void> _updatePolygons() async {
    final Set<Polygon> newPolygons = {};
    final Set<Marker> newMarkers = {};
    int colorIndex = 0;

    for (var valve in _valves.values) {
      if (valve.area.length >= 3) {
        final strokeColor = _areaColors[colorIndex % _areaColors.length];
        colorIndex++;

        newPolygons.add(
          Polygon(
            polygonId: PolygonId(valve.name),
            points: valve.area,
            strokeColor: strokeColor,
            strokeWidth: 1,
            fillColor: getColorByStatus(valve.status,valve.percentage).withValues(alpha: 0.7),
          ),
        );

        final center = _getPolygonCenter(valve.area);

        final markerIcon = await TextOnImage(text: valve.name).toBitmapDescriptor(
          logicalSize: const Size(150, 150),
          imageSize: const Size(300, 400),
        );

        newMarkers.add(
          Marker(
            markerId: MarkerId(valve.name),
            position: center,
            infoWindow: InfoWindow(title: valve.name,snippet: "Irrigation Percentage is💧:${valve.percentage}%"),
            icon: markerIcon,
            visible: true,
          ),
        );
      }
    }

    setState(() {
      _polygons
        ..clear()
        ..addAll(newPolygons);
      _markers
        ..clear()
        ..addAll(newMarkers);
    });
  }

  LatLng _getPolygonCenter(List<LatLng> points) {
    double lat = 0.0;
    double lng = 0.0;
    for (var point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }
  //COLOR FOR MAP
  Color getColorByStatus(int? status, int? percentage) {
    AppLog.log('status:$status,percentage:$percentage');
    if (status == 1 || status == 2) {
      if (percentage == 100) {
        return Colors.blue;
      } else {
        return Colors.green;
      }
    } else if (status == 0 || status == 3) {
      if (percentage == 0) {
        return Colors.red;
      } else {
        return Colors.yellow;
      }
    } else {
      return Colors.grey;
    }
  }

  Future<void> _zoomToValves() async {
    if (_valves.isEmpty) return;
    final allPoints = _valves.values.expand((v) => v.area).toList();
    if (allPoints.isEmpty) return;

    final bounds = _calculateBounds(allPoints);
    final controller = await _controllerCompleter.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points[0].latitude, maxLat = points[0].latitude;
    double minLng = points[0].longitude, maxLng = points[0].longitude;

    for (var point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Area with Valves'),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _zoomToValves,
          ),
          IconButton(
            icon: const Icon(Icons.edit_location_alt),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => MapScreenArea(
                  userId: widget.userId,
                  customerId: widget.customerId,
                  controllerId: widget.controllerId,
                  imeiNo: widget.imeiNo,
                ),
              ));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) {
              _mapController = controller;
              _controllerCompleter.complete(controller);
              if (_valves.isNotEmpty) {
                _zoomToValves();
              }
            },
            mapType: MapType.hybrid,
            polygons: _polygons,
            markers: _markers,
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(backgroundColor: Colors.red,),
            ),
        ],
      ),
    );
  }
}

class TextOnImage extends StatelessWidget {
  const TextOnImage({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Image(
          image: AssetImage("assets/png/textmarker.png"),
          height: 50,
          width: 100,
        ),
        Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
