import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../StateManagement/mqtt_payload_provider.dart';
import 'googlemap_model.dart';

class MapScreenConnectedObjects extends StatefulWidget {
  const MapScreenConnectedObjects({Key? key, required this.selectindex}) : super(key: key);

  final int selectindex;

  @override
  _MapScreenConnectedObjectsState createState() => _MapScreenConnectedObjectsState();
}

class _MapScreenConnectedObjectsState extends State<MapScreenConnectedObjects> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  Set<Marker> _markers = {};
  LatLng? _selectedPosition;
  ConnectedObject? _selectedConnectedObject;

  late MqttPayloadProvider mqttPayloadProvider;

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectedObjects = _getConnectedObjectsForSelectedDevice();

      if (connectedObjects.isNotEmpty) {
        setState(() {
          _selectedConnectedObject = connectedObjects.first;

          if (_selectedConnectedObject!.lat != null && _selectedConnectedObject!.long != null) {
            _selectedPosition = LatLng(_selectedConnectedObject!.lat!, _selectedConnectedObject!.long!);
            _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selectedPosition!, 15));
          }
        });
      }

      _addConnectedObjectMarkers();
    });
  }

  List<ConnectedObject> _getConnectedObjectsForSelectedDevice() {
    final deviceList = mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];

    if (widget.selectindex >= 0 && widget.selectindex < deviceList.length) {
      return deviceList[widget.selectindex].connectedObject?.cast<ConnectedObject>() ?? [];
    }

    return [];
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _addConnectedObjectMarkers() {
    final connectedObjects = _getConnectedObjectsForSelectedDevice();
    Set<Marker> markers = {};

    for (var obj in connectedObjects) {
      if (obj.lat != null && obj.long != null) {
        final position = LatLng(obj.lat!, obj.long!);
        final isSelected = obj.sNo == _selectedConnectedObject?.sNo;

        markers.add(
          Marker(
            markerId: MarkerId('${obj.sNo}'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isSelected
                  ? BitmapDescriptor.hueAzure
                  : getMarkerHueByStatus(obj.status),

            ),
            infoWindow: InfoWindow(
              title: obj.name ?? 'Object',
              snippet: 'Lat: ${obj.lat}, Long: ${obj.long}',
              onTap: () {
                setState(() {
                  _selectedConnectedObject = obj;
                  _selectedPosition = position;
                });
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
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
  double getMarkerHueByStatus(int? status) {
     switch (status) {
      case 1:
        return BitmapDescriptor.hueGreen;
      case 2:
        return BitmapDescriptor.hueBlue;
      case 3:
        return BitmapDescriptor.hueRed;
      case 0:
      default:
        return 210.0; // Default or unknown status
    }
  }
  void _updateMarker(double lat, double long) {
    if (_selectedConnectedObject == null) return;

    setState(() {
      _selectedConnectedObject!.lat = lat;
      _selectedConnectedObject!.long = long;
      _selectedPosition = LatLng(lat, long);
    });

    mqttPayloadProvider.notifyListeners();
    _addConnectedObjectMarkers();
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selectedPosition!, 15));
  }

  void _searchLocation() {
    try {
      final input = _searchController.text.trim();
      final extracted = extractCoordinates(input);
      final coords = extracted.split(',');

      if (coords.length == 2) {
        final lat = double.parse(coords[0].trim());
        final long = double.parse(coords[1].trim());
        _updateMarker(lat, long);
      } else {
        throw Exception('Invalid coordinate format');
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter coordinates as "lat, long" (e.g., 11.1326952, 76.9767822)'),
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

  @override
  Widget build(BuildContext context) {
    final connectedObjects = _getConnectedObjectsForSelectedDevice();

    return Scaffold(
      appBar: AppBar(title: const Text('Set Connected Object Locations')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<ConnectedObject>(
              value: _selectedConnectedObject,
              hint: const Text('Select Connected Object'),
              onChanged: (ConnectedObject? obj) {
                if (obj != null) {
                  setState(() {
                    _selectedConnectedObject = obj;
                    _selectedPosition = obj.lat != null && obj.long != null
                        ? LatLng(obj.lat!, obj.long!)
                        : null;
                  });

                  if (_selectedPosition != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_selectedPosition!, 15),
                    );
                  }

                  _addConnectedObjectMarkers();
                }
              },
              isExpanded: true,
              items: connectedObjects.map((obj) {
                final lat = obj.lat?.toStringAsFixed(5) ?? 'N/A';
                final long = obj.long?.toStringAsFixed(5) ?? 'N/A';
                return DropdownMenuItem<ConnectedObject>(
                  value: obj,
                  child: Text('${obj.name ?? "Object"} (Lat: $lat, Long: $long)'),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search Area (e.g., 11.1326952, 76.9767822)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _searchLocation,
                  child: const Text('Search', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              mapType: MapType.hybrid,
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(target: LatLng(0, 0), zoom: 2),
              markers: _markers,
              onTap: (LatLng latLng) {
                _updateMarker(latLng.latitude, latLng.longitude);
              },
            ),
          ),
        ],
      ),
    );
  }
}
