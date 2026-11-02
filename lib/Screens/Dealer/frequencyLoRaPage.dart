
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../StateManagement/mqtt_payload_provider.dart';
import '../../repository/repository.dart';
import '../../services/communication_service.dart';
import '../../services/http_service.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

class FrequencyPage extends StatefulWidget {
  final int userId;
  final int controllerId;
  final String deviceId;
  final bool plusTrue;
  final String loraValue;
  final String loara1Version;
  final String loara2Version;

  const FrequencyPage({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.deviceId,
    required this.plusTrue,
    required this.loraValue,
    required this.loara1Version,
    required this.loara2Version,
  });

  @override
  State<FrequencyPage> createState() => _FrequencyPageState();
}

class _FrequencyPageState extends State<FrequencyPage> {
  final frequency1Controller = TextEditingController();
  final frequency2Controller = TextEditingController();
  final sf1Controller = TextEditingController();
  final sf2Controller = TextEditingController();

  late final MqttPayloadProvider mqttPayloadProvider;

  String loRa1VersionState = '';
  String loRa2VersionState = '';

  bool _isLoading = false;
  bool _isSending = false;

  // A View request is waiting for a fresh MQTT response.
  final Set<int> _pendingViews = {};

  // Track the provider values present when View was requested.
  final Map<int, String> _viewBaselines = {};

  // Prevent unsolicited MQTT data from overwriting edited fields.
  bool _hasLocalEdits = false;
  bool _updatingControllers = false;

  Timer? _viewTimeout;

  @override
  void initState() {
    super.initState();

    mqttPayloadProvider = context.read<MqttPayloadProvider>();

    loRa1VersionState = widget.loara1Version;
    loRa2VersionState = widget.loara2Version;

    _setInitialValues(widget.loraValue);

    frequency1Controller.addListener(_onFieldEdited);
    frequency2Controller.addListener(_onFieldEdited);
    sf1Controller.addListener(_onFieldEdited);
    sf2Controller.addListener(_onFieldEdited);

    mqttPayloadProvider.addListener(_onMqttUpdated);
  }

  void _onFieldEdited() {
    if (!_updatingControllers) {
      _hasLocalEdits = true;
    }
  }

  void _setInitialValues(String value) {
    final parts = value.split(',');

    if (parts.length < 4) return;

    _setFrequencyFields(
      parts[0].trim(),
      parts[1].trim(),
      parts[2].trim(),
      parts[3].trim(),
    );
  }

  void _setFrequencyFields(
      String frequency1,
      String sf1,
      String frequency2,
      String sf2,
      ) {
    _updatingControllers = true;

    try {
      frequency1Controller.text = frequency1;
      sf1Controller.text = sf1;
      frequency2Controller.text = frequency2;
      sf2Controller.text = sf2;
    } finally {
      _updatingControllers = false;
    }
  }

  String _providerValue(int index) {
    return index == 1
        ? mqttPayloadProvider.Loara1verssion
        : mqttPayloadProvider.Loara2verssion;
  }

  void _onMqttUpdated() {
    if (!mounted || _pendingViews.isEmpty) return;

    for (final index in List<int>.from(_pendingViews)) {
      final value = _providerValue(index);

      if (value.isEmpty) continue;

      // Do not treat the previous provider value as a new response.
      if (value == _viewBaselines[index]) continue;

      final parts = value.split(',');

      if (parts.length < 3) continue;

      final version = parts[0].trim();
      final frequency = parts[1].trim();
      final sf = parts[2].trim();

      if (double.tryParse(frequency) == null ||
          int.tryParse(sf) == null) {
        continue;
      }

      _updatingControllers = true;

      try {
        setState(() {
          if (index == 1) {
            loRa1VersionState = version;
            frequency1Controller.text = frequency;
            sf1Controller.text = sf;
          } else {
            loRa2VersionState = version;
            frequency2Controller.text = frequency;
            sf2Controller.text = sf;
          }

          _pendingViews.remove(index);
          _viewBaselines.remove(index);
          _isLoading = _pendingViews.isNotEmpty;
          _hasLocalEdits = false;
        });
      } finally {
        _updatingControllers = false;
      }
    }

    if (_pendingViews.isEmpty) {
      _viewTimeout?.cancel();
    }
  }

