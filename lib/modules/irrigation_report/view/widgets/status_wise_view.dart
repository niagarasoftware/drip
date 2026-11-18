import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';
import 'fertigation_detail_sections.dart';

class StatusWiseView extends StatelessWidget {
  final List<FertigationCardModel> cards;

  const StatusWiseView({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Text('No Fertigation Records Found', style: TextStyle(color: Color(0xFF637D7A), fontSize: 14, fontWeight: FontWeight.w500)),
      );
    }

    List<FertigationCardModel> completedCards = cards.where((c) => c.status.toLowerCase().contains('complet')).toList();
    List<FertigationCardModel> runningCards = cards.where((c) => c.status.toLowerCase().contains('run')).toList();
    List<FertigationCardModel> skippedCards = cards.where((c) => c.status.toLowerCase().contains('skip')).toList();
    List<FertigationCardModel> stoppedCards = cards.where((c) => c.status.toLowerCase().contains('stop')).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // 4 Status Summary Counter Cards
        Row(
          children: [
            Expanded(child: _buildCounterCard('Completed', completedCards.length, Colors.green, Icons.check_circle_outline)),
            const SizedBox(width: 8),
            Expanded(child: _buildCounterCard('Running', runningCards.length, Colors.orange, Icons.run_circle_outlined)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildCounterCard('Skipped', skippedCards.length, Colors.blueGrey, Icons.skip_next_outlined)),
            const SizedBox(width: 8),
            Expanded(child: _buildCounterCard('Stopped', stoppedCards.length, Colors.red, Icons.stop_circle_outlined)),
          ],
        ),
        const SizedBox(height: 16),

        // Categorized Record Sections
        if (completedCards.isNotEmpty) ...[_buildCategoryHeader('Completed Records', Colors.green, completedCards.length),
          const SizedBox(height: 8),
          _buildCategoryList(completedCards),
          const SizedBox(height: 16),
        ],

        if (runningCards.isNotEmpty) ...[
          _buildCategoryHeader('Running Records', Colors.orange, runningCards.length),
          const SizedBox(height: 8),
          _buildCategoryList(runningCards),
          const SizedBox(height: 16),
        ],

        if (skippedCards.isNotEmpty) ...[
          _buildCategoryHeader('Skipped Records', Colors.blueGrey, skippedCards.length),
          const SizedBox(height: 8),
          _buildCategoryList(skippedCards),
          const SizedBox(height: 16),
        ],

        if (stoppedCards.isNotEmpty) ...[
          _buildCategoryHeader('Stopped Records', Colors.red, stoppedCards.length),
          const SizedBox(height: 8),
          _buildCategoryList(stoppedCards),
        ],
      ],
    );
  }

  Widget _buildCounterCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, Color color, int count) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildCategoryList(List<FertigationCardModel> categoryCards) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categoryCards.length,
      separatorBuilder: (context, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        var card = categoryCards[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF006573).withValues(alpha: 0.15), width: 1),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.programName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF006573)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${card.sequenceName} • ${card.lineName}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: card.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: card.statusColor, width: 1),
                    ),
                    child: Text(
                      card.status,
                      style: TextStyle(color: card.statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1, color: Color(0xFFEDF4F4)),
              FertigationDetailSections(cardModel: card),
            ],
          ),
        );
      },
    );
  }
}
