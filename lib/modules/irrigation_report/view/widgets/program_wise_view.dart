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
          child: Text('No Fertigation Records Found', style: TextStyle(color: Color(0xFF637D7A), fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      );
    }

    int running = cards.where((c) => c.status.toLowerCase().contains('run')).length;
    int skipped = cards.where((c) => c.status.toLowerCase().contains('skip')).length;
    int completed = cards.where((c) => c.status.toLowerCase().contains('complet')).length;
    int pending = cards.where((c) => c.status.toLowerCase().contains('pend')).length;

    return Container(
      color: const Color(0xFFF5F7F8),
      child: LayoutBuilder(
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
              ? width - 32
              : (width - 32 - (crossAxisCount - 1) * spacing) / crossAxisCount;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ONE Overall Fertigation Status Summary at the TOP
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF006573).withValues(alpha: 0.2), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Fertigation Status Summary',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006573),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF4F4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statusCountItem('Running', running, Colors.orange),
                            _statusCountItem('Skipped', skipped, Colors.blueGrey),
                            _statusCountItem('Completed', completed, Colors.green),
                            _statusCountItem('Pending', pending, Colors.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Wrap with natural content heights
                Wrap(
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusCountItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
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