  String formatNumber(String input) {
    final number = double.tryParse(input.trim());

    if (number == null) {
      throw const FormatException('Invalid frequency');
    }

    final result = (number * 10).round().toString().padLeft(4, '0');

    if (result.length != 4) {
      throw const FormatException('Frequency out of range');
    }

    return '${result.substring(0, 2)},${result.substring(2, 4)}';
  }

  bool _isValidFrequency(String value) {
    final frequency = double.tryParse(value.trim());

    return frequency != null &&
        frequency >= 0 &&
        frequency <= 999.9 &&
        RegExp(r'^\d{1,3}(\.\d)?$').hasMatch(value.trim());
  }

  bool _isValidSf(String value) {
    final sf = int.tryParse(value.trim());
    return sf != null && sf >= 7 && sf <= 12;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Invalid Input'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshFrequencyFromApi() async {
    try {
      final repository = Repository(HttpService());

      final response =
      await repository.getUserDeviceFirmwareDetails({
        'userId': widget.userId,
        'controllerId': widget.controllerId,
      });

      if (!mounted || response.statusCode != 200) return;

      final jsonData = jsonDecode(response.body);

      if (jsonData['code'] != 200 ||
          jsonData['data'] is! List) {
        return;
      }

      final devices = jsonData['data'] as List;

      for (final device in devices) {
        if (device['deviceId'].toString() != widget.deviceId) {
          continue;
        }

        final value = device['loraFrequency']?.toString() ?? '';
        final parts = value.split(',');

        if (parts.length >= 4 && mounted) {
          setState(() {
            _setFrequencyFields(
              parts[0].trim(),
              parts[1].trim(),
              parts[2].trim(),
              parts[3].trim(),
            );
            _hasLocalEdits = false;
          });
        }

        break;
      }
    } catch (e) {
      AppLog.log('Frequency API refresh error: $e');
    }
  }

