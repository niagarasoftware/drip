import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';
import 'fertigation_detail_sections.dart';

class SequenceWiseView extends StatelessWidget {
  final List<FertigationCardModel> cards;

  const SequenceWiseView({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Text('No sequence records available', style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        var card = cards[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF006573).withValues(alpha: 0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.sequenceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006573),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Program: ${card.programName} • Line: ${card.lineName}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: card.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: card.statusColor, width: 1),
                    ),
                    child: Text(
                      card.status,
                      style: TextStyle(color: card.statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1, color: Color(0xFFEDF4F4)),

              // Vertical Timeline Stages
              const Text(
                'Execution Timeline Stages',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF006573)),
              ),
              const SizedBox(height: 10),

              _buildTimelineStage(
                title: 'Started',
                subtitle: 'Time: ${card.startTime} | Reason: ${card.startReason}',
                icon: Icons.play_arrow_rounded,
                isCompleted: true,
                isFirst: true,
              ),
              _buildTimelineStage(
                title: 'Pre-Irrigation',
                subtitle: 'Method: ${card.preMethod} | Duration/Qty: ${card.preTimeQty}',
                icon: Icons.hourglass_top_rounded,
                isCompleted: card.preTimeQty != '0m' && card.preMethod != 'None',
              ),
              _buildTimelineStage(
                title: 'Water Irrigation',
                subtitle: 'Planned: ${card.waterPlanned} | Actual: ${card.waterActual} (${card.waterMethod})',
                icon: Icons.water_drop_outlined,
                isCompleted: true,
              ),
              _buildTimelineStage(
                title: 'Fertigation Execution',
                subtitle: 'Central EC: ${card.centralEc} mS/cm | pH: ${card.centralPh} | Progress: ${card.progress}',
                icon: Icons.science_outlined,
                isCompleted: card.progressValue > 0,
              ),
              _buildTimelineStage(
                title: 'Post-Irrigation',
                subtitle: 'Duration/Qty: ${card.postTimeQty}',
                icon: Icons.hourglass_bottom_rounded,
                isCompleted: card.postTimeQty != '0m',
              ),
              _buildTimelineStage(
                title: card.status,
                subtitle: 'Stop Time: ${card.stopTime} | Reason: ${card.stopReason}',
                icon: card.status.toLowerCase().contains('complet') ? Icons.check_circle_outline : Icons.stop_circle_outlined,
                isCompleted: true,
                isLast: true,
              ),

              const Divider(height: 24, thickness: 1, color: Color(0xFFEDF4F4)),

              // Full Details
              FertigationDetailSections(cardModel: card),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineStage({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
  }) {
    Color color = isCompleted ? const Color(0xFF006573) : Colors.grey;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
