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
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. WATER & PRE/POST Sections
        LayoutBuilder(builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 500;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildWaterSection()),
                const SizedBox(width: 16),
                Expanded(child: _buildPrePostSection()),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWaterSection(),
                const Divider(height: 20, thickness: 1, color: Color(0xFFE7EEEE)),
                _buildPrePostSection(),
              ],
            );
          }
        }),
        const Divider(height: 20, thickness: 1, color: Color(0xFFE7EEEE)),

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
        const Divider(height: 20, thickness: 1, color: Color(0xFFE7EEEE)),

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
        const Divider(height: 20, thickness: 1, color: Color(0xFFE7EEEE)),

        // 3. CHANNELS
        const Text(
          'CHANNELS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006573)),
        ),
        const SizedBox(height: 6),
        if (!hasChannels)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('No fertilizer data / Fertigation OFF', style: TextStyle(fontSize: 11, color: Color(0xFF637D7A))),
          )
        else ...[
          ...cardModel.centralChannels.map((c) => FertigationChannelTile(channel: c)),
          ...cardModel.localChannels.map((c) => FertigationChannelTile(channel: c)),
        ],

        const Divider(height: 20, thickness: 1, color: Color(0xFFE7EEEE)),

        // 4. GENERAL (start/stop reason, times)
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
          ],
        ),
      ],
    );
  }

  Widget _buildWaterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('WATER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006573))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Method', style: TextStyle(fontSize: 11, color: Color(0xFF637D7A))),
                  const SizedBox(height: 2),
                  Text(cardModel.waterMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF203B3D))),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Volume', style: TextStyle(fontSize: 11, color: Color(0xFF637D7A))),
                  const SizedBox(height: 2),
                  Text(cardModel.waterActual, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF203B3D))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Planned', style: TextStyle(fontSize: 11, color: Color(0xFF637D7A))),
                  const SizedBox(height: 2),
                  Text(cardModel.waterPlanned, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF203B3D))),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Actual', style: TextStyle(fontSize: 11, color: Color(0xFF637D7A))),
                  const SizedBox(height: 2),
                  Text(cardModel.waterActual, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF203B3D))),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrePostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PRE / POST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006573))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Method', style: TextStyle(fontSize: 11, color: Color(0xFF637D7A))),
                  const SizedBox(height: 2),
                  Text(cardModel.preMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF203B3D))),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pre', style: TextStyle(fontSize: 11, color: Color(0xFF637D7A))),
                  const SizedBox(height: 2),
                  Text(cardModel.preTimeQty, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF203B3D))),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Post', style: TextStyle(fontSize: 11, color: Color(0xFF637D7A))),
                  const SizedBox(height: 2),
                  Text(cardModel.postTimeQty, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF203B3D))),
                ],
              ),
            ),
          ],
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006573))),
        const SizedBox(height: 6),
        const Row(
          children: [
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
    );
  }
}
