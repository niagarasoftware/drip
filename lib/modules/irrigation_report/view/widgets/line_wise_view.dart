import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';
import 'fertigation_detail_sections.dart';

class LineWiseView extends StatelessWidget {
  final List<FertigationCardModel> cards;

  const LineWiseView({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Text('No Fertigation Records Found', style: TextStyle(color: Color(0xFF637D7A), fontSize: 14, fontWeight: FontWeight.w500)),
      );
    }

    // Group by lineName
    Map<String, List<FertigationCardModel>> grouped = {};
    for (var card in cards) {
      grouped.putIfAbsent(card.lineName, () => []).add(card);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        String lineName = grouped.keys.elementAt(index);
        List<FertigationCardModel> lineCards = grouped[lineName]!;

        int totalRecords = lineCards.length;
        Set<String> uniquePrograms = lineCards.map((c) => c.programName).toSet();

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
              // Line Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006573).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.settings_input_component_outlined, color: Color(0xFF006573), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lineName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006573),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006573),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalRecords Executions',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Summary Metrics (Programs count, active lines)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF4F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricItem('Associated Programs', '${uniquePrograms.length}', const Color(0xFF006573)),
                    Container(height: 20, width: 1, color: Colors.black26),
                    _metricItem('Total Water Records', '$totalRecords', const Color(0xFF006573)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Compact Program rows summary
              const Text(
                'Active Programs on this Line',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006573)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: uniquePrograms.map((prog) {
                  return Chip(
                    backgroundColor: const Color(0xFFEDF4F4),
                    labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF006573), fontWeight: FontWeight.bold),
                    label: Text(prog),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),

              const Divider(height: 24, thickness: 1, color: Color(0xFFEDF4F4)),

              // Detailed Fertilizer / Irrigation Info (Fully expanded)
              const Text(
                'Detailed Irrigation & Fertigation Logs',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF006573)),
              ),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lineCards.length,
                separatorBuilder: (context, _) => const Divider(height: 20, thickness: 1, color: Color(0xFFEDF4F4)),
                itemBuilder: (context, cardIndex) {
                  var card = lineCards[cardIndex];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF006573).withValues(alpha: 0.1), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${card.programName} - ${card.sequenceName}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF006573)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: card.statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                card.status,
                                style: TextStyle(color: card.statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FertigationDetailSections(cardModel: card),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
