import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';
import 'fertigation_channel_tile.dart';

class FertigationDetailSections extends StatelessWidget {
  final FertigationCardModel cardModel;

  const FertigationDetailSections({super.key, required this.cardModel});

  @override
  Widget build(BuildContext context) {
    bool hasChannels = cardModel.centralChannels.isNotEmpty || cardModel.localChannels.isNotEmpty;

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

        // 2A. CENTRAL EC / pH Table
        _buildEcPhTable(
          'CENTRAL EC / pH',
          cardModel.centralEcSet,
          cardModel.centralEcMin,
          cardModel.centralEcMax,
          cardModel.centralEcAvg,
          cardModel.centralPhSet,
          cardModel.centralPhMin,
          cardModel.centralPhMax,
          cardModel.centralPhAvg,
        ),
        const SizedBox(height: 12),

        // 2B. LOCAL EC / pH Table
        _buildEcPhTable(
          'LOCAL EC / pH',
          cardModel.localEcSet,
          cardModel.localEcMin,
          cardModel.localEcMax,
          cardModel.localEcAvg,
          cardModel.localPhSet,
          cardModel.localPhMin,
          cardModel.localPhMax,
          cardModel.localPhAvg,
        ),
        const SizedBox(height: 16),

        // 3. CHANNELS
        const Text(
          'CHANNELS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006573)),
        ),
        const SizedBox(height: 6),
        if (!hasChannels)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Text('No fertilizer data / Fertigation OFF', style: TextStyle(fontSize: 11, color: Color(0xFF637D7A))),
          )
        else ...[
          ...cardModel.centralChannels.map((c) => FertigationChannelTile(channel: c)),
          ...cardModel.localChannels.map((c) => FertigationChannelTile(channel: c)),
        ],

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

  Widget _buildEcPhTable(
    String title,
    String ecSet,
    String ecMin,
    String ecMax,
    String ecAvg,
    String phSet,
    String phMin,
    String phMax,
    String phAvg,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006573))),
          const SizedBox(height: 6),
          Row(
            children: const [
              SizedBox(width: 35, child: Text('', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54))),
              Expanded(child: Text('Set', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54))),
              Expanded(child: Text('Min', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54))),
              Expanded(child: Text('Max', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54))),
              Expanded(child: Text('Avg', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 35, child: Text('EC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF203B3D)))),
              Expanded(child: Text(ecSet, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87))),
              Expanded(child: Text(ecMin, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87))),
              Expanded(child: Text(ecMax, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87))),
              Expanded(child: Text(ecAvg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 35, child: Text('pH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF203B3D)))),
              Expanded(child: Text(phSet, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87))),
              Expanded(child: Text(phMin, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87))),
              Expanded(child: Text(phMax, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87))),
              Expanded(child: Text(phAvg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87))),
            ],
          ),
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
}