  Future<void> _handleSend() async {
    if (_isSending) return;

    final freq1 = frequency1Controller.text.trim();
    final freq2 = frequency2Controller.text.trim();
    final sf1 = sf1Controller.text.trim();
    final sf2 = sf2Controller.text.trim();

    if (!_isValidFrequency(freq1) || !_isValidSf(sf1)) {
      _showErrorDialog(
        'Enter valid LoRa Frequency 1 and SF value (7-12).',
      );
      return;
    }

    if (widget.plusTrue &&
        (!_isValidFrequency(freq2) || !_isValidSf(sf2))) {
      _showErrorDialog(
        'Enter valid LoRa Frequency 2 and SF value (7-12).',
      );
      return;
    }

    final effectiveFreq2 = widget.plusTrue ? freq2 : '0.0';
    final effectiveSf2 = widget.plusTrue ? sf2 : '0';

    setState(() => _isSending = true);

    try {
      final payload = jsonEncode({
        '6500': {
          '6501':
          '${formatNumber(freq1)},$sf1,'
              '${formatNumber(effectiveFreq2)},$effectiveSf2',
        },
      });

      final communicationService =
      context.read<CommunicationService>();

      final result = await communicationService.sendCommand(
        payload: payload,
        serverMsg: 'LORA KEY UPDATE',
      );

      if (!mounted) return;

      final commandSent = result['http'] == true ||
          result['mqtt'] == true ||
          result['bluetooth'] == true;

      if (!commandSent) {
        _showSnackBar('Unable to send LoRa settings command');
        return;
      }

      final repository = Repository(HttpService());

      final body = {
        'userId': widget.userId,
        'controllerId': widget.controllerId,
        'loraFrequency':
        '$freq1,$sf1,$effectiveFreq2,$effectiveSf2',
        'modifyUser': widget.userId,
      };

      final response =
      await repository.updateUserDeviceFirmwareDetails(body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['code'] == 200) {
          await _refreshFrequencyFromApi();

          if (!mounted) return;

          _showSnackBar(
            data['message']?.toString() ??
                'LoRa settings updated successfully',
          );
        } else {
          _showSnackBar(
            data['message']?.toString() ??
                'Failed to save LoRa settings',
          );
        }
      } else {
        _showSnackBar('Failed to save LoRa settings');
      }
    } catch (e) {
      AppLog.log('LoRa send error: $e');
      _showSnackBar('Error sending LoRa settings');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _handleView(int loraIndex) async {
    if (_isLoading || _isSending) return;

    final command = loraIndex == 1 ? '29' : '30';

    // Capture the old value before requesting new device data.
    _viewBaselines[loraIndex] = _providerValue(loraIndex);

    setState(() {
      _pendingViews.add(loraIndex);
      _isLoading = true;
    });

    try {
      final payload = jsonEncode({
        '5700': {'5701': command},
      });

      final communicationService =
      context.read<CommunicationService>();

      final result = await communicationService.sendCommand(
        payload: payload,
        serverMsg: 'LORA KEY View',
      );

      print("result:$result");

      if (!mounted) return;

      print("result:$result");


      final commandSent = result['http'] == true ||
          result['mqtt'] == true ||
          result['bluetooth'] == true;

      if (!commandSent) {
        setState(() {
          _pendingViews.remove(loraIndex);
          _viewBaselines.remove(loraIndex);
          _isLoading = _pendingViews.isNotEmpty;
        });

        _showSnackBar('Unable to request LoRa settings');
        return;
      }

      // The provider listener updates the UI when data changes.
      // Timeout only stops the loading indicator.
      _viewTimeout?.cancel();

      _viewTimeout = Timer(const Duration(seconds: 12), () {
        if (!mounted || !_pendingViews.contains(loraIndex)) {
          return;
        }

        setState(() {
          _pendingViews.remove(loraIndex);
          _viewBaselines.remove(loraIndex);
          _isLoading = _pendingViews.isNotEmpty;
        });

        _showSnackBar('LoRa response timeout. Please try View again.');
      });
    } catch (e) {
      AppLog.log('LoRa View error: $e');

      if (mounted) {
        setState(() {
          _pendingViews.remove(loraIndex);
          _viewBaselines.remove(loraIndex);
          _isLoading = _pendingViews.isNotEmpty;
        });

        _showSnackBar('Unable to read LoRa settings');
      }
    }
  }

  Widget _buildCard({
    required String title,
    required TextEditingController freqCtrl,
    required TextEditingController sfCtrl,
    required int loraIndex,
  }) {
    final version = loraIndex == 1
        ? loRa1VersionState
        : loRa2VersionState;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: freqCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,3}(\.\d?)?$'),
                ),
              ],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.wifi_tethering),
                labelText: 'LoRa Frequency (000.0)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sfCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.settings_input_antenna),
                labelText: 'SF Value (7-12)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Device Version: '
                        '${version.isEmpty ? "--" : version}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: (_isLoading || _isSending)
                      ? null
                      : () => _handleView(loraIndex),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('View'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final contentWidth =
    screenWidth > 700 ? 650.0 : screenWidth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LoRa Frequency Settings'),
        actions: [
          IconButton(
            tooltip: 'Refresh saved frequency',
            onPressed: (_isLoading || _isSending)
                ? null
                : _refreshFrequencyFromApi,
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: contentWidth,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCard(
                      title: 'Frequency 1 Settings',
                      freqCtrl: frequency1Controller,
                      sfCtrl: sf1Controller,
                      loraIndex: 1,
                    ),
                    if (widget.plusTrue) ...[
                      const SizedBox(height: 16),
                      _buildCard(
                        title: 'Frequency 2 Settings',
                        freqCtrl: frequency2Controller,
                        sfCtrl: sf2Controller,
                        loraIndex: 2,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSending
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                            _isSending || _isLoading
                                ? null
                                : _handleSend,
                            child: Text(
                              _isSending ? 'Sending...' : 'Send',style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading || _isSending)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _viewTimeout?.cancel();

    mqttPayloadProvider.removeListener(_onMqttUpdated);

    frequency1Controller.removeListener(_onFieldEdited);
    frequency2Controller.removeListener(_onFieldEdited);
    sf1Controller.removeListener(_onFieldEdited);
    sf2Controller.removeListener(_onFieldEdited);

    frequency1Controller.dispose();
    frequency2Controller.dispose();
    sf1Controller.dispose();
    sf2Controller.dispose();

    super.dispose();
  }
}
