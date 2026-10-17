import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';
import 'fertigation_detail_sections.dart';

class ProgramWiseView extends StatelessWidget {
  final List<FertigationCardModel> cards;

  const ProgramWiseView({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Text('No fertigation records available', style: TextStyle(color: Colors.black54)),
      );
    }

    // Group cards by programName
    Map<String, List<FertigationCardModel>> grouped = {};
    for (var card in cards) {
      grouped.putIfAbsent(card.programName, () => []).add(card);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        String programName = grouped.keys.elementAt(index);
        List<FertigationCardModel> programCards = grouped[programName]!;

        int totalSequences = programCards.length;
        int completedCount = programCards.where((c) => c.status.toLowerCase().contains('complet')).length;
        int runningCount = programCards.where((c) => c.status.toLowerCase().contains('run')).length;
        int skippedCount = programCards.where((c) => c.status.toLowerCase().contains('skip')).length;
        int stoppedCount = programCards.where((c) => c.status.toLowerCase().contains('stop')).length;

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
              // Program Summary Header
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
                          child: const Icon(Icons.assessment_outlined, color: Color(0xFF006573), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            programName,
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
                      '$totalSequences Sequences',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status Summary Badges & Metrics
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF4F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricItem('Completed', '$completedCount', Colors.green),
                    _metricItem('Running', '$runningCount', Colors.orange),
                    _metricItem('Skipped', '$skippedCount', Colors.blueGrey),
                    _metricItem('Stopped', '$stoppedCount', Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Sequence Progress Indicators (e.g. [3.9 ✓])
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: programCards.map((card) {
                  bool isCompleted = card.status.toLowerCase().contains('complet');
                  Color badgeColor = isCompleted ? Colors.green : card.statusColor;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.sequenceName,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isCompleted ? Icons.check : Icons.circle,
                          size: 12,
                          color: badgeColor,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 24, thickness: 1, color: Color(0xFFEDF4F4)),

              // Full Sequence Details (Fully expanded by default)
              const Text(
                'Sequence Details & Fertigation Logs',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF006573)),
              ),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: programCards.length,
                separatorBuilder: (context, _) => const Divider(height: 20, thickness: 1, color: Color(0xFFEDF4F4)),
                itemBuilder: (context, seqIndex) {
                  var card = programCards[seqIndex];
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
                              '${card.sequenceName} (${card.lineName})',
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
