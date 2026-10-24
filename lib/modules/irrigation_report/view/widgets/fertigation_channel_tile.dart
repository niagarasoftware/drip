import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';

class FertigationChannelTile extends StatelessWidget {
  final FertigationChannelModel channel;

  const FertigationChannelTile({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 55,
            child: Text(
              channel.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF203B3D),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Time · ${channel.planned} planned',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF637D7A),
            ),
          ),
          const Spacer(),
          Text(
            channel.actual,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF203B3D),
            ),
          ),
        ],
      ),
    );
  }
}
