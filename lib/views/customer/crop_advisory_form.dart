import 'dart:convert';

import 'package:flutter/material.dart';

import '../../repository/repository.dart';
import '../../services/http_service.dart';

class CropAdvisoryForm extends StatefulWidget {
  const CropAdvisoryForm({super.key, required this.customerId, required this.controllerId, required this.isNarrow});
  final int customerId, controllerId;
  final bool isNarrow;

  @override
  State<CropAdvisoryForm> createState() => _CropAdvisoryFormPageState();
}

class _CropAdvisoryFormPageState extends State<CropAdvisoryForm> {
  final _formKey = GlobalKey<FormState>();

  // Field variables
  String? cropName, variety, stage, soilType, irrigationType, location;
  String? rainfall, waterSource, fertilizerUsed, fertilizerFreq;
  DateTime? sowingDate;
  late TextEditingController _dateController, _cvController, _sphController, _faController, _lfuController, _ldController;
  double? soilPH, fieldArea;


  bool isEnabled = true;

  final Map<String, List<String>> crops = {
    "Crops": ["Cotton", "Sugarcane", "Maize", "Groundnut", "Wheat","Tomato", "Chilli", "Brinjal", "Okra",
      "Cabbage", "Cauliflower", "Cucumber", "Capsicum", "Pumpkin", "Bitter Gourd","Banana", "Pomegranate",
      "Papaya", "Grapes", "Mango", "Guava", "Sweet Lime", "Orange", "Watermelon", "Muskmelon","Turmeric",
      "Ginger", "Aloe Vera", "Ashwagandha", "Tulsi","Coconut", "Arecanut", "Coffee", "Tea", "Rubber"],
  };

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    _cvController = TextEditingController();
    _sphController = TextEditingController();
    _faController = TextEditingController();
    _lfuController = TextEditingController();
    _ldController = TextEditingController();
    getSiteData();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _cvController.dispose();
    _sphController.dispose();
    _faController.dispose();
    _ldController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.isNarrow? AppBar(
        title: const Text("Crop Advisory"),
        actions: [
          Row(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Tooltip(
                  message: isEnabled ? 'deactivate' : 'activate',
                  child: Switch(
                    value: isEnabled,
                    activeColor: Theme.of(context).primaryColorLight,
                    activeTrackColor: Colors.white70,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.black12,
                    onChanged: (value) {
                      setState(() {
                        isEnabled = value;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value ? "Crop Advisory activated" : "Crop Advisory deactivated",
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10)
            ],
          ),
        ],
      ):
      null,
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              _sectionTitle("🌱 Crop Details"),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _dropdown("Crop Name", crops['Crops']!, (val) => setState(() => cropName = val), selected: cropName),
                      _textField("Crop Variety", _cvController),
                      _dateField("Sowing Date", (val) {
                        debugPrint("Selected Date: $val");
                      }),
                      _dropdown("Stage of Crop", ["Germination", "Flowering", "Harvest"], (val) => setState(() => stage = val), selected: stage),
                    ],
                  ),
                ),
              ),

              _sectionTitle("🌍 Soil & Land Details"),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _dropdown("Soil Type", ["Loamy", "Clay", "Sandy", "Red"], (val) => setState(() => soilType = val), selected: soilType),
                      _textField("Soil pH (e.g. 6.5)", _sphController),
                      _textField("Field Area (acres)", _faController),
                    ],
                  ),
                ),
              ),

              _sectionTitle("💧 Irrigation & Water Details"),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _dropdown("Irrigation Type", ["Drip", "Sprinkler"], (val) => setState(() => irrigationType = val), selected: irrigationType),
                      _dropdown("Water Source", ["Bore-well", "Tank", "Canal", "River"], (val) => setState(() => waterSource = val), selected: waterSource),
                    ],
                  ),
                ),
              ),

              _sectionTitle("🌿 Fertilizer Info"),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _textField("Last Fertilizer Used", _lfuController),
                      _dropdown("Fertilizer Frequency", ["Daily","Weekly", "Biweekly", "Monthly"], (val) => setState(() => fertilizerFreq = val), selected: fertilizerFreq),
                    ],
                  ),
                ),
              ),

              _sectionTitle("📍 Field Location"),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _textField("Location / District", _ldController),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 18, right: 16),
                child: ElevatedButton(
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.all<Color>(Theme.of(context).primaryColorLight),
                    backgroundColor: WidgetStateProperty.all<Color>(Theme.of(context).primaryColorLight),
                  ),
                  onPressed: () {
                    // Send to backend or AI model here
                    if (_formKey.currentState!.validate()) {
                      final data = {
                        "cropName": cropName,
                        "cropVariety": _cvController.text,
                        "sowingDate": sowingDate?.toIso8601String(),
                        "stage": stage,
                        "soilType": soilType,
                        "soilPh": _sphController.text,
                        "fieldArea": _faController.text,
                        "irrigationType": irrigationType,
                        "waterSource": waterSource,
                        "lastFertilizerUsed": _lfuController.text,
                        "fertilizerFrequency": fertilizerFreq,
                        "location": _ldController.text,
                      };
                      updateSiteData(context, data);
                    }
                  },
                  child: const Text("Save the Details", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ========== UI Helpers ==========

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87)),
    );
  }

  Widget _textField(String label, TextEditingController controller, {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).primaryColorLight.withOpacity(0.1),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            borderSide: BorderSide(color: Colors.black12, width: 1.0),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            borderSide: BorderSide(color: Colors.black12, width: 1.0),
          ),
        ),
        validator: (value) => isRequired && (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, Function(String?) onChanged, {String? selected}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selected,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).primaryColorLight.withOpacity(0.1),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            borderSide: BorderSide(color: Colors.black12, width: 1.0),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            borderSide: BorderSide(color: Colors.black12, width: 1.0),
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Required' : null,
      ),
    );
  }

  Widget _dateField(String label, Function(DateTime) onDatePicked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              sowingDate = picked;
              _dateController.text = "${picked.toLocal()}".split(' ')[0];
            });
            onDatePicked(picked);
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: _dateController,
            decoration: InputDecoration(
              labelText: label,
              hintText: 'Select Date',
              filled: true,
              fillColor: Theme.of(context).primaryColorLight.withOpacity(0.1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                borderSide: BorderSide(color: Colors.black12),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                borderSide: BorderSide(color: Colors.black12),
              ),
            ),
            validator: (_) => sowingDate == null ? 'Select a date' : null,
          ),
        ),
      ),
    );
  }

  Future<void> getSiteData() async {
    try {
      Map<String, Object> body = {
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
      };
      final response = await Repository(HttpService()).fetchSiteAiAdvisoryData(body);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          final data = jsonData['data'];
          if (data != null || data.isNotEmpty) {
            cropName = data['cropName'];
            _cvController.text = data['cropVariety'];

            sowingDate = DateTime.tryParse(data['sowingDate'].split('T')[0]);
            if (sowingDate != null) {
              _dateController.text = "${sowingDate!.year}-${sowingDate!.month.toString().padLeft(2, '0')}-${sowingDate!.day.toString().padLeft(2, '0')}";
            }

            stage = data['stage'];
            soilType = data['soilType'];
            _sphController.text = data['soilPh'];
            _faController.text = data['fieldArea'];
            irrigationType = data['irrigationType'];
            waterSource = data['waterSource'];
            _lfuController.text = data['lastFertilizerUsed'];
            fertilizerFreq = data['fertilizerFrequency'];
            location = data['location'];
            _ldController.text = location!;

            setState(() {});
          } else {
            print("Data is empty");
          }
        }
      }
    } catch (error) {
      debugPrint(error as String?);
    }
  }

  Future<void> updateSiteData(BuildContext context, Map<String, String?> data) async {
    try {
      Map<String, Object> body = {
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
        "aiAdvisory": data,
        "modifyUser": widget.customerId,
      };
      final response = await Repository(HttpService()).updateSiteAiAdvisoryData(body);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonData["message"])),
          );
        }
      }
    } catch (error) {
      debugPrint(error as String?);
    }
  }

}