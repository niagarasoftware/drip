import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';
import 'fertigation_detail_sections.dart';

class FertigationLogCard extends StatelessWidget {
  final FertigationCardModel cardModel;

  const FertigationLogCard({super.key, required this.cardModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF), // White
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFF006573).withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardModel.programName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006573), // Primary teal
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cardModel.sequenceName} • ${cardModel.lineName}',
                      style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cardModel.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardModel.statusColor, width: 1),
                ),
                child: Text(
                  cardModel.status,
                  style: TextStyle(
                    color: cardModel.statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFEDF4F4)),
          FertigationDetailSections(cardModel: cardModel),
        ],
      ),
    );
  }
}
