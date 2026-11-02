import 'package:flutter/material.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';


class BluetoothScanTile extends StatefulWidget {
  final CustomerScreenControllerViewModel vm;

  const BluetoothScanTile({super.key, required this.vm});

  @override
  State<BluetoothScanTile> createState() => _BluetoothScanTileState();
}

enum _MessageType { info, error, warning }

class _BluetoothScanTileState extends State<BluetoothScanTile>
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

    // Stop scan when device is found
    widget.vm.bluetoothClassicService.onDeviceFound = stopScan;

    // Scan finished with nothing found
    widget.vm.bluetoothClassicService.onNoDeviceFound = () {
      if (!mounted) return;
      _showMessage(
        "No nearby device found. Please move closer to the device and try again.",
        _MessageType.warning,
      );
    };

    // Connection / scan failures
    widget.vm.bluetoothClassicService.onConnectionError = (message) {
      if (!mounted) return;
      _showMessage(_friendlyError(message), _MessageType.error);
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

  String _friendlyError(String raw) {
    if (raw.toLowerCase().contains('permission')) {
      return "Bluetooth permission is required. Please enable it in app settings.";
    }
    if (raw.toLowerCase().contains('disconnected')) {
      return "Connection dropped unexpectedly. Please move closer to the device and try again.";
    }
    if (raw.toLowerCase().contains('timeout')) {
      return "Connection timed out. Please make sure the device is powered on and nearby.";
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
          .mySiteList.data[widget.vm.sIndex].master[widget.vm.mIndex].deviceId;
      debugPrint("deviceId : $deviceId");
      await widget.vm.bluetoothClassicService.scanDevices(deviceId);
    } catch (e) {
      debugPrint("Classic scan error: $e");
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
    widget.vm.bluetoothClassicService.onDeviceFound = null;
    widget.vm.bluetoothClassicService.onNoDeviceFound = null;
    widget.vm.bluetoothClassicService.onConnectionError = null;
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
          child: statusMessage == null
              ? const SizedBox.shrink()
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

/*
class BluetoothScanTile extends StatefulWidget {
  final CustomerScreenControllerViewModel vm;

  const BluetoothScanTile({super.key, required this.vm});

  @override
  State<BluetoothScanTile> createState() => _BluetoothScanTileState();
}

class _BluetoothScanTileState extends State<BluetoothScanTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool isScanning = false;

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

    // Stop scan when device is found
    widget.vm.bluetoothClassicService.onDeviceFound = stopScan;
  }

  Future<void> startScan() async {
    if (isScanning) return;

    setState(() => isScanning = true);
    _controller.repeat();

    // Use try/finally to ensure scan stops even if an error occurs
    try {
      final deviceId = widget.vm
          .mySiteList.data[widget.vm.sIndex].master[widget.vm.mIndex].deviceId;
      print("deviceId : ${deviceId}");
      await widget.vm.bluetoothClassicService.scanDevices(deviceId);
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
    widget.vm.bluetoothClassicService.onDeviceFound = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("ble working");
    return ListTile(
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
    );
  }
}*/
