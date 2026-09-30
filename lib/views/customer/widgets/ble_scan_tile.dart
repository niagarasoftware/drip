import 'package:flutter/material.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';

class BleScanTile extends StatefulWidget {
  final CustomerScreenControllerViewModel vm;

  const BleScanTile({super.key, required this.vm});

  @override
  State<BleScanTile> createState() => _BleScanTileState();
}

enum _MessageType { info, error, warning }

class _BleScanTileState extends State<BleScanTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool isScanning = false;

  String? statusMessage;
  _MessageType _messageType = _MessageType.info;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _rotationAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    // ---- Scan found a device ----
    widget.vm.bluetoothBleService.onDeviceFound = stopScan;

    // ---- Scan finished with nothing found ----
    widget.vm.bluetoothBleService.onNoDeviceFound = () {
      if (!mounted) return;
      _showMessage(
        "No nearby device found. Please move closer to the device and try again.",
        _MessageType.warning,
      );
    };

    // ---- Connection failed ----
    widget.vm.bluetoothBleService.onConnectionError = (message) {
      if (!mounted) return;
      _showMessage(_friendlyConnectionError(message), _MessageType.error);
    };

    // ---- Pairing / bonding instructions required ----
    widget.vm.bluetoothBleService.onPairingRequired = (message) {
      if (!mounted) return;
      _showMessage(
        "This device needs to be forgotten and reconnected. "
            "Go to Bluetooth settings, forget the device, then try connecting again.",
        _MessageType.warning,
      );
    };

    // ---- Bluetooth turned off / unavailable ----
    widget.vm.bluetoothBleService.onBluetoothDisabled = (message) {
      if (!mounted) return;
      stopScan(); // stop the spinning icon since scanning can't continue
      _showMessage(message, _MessageType.warning);
    };

    // ---- Wi-Fi credential update result ----
    widget.vm.bluetoothBleService.onWifiUpdateResult = (message, success) {
      if (!mounted) return;
      _showMessage(message, success ? _MessageType.info : _MessageType.error);
    };

  }

  void _showMessage(String message, _MessageType type, {int seconds = 5}) {
    setState(() {
      statusMessage = message;
      _messageType = type;
    });
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted && statusMessage == message) {
        setState(() => statusMessage = null);
      }
    });
  }

  // Translate raw exceptions into customer-friendly text
  String _friendlyConnectionError(String raw) {
    if (raw.contains('requestMtu') || raw.contains('Device is disconnected')) {
      return "Connection dropped unexpectedly. Please move closer to the device and try again.";
    }
    if (raw.toLowerCase().contains('timeout')) {
      return "Connection timed out. Please make sure the device is powered on and nearby.";
    }
    if (raw.contains('AUTHENTICATION_FAILURE') || raw.contains('status=5')) {
      return "Pairing issue detected. Try forgetting the device in Bluetooth settings and reconnecting.";
    }
    if (raw.contains('service not found') || raw.contains('Custom service')) {
      return "Couldn't detect the device configuration. Please ensure it's in configuration mode.";
    }
    return "Could not connect to the device. Please try again.";
  }

  Future<void> startScan() async {
    if (isScanning) return;

    setState(() {
      isScanning = true;
      statusMessage = null; // clear old message on new attempt
    });
    _controller.repeat();

    try {
      final deviceId = widget.vm
          .mySiteList.data[widget.vm.sIndex]
          .master[widget.vm.mIndex]
          .deviceId;

      debugPrint("BLE deviceId: $deviceId");
      await widget.vm.bluetoothBleService.startScan(deviceId: deviceId);
    } catch (e) {
      debugPrint("BLE scan error: $e");
      if (mounted) {
        _showMessage("Bluetooth scan failed. Please try again.", _MessageType.error);
      }
    } finally {
      stopScan();
    }
  }

  void stopScan() {
    if (!mounted) return;
    setState(() => isScanning = false);
    _controller.stop();
  }

  @override
  void dispose() {
    widget.vm.bluetoothBleService.onDeviceFound = null;
    widget.vm.bluetoothBleService.onNoDeviceFound = null;
    widget.vm.bluetoothBleService.onConnectionError = null;
    widget.vm.bluetoothBleService.onPairingRequired = null;
    widget.vm.bluetoothBleService.onWifiUpdateResult = null; // 👈 add this
    _controller.dispose();
    super.dispose();
  }

  ({Color bg, Color border, Color text, IconData icon}) _styleFor(_MessageType type) {
    switch (type) {
      case _MessageType.error:
        return (
        bg: Colors.red.shade50,
        border: Colors.red.shade200,
        text: Colors.red.shade900,
        icon: Icons.error_outline,
        );
      case _MessageType.warning:
        return (
        bg: Colors.orange.shade50,
        border: Colors.orange.shade200,
        text: Colors.orange.shade900,
        icon: Icons.info_outline,
        );
      case _MessageType.info:
        return (
        bg: Colors.blue.shade50,
        border: Colors.blue.shade200,
        text: Colors.blue.shade900,
        icon: Icons.info_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(_messageType);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            "Scan for Bluetooth Devices and Connect",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          trailing: RotationTransition(
            turns: _rotationAnimation,
            child: IconButton(
              icon: Icon(
                Icons.refresh_outlined,
                color: isScanning ? Colors.blue : Colors.black,
              ),
              onPressed: startScan,
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: statusMessage == null ? const SizedBox.shrink()
              : Container(
            key: ValueKey(statusMessage),
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: style.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(style.icon, size: 18, color: style.text),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusMessage!,
                    style: TextStyle(color: style.text, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}