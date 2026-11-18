import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/modules/PumpController/repository/lora_settings_repository.dart';
import 'package:oro_drip_irrigation/services/http_service.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import 'package:oro_drip_irrigation/utils/environment.dart';

import '../../../repository/repository.dart';

class GeneralScreen extends StatefulWidget {
  final int userId, controllerId, customerId;
  final String deviceId;
  const GeneralScreen({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.customerId,
    required this.deviceId,
  });

  @override
  State<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends State<GeneralScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController spreadFactorController = TextEditingController();
  final TextEditingController loraKeyController = TextEditingController();
  final LoraSettingsRepository loraSettingsRepository = LoraSettingsRepository(HttpService());

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchGeneralData();
  }

  Future<void> _fetchGeneralData() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> userdata = {
        'userId': widget.customerId,
        'controllerId': widget.controllerId,
      };
      final result = await loraSettingsRepository.getLoraSettings(userdata);
      final data = jsonDecode(result.body);

      if (result.statusCode == 200 && data['code'] == 200) {
        // print("loraFrequency :: ${data['loraFrequency']}");
        if (data['loraFrequency'] != null && data['loraFrequency'].isNotEmpty) {
          final splitData = data['loraFrequency'].toString().split(',');
          if (splitData.length >= 3) {
            frequencyController.text = splitData[0];
            spreadFactorController.text = splitData[1];
            loraKeyController.text = splitData[2];
          }
        } else {
          frequencyController.text = '866.0';
          spreadFactorController.text = '7';
          loraKeyController.text = '1';
        }
      } else {
        _showSnackBar('Failed to load LoRa settings');
      }
    } catch (e) {
      _showSnackBar('Error fetching settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLoraSettings(String payload) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> userData = {
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
        "loraFrequency": "${frequencyController.text},${spreadFactorController.text},${loraKeyController.text}",
        "modifyUser": widget.userId,
      };
      final Repository repository = Repository(HttpService());
      MqttService().topicToPublishAndItsMessage(payload, '${Environment.mqttPublishTopic}/${widget.deviceId}');
      final response = await loraSettingsRepository.updateLoraSettings(userData);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['code'] == 200) {
        _showSnackBar('Settings updated successfully', isSuccess: true);
        Map<String, dynamic> body = {
          "userId": widget.customerId,
          "controllerId": widget.controllerId,
          "hardware": payload,
          "messageStatus": "${payload.contains('frequency') ? 'LoRa Frequency' : 'LoRa Key'} updated successfully",
          "createUser": widget.userId
        };
        final result = await repository.sendManualOperationToServer(body);
        Navigator.of(context).pop();
      } else {
        _showSnackBar('Failed to update settings: ${data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showSnackBar('Error updating settings: $e');
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
            key: _formKey,
            child: Expanded(
              child: ListView(
                // crossAxisAlignment: CrossAxisAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  const SizedBox(height: 15),
                  _buildSectionCard(
                    title: 'LoRa Frequency Settings',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: frequencyController,
                              label: 'LoRa Frequency (MHz)',
                              hint: 'Enter frequency (e.g., 915.0)',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Frequency is required';
                                }
                                if (!_isValidFrequency(value)) {
                                  return 'Enter a valid frequency (100.0 - 999.9)';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              controller: spreadFactorController,
                              label: 'Spread Factor (SF)',
                              hint: 'Enter SF value (7-12)',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Spread Factor is required';
                                }
                                final sf = int.tryParse(value);
                                if (sf == null || sf < 7 || sf > 12) {
                                  return 'Enter a valid SF (7-12)';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildButtonRow(
                        onCancel: () => Navigator.of(context).pop(),
                        onSubmit: () => _updateLoraSettings(jsonEncode({'sentSms': 'frequency,${frequencyController.text},${spreadFactorController.text}'})),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSectionCard(
                    title: 'LoRa Key',
                    children: [
                      _buildTextField(
                        controller: loraKeyController,
                        label: 'LoRa Key',
                        hint: 'Enter LoRa Key',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'LoRa Key is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildButtonRow(
                        onCancel: () => Navigator.of(context).pop(),
                        onSubmit: () => _updateLoraSettings(jsonEncode({'sentSms': 'lorakey,${loraKeyController.text}'})),
                      ),
                    ],
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
      validator: validator,
    );
  }

  Widget _buildButtonRow({required VoidCallback onCancel, required VoidCallback onSubmit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Save'),
        ),
      ],
    );
  }

  bool _isValidFrequency(String freq) {
    final regex = RegExp(r'^\d{1,3}\.\d$');
    if (!regex.hasMatch(freq)) return false;
    final value = double.tryParse(freq);
    return value != null && value >= 100.0 && value <= 999.9;
  }

  @override
  void dispose() {
    frequencyController.dispose();
    spreadFactorController.dispose();
    loraKeyController.dispose();
    super.dispose();
  }
}