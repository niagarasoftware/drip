import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';
import 'fertigation_detail_sections.dart';

class ProgramWiseView extends StatelessWidget {
  final List<FertigationCardModel> cards;

  const ProgramWiseView({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Container(
        color: const Color(0xFFF5F7F8),
        child: const Center(
          child: Text('No fertigation records available', style: TextStyle(color: Color(0xFF637D7A))),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F7F8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          int crossAxisCount = 1;
          if (width >= 1200) {
            crossAxisCount = 3;
          } else if (width >= 768) {
            crossAxisCount = 2;
          }

          if (crossAxisCount == 1) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cards.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildCompactCard(context, cards[index], index + 1);
              },
            );
          } else {
            double spacing = 16.0;
            double cardWidth = (width - 32 - (crossAxisCount - 1) * spacing) / crossAxisCount;
            if (cardWidth > 420) cardWidth = 420;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Wrap(
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
              ),
            );
          }
        },
      ),
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
        children: [
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 4),
                  Text(
                    'Seq: #$sequenceNo',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF637D7A),
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
