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
        child: Text('No Fertigation Records Found', style: TextStyle(color: Color(0xFF637D7A), fontSize: 14, fontWeight: FontWeight.w500)),
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
              // Sequence Header
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
                          'Program: ${card.programName} • Line: ${card.lineName} • Date: ${card.date}',
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

              // Compact sequence execution details blocks: WATER, FERTILIZER, PRE/POST, GENERAL, CENTRAL EC/pH
              FertigationDetailSections(cardModel: card),
            ],
          ),
        );
      },
    );
  }
}
