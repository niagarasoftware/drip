import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';
import 'fertigation_detail_sections.dart';

class ProgramWiseView extends StatelessWidget {
  final List<FertigationCardModel> cards;

  const ProgramWiseView({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width >= 1600) {
          crossAxisCount = 4;
        } else if (width >= 1200) {
          crossAxisCount = 3;
        } else if (width >= 768) {
          crossAxisCount = 2;
        }

        double spacing = 16.0;
        double cardWidth = crossAxisCount == 1
            ? width
            : (width - (crossAxisCount - 1) * spacing) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.start,
          children: cards.asMap().entries.map((entry) {
            int index = entry.key;
            var card = entry.value;
            return SizedBox(
              width: cardWidth,
              child: _buildCompactCard(context, card, index + 1),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCompactCard(BuildContext context, FertigationCardModel card, int sequenceNo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EEEE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      card.programName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF203B3D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.lineName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF637D7A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${card.sequenceName} • ${card.date}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF637D7A),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: card.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      card.status,
                      style: TextStyle(
                        color: card.statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1, color: Color(0xFFE7EEEE)),
          FertigationDetailSections(cardModel: card),
        ],
      ),
    );
  }
}
