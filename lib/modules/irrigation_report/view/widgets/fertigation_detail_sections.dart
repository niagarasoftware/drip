import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';
import 'fertigation_channel_tile.dart';

class FertigationDetailSections extends StatelessWidget {
  final FertigationCardModel cardModel;

  const FertigationDetailSections({super.key, required this.cardModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. WATER & PRE/POST Sections
        LayoutBuilder(builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 500;
          if (isWide) {
            return Row(
              children: [
                Expanded(child: _buildWaterSection()),
                const SizedBox(width: 12),
                Expanded(child: _buildPrePostSection()),
              ],
            );
          } else {
            return Column(
              children: [
                _buildWaterSection(),
                const SizedBox(height: 12),
                _buildPrePostSection(),
              ],
            );
          }
        }),
        const SizedBox(height: 12),

        // 2. CENTRAL EC / pH Stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF4F4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Central EC', '${cardModel.centralEc} mS/cm'),
              Container(height: 20, width: 1, color: Colors.black26),
              _statItem('Central pH', cardModel.centralPh),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. FERTILIZER CHANNELS (Central C-CH1..8 and Local L-CH1..8)
        const Text(
          'Central Fertilizer Channels (C-CH1 to C-CH8)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF006573)),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          int crossAxisCount = 4;
          if (constraints.maxWidth < 400) {
            crossAxisCount = 1;
          } else if (constraints.maxWidth < 650) {
            crossAxisCount = 2;
          } else if (constraints.maxWidth < 900) {
            crossAxisCount = 3;
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cardModel.centralChannels.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              return FertigationChannelTile(channel: cardModel.centralChannels[index]);
            },
          );
        }),

        const SizedBox(height: 12),
        const Text(
          'Local Fertilizer Channels (L-CH1 to L-CH8)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF006573)),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          int crossAxisCount = 4;
          if (constraints.maxWidth < 400) {
            crossAxisCount = 1;
          } else if (constraints.maxWidth < 650) {
            crossAxisCount = 2;
          } else if (constraints.maxWidth < 900) {
            crossAxisCount = 3;
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cardModel.localChannels.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              return FertigationChannelTile(channel: cardModel.localChannels[index]);
            },
          );
        }),

        const Divider(height: 24, thickness: 1, color: Color(0xFFEDF4F4)),

        // 4. GENERAL (start/stop reason, times, progress bar)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start Time: ${cardModel.startTime}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                Text('Stop Time: ${cardModel.stopTime}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Start Reason: ${cardModel.startReason}', style: const TextStyle(fontSize: 12, color: Colors.black54))),
                Expanded(child: Text('Stop Reason: ${cardModel.stopReason}', style: const TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.end)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF006573))),
                Text(cardModel.progress, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006573))),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: cardModel.progressValue,
                backgroundColor: const Color(0xFFEDF4F4),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006573)),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaterSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WATER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006573))),
          const SizedBox(height: 4),
          _rowInfo('Method:', cardModel.waterMethod),
          _rowInfo('Planned:', cardModel.waterPlanned),
          _rowInfo('Actual:', cardModel.waterActual),
        ],
      ),
    );
  }

  Widget _buildPrePostSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRE / POST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006573))),
          const SizedBox(height: 4),
          _rowInfo('Method:', cardModel.preMethod),
          _rowInfo('Pre Time/Qty:', cardModel.preTimeQty),
          _rowInfo('Post Time/Qty:', cardModel.postTimeQty),
        ],
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF006573))),
      ],
    );
  }
}
