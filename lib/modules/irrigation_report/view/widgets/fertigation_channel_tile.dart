import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';

class FertigationChannelTile extends StatelessWidget {
  final FertigationChannelModel channel;

  const FertigationChannelTile({super.key, required this.channel});

  bool _isValidVal(String val) {
    final clean = val.trim().toLowerCase();
    if (clean.isEmpty || clean == '—' || clean == '-' || clean == 'null') {
      return false;
    }
    final numOnly = clean.replaceAll(RegExp(r'[^0-9.]'), '');
    final d = double.tryParse(numOnly);
    return d != null && d >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final bool isTimeMethod = channel.planned.contains(':');
    final String methodText = isTimeMethod ? 'Time' : 'Qty';

    final bool hasSensorQty = _isValidVal(channel.sensorQty);
    final bool hasActualQty = _isValidVal(channel.actualQty);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 55,
            child: Text(
              channel.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF203B3D),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$methodText · ${channel.planned} planned',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF637D7A),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                channel.actual,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF203B3D),
                ),
              ),
              if (hasActualQty && channel.actual != channel.actualQty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Qty: ${channel.actualQty}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF637D7A),
                    ),
                  ),
                ),
              if (hasSensorQty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Sensor Qty: ${channel.sensorQty}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF006573),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
