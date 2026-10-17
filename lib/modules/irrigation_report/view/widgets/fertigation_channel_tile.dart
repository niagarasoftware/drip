import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';

class FertigationChannelTile extends StatelessWidget {
  final FertigationChannelModel channel;

  const FertigationChannelTile({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4F4), // Section background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF006573).withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                channel.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF006573), // Primary teal
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: channel.isCentral ? const Color(0xFF006573) : Colors.teal.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  channel.isCentral ? 'Central' : 'Local',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Planned:', style: TextStyle(fontSize: 11, color: Colors.black54)),
              Text(channel.planned, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Actual:', style: TextStyle(fontSize: 11, color: Colors.black54)),
              Text(channel.actual, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}
