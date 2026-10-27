import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../enums.dart';

class MqttStatusIndicator extends StatelessWidget {
  final bool compact;
  const MqttStatusIndicator({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, MQTTConnectionState>(
      selector: (_, p) => p.getAppConnectionState,
      builder: (_, state, __) {
        final online = state == MQTTConnectionState.connected;
        final color = online ? Colors.green : Colors.red;
        final label = online ? 'Online' : 'Offline';

        return Tooltip(
          message: 'MQTT $label',
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(online ? Icons.cloud_done : Icons.cloud_off,
                    size: 15, color: color),
                if (!compact) ...[
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}