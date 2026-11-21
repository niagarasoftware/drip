import 'package:flutter/material.dart';
import '../../../services/bluetooth/hotspot_websocket_service.dart';
import '../../../utils/enums.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';

class HotspotConnectTile extends StatefulWidget {
  final CustomerScreenControllerViewModel vm;

  const HotspotConnectTile({super.key, required this.vm});

  @override
  State<HotspotConnectTile> createState() => _HotspotConnectTileState();
}

class _HotspotConnectTileState extends State<HotspotConnectTile> {
  late final HotspotWebSocketService _hotspot = widget.vm.hotspotService;
  late final TextEditingController _ssid;
  final TextEditingController _pass = TextEditingController();

  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();

    final deviceId = widget.vm
        .mySiteList.data[widget.vm.sIndex].master[widget.vm.mIndex].deviceId;

    // Assumed hotspot name: change it if your device uses another pattern.
    _ssid = TextEditingController(text: 'NIA_$deviceId');

    _hotspot.onConnectionError = (msg) {
      if (!mounted) return;
      setState(() => _message = msg);
    };

    _hotspot.onConnected = () {
      if (!mounted) return;
      setState(() => _message = null);
    };
  }

  Future<void> _connect() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final ssid = _ssid.text.trim();

      // Empty SSID = the user already joined the hotspot in Wi-Fi settings.
      if (ssid.isNotEmpty) {
        final joined = await _hotspot.joinHotspot(
          ssid,
          password: _pass.text.trim(),
        );
        if (!joined) return;
        await Future.delayed(const Duration(seconds: 2));
      }

      await _hotspot.connect(); // 192.168.4.1:81 by default
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _hotspot.onConnectionError = null;
    _hotspot.onConnected = null;
    _ssid.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BlueConnectionState>(
      valueListenable: _hotspot.connectionState,
      builder: (context, state, _) {
        final connected = state == BlueConnectionState.connected;
        final connecting = _busy || state == BlueConnectionState.connecting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Connect to the controller hotspot',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            if (!connected) ...[
              TextField(
                controller: _ssid,
                decoration: const InputDecoration(
                  labelText: 'Hotspot name (SSID)',
                  isDense: true,
                ),
              ),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Hotspot password',
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (connected)
                  const Icon(Icons.check_circle, color: Colors.green),
                if (connected) const SizedBox(width: 8),
                if (connecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: connected ? _hotspot.disconnect : _connect,
                    child: Text(connected ? 'Disconnect' : 'Connect'),
                  ),
              ],
            ),
            if (_message != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                ),
              ),
          ],
        );
      },
    );
  }
}