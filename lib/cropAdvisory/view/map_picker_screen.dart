import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:oro_drip_irrigation/cropAdvisory/service/location_service.dart';
import 'package:oro_drip_irrigation/cropAdvisory/view/CropDetailsScreen.dart';
import '../model/cropadvisory_model.dart';
import 'getUserInformationScreen.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final int? userId,cropId;
  final int? controllerId;
  final bool? edit;


  const MapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.userId,
    this.cropId,
    this.controllerId,
    this.edit,

  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  late LatLng _pickedLocation;
  String _address = "Fetching address...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use initial coordinates if provided, otherwise default
    _pickedLocation = LatLng(
      widget.initialLatitude ?? 37.7749,
      widget.initialLongitude ?? -122.4194,
    );
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      _updatePickedLocation(
        LatLng(position.latitude, position.longitude),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updatePickedLocation(LatLng location) async {
    setState(() {
      _pickedLocation = location;
      _isLoading = false;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(location));

    // Reverse geocode
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = [
            place.street,
            place.locality,
            place.administrativeArea,
            place.postalCode,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        });
      }
    } catch (_) {
      setState(() => _address = "Address not available");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraIdle() async {
    if (_mapController == null) return;
    LatLng center = await _mapController!.getVisibleRegion().then(
          (region) => LatLng(
        (region.northeast.latitude + region.southwest.latitude) / 2,
        (region.northeast.longitude + region.southwest.longitude) / 2,
      ),
    );
    _updatePickedLocation(center);
  }

  void _confirmLocation() {
    // Store selected location in the CropAdvisoryModel provider singleton
    CropAdvisoryModel.instance.updateLocation(
      lat: _pickedLocation.latitude.toString(),
      lng: _pickedLocation.longitude.toString(),
      addr: _address,
    );
    print("lat long: ${_pickedLocation.latitude} ${_pickedLocation.longitude} ");
    print("widget.cropId: ${widget.cropId}  ");
    print("widget.edit: ${widget.edit}");

    // Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>  Cropinformationscreen(userId: widget.userId!,controllerId: widget.controllerId!, cropId: widget.cropId!, edit: widget.edit ?? false,),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation,
              zoom: 15,
            ),
            onMapCreated: _onMapCreated,
            onCameraIdle: _onCameraIdle,
            markers: {
              Marker(
                markerId: const MarkerId('selected-location'),
                position: _pickedLocation,
                draggable: true,
                onDragEnd: (newPosition) {
                  _updatePickedLocation(newPosition);
                },
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  _address,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'current_location',
                  mini: true,
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'confirm',
                  onPressed: _confirmLocation,
                  label: const Text('Select this location'),
                  icon: const Icon(Icons.check),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
