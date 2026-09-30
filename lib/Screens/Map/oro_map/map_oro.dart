
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';

import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../views/common/user_dashboard/widgets/valve_status_legend.dart';
import '../MapDeviceList.dart';
import 'map_conection_objects.dart';


class MapScreenOro extends StatefulWidget {
  MapScreenOro({
    Key? key,
    required this.userId,
    required this.customerId,
    required this.controllerId,
    required this.imeiNo,
    required this.modelId,
    this.isCheckDashboard = false,
  }) : super(key: key);

  final int userId, customerId, controllerId,modelId;
  final String imeiNo;
  final bool isCheckDashboard;

  @override
  State<MapScreenOro> createState() => _MapScreenOroState();
}

class _MapScreenOroState extends State<MapScreenOro> {
  GoogleMapController? mapController;
  LatLng center = const LatLng(11.7749, 78.4194);
  double _currentZoom = 15;

  Set<Marker> markers = {};
  Map<String, BitmapDescriptor> markerIcons = {};
  Set<Polygon> polygons = {};
  String _sentTime = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadIcons();
    await _fetchData();
  }

  // ---------------- ICON LOAD ----------------
  Future<void> _loadIcons() async {
    Future<BitmapDescriptor> load(String path) {
      return BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        path,
      );
    }

    markerIcons = {
      "gray": await load('assets/png/markergray.png'),
      "green": await load('assets/png/markergreen.png'),
      "red": await load('assets/png/markerred.png'),
      "blue": await load('assets/png/markerblue.png'),
      "yellow": await load('assets/png/markeryellow.png'),
      "pump": await load('assets/png/markerpump.png'),
      "sensor": await load('assets/png/markersensor.png'),
      "fert": await load('assets/png/markerfertilizer.png'),
      "filter": await load('assets/png/markerfilter.png'),
      "injector": await load('assets/png/markerinjector.png'),
    };
  }

  // ---------------- FETCH DATA ----------------
  Future<void> _fetchData() async {
    try {
      final repo = Repository(HttpService());
      final response = await repo.getgeography({
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
      });

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final deviceList = data["data"]["deviceList"] ?? [];
      String date = data["data"]?["liveMessage"]?["cD"] ?? "";
      String time = data["data"]?["liveMessage"]?["cT"] ?? "";
      _sentTime = "$date $time";

      Set<Marker> newMarkers = {};
      Set<Polygon> newPolygons = {};

      for (var device in deviceList) {
        final geo = device["geography"];

        // ---------------- DEVICE MARKER ----------------
        if (geo != null && geo["lat"] != null && geo["long"] != null) {
          newMarkers.add(_createMarker(
            id: "device-${device["deviceId"]}",
            lat: geo["lat"],
            lng: geo["long"],
            title: device["deviceName"],
            type: device["categoryName"],
            status: geo["status"],
            percentage: 0,
          ));
        }

        // ---------------- CONNECTED OBJECT ----------------
        for (var obj in device["connectedObject"] ?? []) {

          // ✅ GET LIVE STATUS
          var resultstaus = getStatusPercentage(
            obj["sNo"],
            data["data"]["liveMessage"],
          );

          int st = resultstaus["status"] ?? 0;
          int per = resultstaus["percentage"] ?? 0;

          // ---------------- OBJECT MARKER ----------------
          if (obj["lat"] != null && obj["long"] != null) {
            newMarkers.add(_createMarker(
              id: "obj-${obj["sNo"]}",
              lat: obj["lat"],
              lng: obj["long"],
              title: obj["name"] ?? obj["objectName"],
              type: obj["objectName"],
              status: st,
              percentage: per,
            ));
          }

          // ---------------- AREA POLYGON ----------------
          if (obj["area"] != null && obj["area"].isNotEmpty) {
            List<LatLng> points = [];

            for (var point in obj["area"]) {
              if (point["lat"] != null && point["long"] != null) {
                points.add(LatLng(point["lat"], point["long"]));
              }
            }

            if (points.isNotEmpty) {

              // ✅ GET COLOR FROM FUNCTION
              Color areaColor = _getAreaColor(st, per);

              // ✅ ADD POLYGON
              newPolygons.add(
                Polygon(
                  polygonId: PolygonId("area-${obj["sNo"]}"),
                  points: points,
                  strokeColor: areaColor.withOpacity(0.8),
                  strokeWidth: 2,
                  fillColor: areaColor.withOpacity(0.25),
                ),
              );

              // ---------------- AREA LABEL ----------------
              final centerPoint = _getPolygonCenter(points);

              final labelIcon = await _getLabelIcon(
                "${obj["name"] ?? obj["objectName"]} ($per%)",areaColor
              );

              newMarkers.add(
                Marker(
                  markerId: MarkerId("label-${obj["sNo"]}"),
                  position: centerPoint,
                  icon: labelIcon,
                  anchor: const Offset(0.5, 0.5),
                  zIndex: 2,
                ),
              );

            }
          }
        }
      }

      final initialCenter = _getInitialCenter(deviceList);

      if (!mounted) return;

      setState(() {
        markers = newMarkers;
        polygons = newPolygons;
        if (initialCenter != null) {
          center = initialCenter;
        }
      });

      _fitMapToBounds(newMarkers, newPolygons);
    } catch (e) {
      AppLog.log("Error: $e");
    }
  }

  Map<String, int> getStatusPercentage(
      double serialNumber, Map<String, dynamic>? liveMessage)
  {
    try {
      // 1. Safe extraction of the nested map and string
      if (liveMessage == null || liveMessage["cM"] == null) {
        return {"status": 0, "percentage": 0};
      }

      // Cast cM safely
      final dynamic cMData = liveMessage["cM"];
      if (cMData is! Map) return {"status": 0, "percentage": 0};

      final String? data = cMData["2402"]?.toString();

      if (data == null || data.isEmpty) {
        AppLog.log('data is empty or null');
        return {"status": 0, "percentage": 0};
      }

      final List<String> values = data.split(";");

      for (var value in values) {
        final List<String> parts = value.split(",");

        if (parts.length >= 3) {
          // 2. Convert string ID to double to ensure 13.010 == 13.01
          double? partId = double.tryParse(parts[0]);

          if (partId != null && partId == serialNumber) {
            return {
              "status": int.tryParse(parts[1]) ?? 0,
              "percentage": int.tryParse(parts[2]) ?? 0,
            };
          }
        }
      }

      AppLog.log('No match found for serialNumber');
      return {"status": 0, "percentage": 0};

    } catch (e, stacktrace) {
      AppLog.log("Error getting valve data: $e");
      AppLog.log("Stacktrace: $stacktrace");
      return {"status": 0, "percentage": 0};
    }
  }

  LatLng? _getInitialCenter(List deviceList) {
    // 1️⃣ First Valve Object
    for (var device in deviceList) {
      for (var obj in device["connectedObject"] ?? []) {
        if (obj["objectName"] != null &&
            obj["objectName"].toString().contains("Valve") &&
            obj["lat"] != null &&
            obj["long"] != null) {

          return LatLng(obj["lat"], obj["long"]);
        }
      }
    }

    // 2️⃣ First Available Object
    for (var device in deviceList) {
      for (var obj in device["connectedObject"] ?? []) {
        if (obj["lat"] != null && obj["long"] != null) {

          // AppLog.log("object:%:${LatLng(obj["lat"], obj["long"])}");
          return LatLng(obj["lat"], obj["long"]);
        }
      }
    }

    // 3️⃣ First Device Geography
    for (var device in deviceList) {
      final geo = device["geography"];
      if (geo != null &&
          geo["lat"] != null &&
          geo["long"] != null) {
        // AppLog.log("geography:%:${LatLng(geo["lat"], geo["long"])}");

        return LatLng(geo["lat"], geo["long"]);
      }
    }

    return null;
  }

  // ---------------- CREATE MARKER ----------------
  Marker _createMarker({
    required String id,
    required double lat,
    required double lng,
    required String title,
    required String type,
    int? status,
    int? percentage,
  }) {
    return Marker(
      markerId: MarkerId(id),
      position: LatLng(lat, lng),
      icon: _getIcon(type, status, percentage),
      infoWindow: InfoWindow(
        title: title,
        snippet: "Irrigation: ${percentage ?? 0}%",
      ),
    );
  }

  Color _getAreaColor(int? status, int? percentage) {
    int st = status ?? 0;
    int per = percentage ?? 0;

    if (per == 100) {
      return Colors.blue;
    } else if (st == 0 && per == 0) {
      return Colors.grey;
    } else if (st == 0 && per > 0) {
      return Colors.yellow;
    } else if (st == 1 && per <= 100) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  LatLng _getPolygonCenter(List<LatLng> points) {
    double lat = 0;
    double lng = 0;

    for (var p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }

    return LatLng(lat / points.length, lng / points.length);
  }

  Future<BitmapDescriptor> _getLabelIcon(String text,Color labelColor) async {
    // Use device pixel ratio for high-resolution markers on mobile
    final double ratio = ui.PlatformDispatcher.instance.views.isNotEmpty
        ? ui.PlatformDispatcher.instance.views.first.devicePixelRatio
        : 1.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 13 * ratio,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // Calculate dynamic width and height with padding
    final double width = textPainter.width + (16 * ratio);
    final double height = textPainter.height + (6 * ratio);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()..color = labelColor;
    final border = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 * ratio;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      Radius.circular(10 * ratio),
    );

    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, border);

    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  BitmapDescriptor _getIcon(String type, int? status, int? percentage) {

    int st = status ?? 0;
    int per = percentage ?? 0;

    if (type.contains("Valve")) {
      if (st == 1 && per == 100) {
        return markerIcons["blue"] ?? BitmapDescriptor.defaultMarker;
      }
      else if (st == 0 && per == 0) {
        return markerIcons["gray"] ?? BitmapDescriptor.defaultMarker;
      }
      else if (st == 0 && per > 0) {
        return markerIcons["yellow"] ?? BitmapDescriptor.defaultMarker;
      }
      else if (st == 1 && per <= 100) {
        return markerIcons["green"] ?? BitmapDescriptor.defaultMarker;
      }
      else {
        return markerIcons["gray"] ?? BitmapDescriptor.defaultMarker;
      }
    }

    if (type.contains("Pump")) {
      return markerIcons["pump"] ?? BitmapDescriptor.defaultMarker;
    }

    if (type.contains("Sensor")) {
      return markerIcons["sensor"] ?? BitmapDescriptor.defaultMarker;
    }

    if (type.contains("Filter")) {
      return markerIcons["filter"] ?? BitmapDescriptor.defaultMarker;
    }

    if (type.contains("fertilizer")) {
      return markerIcons["fert"] ?? BitmapDescriptor.defaultMarker;
    }

    if (type.contains("Injector")) {
      return markerIcons["injector"] ?? BitmapDescriptor.defaultMarker;
    }

    return markerIcons["blue"] ?? BitmapDescriptor.defaultMarker;
  }

  // ---------------- MAP CREATED ----------------

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Optional: re-fit when map is ready
    if (markers.isNotEmpty || polygons.isNotEmpty) {
      _fitMapToBounds(markers, polygons);
    }
  }



  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    // AppLog.log("build center:$center");
    final bool isAquaculture = [...AppConstants.aquacultureModelList].contains(widget.modelId);

    return Scaffold(
      appBar: (widget.isCheckDashboard || kIsWeb) ? null : AppBar(title: const Text(" Geography"),
        // automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _init();
            },
          ),
          if (!widget.isCheckDashboard)
            IconButton(
              icon: Icon(Icons.map_outlined),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => MapConnectionObject(userId: widget.userId, customerId: widget.customerId, controllerId: widget.controllerId, imeiNo: widget.imeiNo,modelId: widget.modelId,),
                ));
              },
              tooltip: 'Edit',
            ),
        ],
      ) ,

      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            onCameraMove: (CameraPosition position) {
              _currentZoom = position.zoom;
            },
            initialCameraPosition: CameraPosition(
              target: center,
              zoom: _currentZoom,
            ),
            markers: markers,
            polygons: polygons,
            onMapCreated: _onMapCreated,
          ),
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: Container(
              color: Colors.white.withOpacity(0.7),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        "Live sync: $_sentTime",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (kIsWeb)
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        await _init();
                      },
                    ),
                  if (kIsWeb)
                    if (!widget.isCheckDashboard)
                      IconButton(
                        icon: Icon(Icons.map_outlined,color: Colors.red,),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => MapConnectionObject(userId: widget.userId, customerId: widget.customerId, controllerId: widget.controllerId, imeiNo: widget.imeiNo,modelId: widget.modelId,),
                          ));
                        },
                        tooltip: 'Edit',
                      ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: buildValveStatusLegend(false),
          ),
        ],
      ),
    );
  }
  void _fitMapToBounds(Set<Marker> markers, Set<Polygon> polygons) {
    if (mapController == null) return;
    if (markers.isEmpty && polygons.isEmpty) return;

    List<LatLng> allPoints = [];

    // ✅ Add marker positions
    for (var m in markers) {
      allPoints.add(m.position);
    }

    // ✅ Add polygon points
    for (var p in polygons) {
      allPoints.addAll(p.points);
    }

    if (allPoints.isEmpty) return;

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // ✅ Run AFTER UI is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || mapController == null) return;

      try {
        mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      } catch (e) {
        debugPrint("Map fit error: $e");
      }
    });
  }

}