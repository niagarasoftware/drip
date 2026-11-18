import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../widgets/crop_advisory_web_sidebar.dart';
import 'package:oro_drip_irrigation/cropAdvisory/view/CropDetailsScreen.dart';
import 'package:oro_drip_irrigation/cropAdvisory/widgets/AppTextField.dart';
import 'package:oro_drip_irrigation/cropAdvisory/widgets/ContinueButton.dart';
import 'package:oro_drip_irrigation/cropAdvisory/widgets/ProgressWidget.dart';
import 'package:oro_drip_irrigation/cropAdvisory/widgets/SectionCard.dart';
import 'package:oro_drip_irrigation/cropAdvisory/view/map_picker_screen.dart';
import 'package:oro_drip_irrigation/cropAdvisory/service/location_service.dart';
import '../model/cropadvisory_model.dart';

class Cropinformationscreen extends StatefulWidget {
  const Cropinformationscreen({
    super.key,
    required this.userId,
    required this.cropId,
    required this.controllerId,
    required this.edit,
  });
  final int userId, controllerId, cropId;
  final bool edit;

  @override
  State<Cropinformationscreen> createState() => _CropinformationscreenState();
}

class _CropinformationscreenState extends State<Cropinformationscreen> {
  // --- Location related ---
  double? _latitude;
  double? _longitude;
  String _selectedAddress = '';
  final TextEditingController _locationController = TextEditingController();
  final LocationService _locationService = LocationService();

  // --- Other fields ---
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _farmNameController = TextEditingController();
  final CropAdvisoryModel _model = CropAdvisoryModel.instance;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if we are editing (data already in singleton)
    _areaController.text = _model.areaName ?? '';
    _selectedAddress = _model.address ?? '';
    _farmNameController.text = _model.farmName ?? '';
    if (_model.latitude != null && _model.longitude != null) {
      _latitude = double.tryParse(_model.latitude!);
      _longitude = double.tryParse(_model.longitude!);
      _locationController.text = '${_model.latitude}, ${_model.longitude}';
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _areaController.dispose();
    _farmNameController.dispose();
    super.dispose();
  }

  // Opens the full-screen map for manual selection
  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => MapPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          userId: widget.userId,
          controllerId: widget.controllerId,
          cropId: widget.cropId,
          edit: widget.edit,
        ),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationController.text = '$_latitude, $_longitude';
        _selectedAddress = result['address'] ?? _locationController.text;
      });
    }
  }

  // Uses device GPS directly (the suffix icon action)
  Future<void> _getCurrentLocationOnly() async {
    try {
      final position = await _locationService.getCurrentLocation();

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      String address = '';
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        // Build a readable address
        address = [
          pm.street,
          pm.locality,
          pm.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
      if (address.isEmpty) {
        address = '${position.latitude}, ${position.longitude}';
      }

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text = address;
        _selectedAddress = address;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = SafeArea(
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: kIsWeb ? 600 : double.infinity),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Let's get started",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Tell us a bit about you to set up your farm profile.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const ProgressWidget(current: 1),
                const SizedBox(height: 20),

                // ---------- Location Field ----------
                SectionCard(
                  title: 'Share Location',
                  icon: Icons.location_on_outlined,
                  child: GestureDetector(
                    onTap: _openMapPicker,
                    child: AbsorbPointer(
                      child: AppTextField(
                        controller: _locationController,
                        hint: 'Search Or Use Current Location',
                        readOnly: true,
                        suffix: GestureDetector(
                          onTap: _getCurrentLocationOnly,
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                    ),
                  ),
                ),

                // ---------- Area Field ----------
                SectionCard(
                  title: 'Area(acre/ hectare)',
                  icon: Icons.map_outlined,
                  child: AppTextField(
                    controller: _areaController,
                    hint: '10(acre)',
                    suffix: const Icon(Icons.keyboard_arrow_down),
                  ),
                ),

                // ---------- Plot / Farm ID ----------
                SectionCard(
                  title: 'Farm Name',
                  icon: Icons.edit,
                  child: AppTextField(
                    controller: _farmNameController,
                    hint: 'Enter The Plot Or Farm Name',
                  ),
                ),

                const SizedBox(height: 30),

                // ---------- Continue Button ----------
                CropContinueButton(
                  onTap: () {
                    if (_locationController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a location')),
                      );
                      return;
                    }

                    // Update singleton instance
                    _model.latitude = _latitude?.toString();
                    _model.longitude = _longitude?.toString();
                    _model.address = _selectedAddress;
                    _model.areaName = _areaController.text;
                    _model.farmName = _farmNameController.text;

                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => CropDetailsScreen(
                          userId: widget.userId,
                          controllerId: widget.controllerId,
                          cropId: widget.cropId,
                          edit: widget.edit,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Crop Advisory")),
      body: kIsWeb
          ? Row(
              children: [
                const CropAdvisoryWebSidebar(isSetup: true),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }
}
