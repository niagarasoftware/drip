import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import '../../model/fertigation_card_model.dart';

class FertigationTableView extends StatelessWidget {
  final List<FertigationCardModel> cards;

  const FertigationTableView({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Text('No Fertigation Records Found', style: TextStyle(color: Color(0xFF637D7A), fontSize: 14, fontWeight: FontWeight.w500)),
      );
    }

    // Determine optional column visibility
    bool showPre = cards.any((c) => c.preTimeQty != '—' && c.preTimeQty != '-' && c.preTimeQty != '' && c.preTimeQty != '0' && c.preTimeQty != '0m' && c.preTimeQty != '00:00:00');
    bool showPost = cards.any((c) => c.postTimeQty != '—' && c.postTimeQty != '-' && c.postTimeQty != '' && c.postTimeQty != '0' && c.postTimeQty != '0m' && c.postTimeQty != '00:00:00');

    bool showCentralEc = cards.any((c) => (c.centralEcSet != '—' && c.centralEcSet.isNotEmpty) || (c.centralEcMin != '—' && c.centralEcMin.isNotEmpty) || (c.centralEcMax != '—' && c.centralEcMax.isNotEmpty) || (c.centralEcAvg != '—' && c.centralEcAvg.isNotEmpty));
    bool showCentralPh = cards.any((c) => (c.centralPhSet != '—' && c.centralPhSet.isNotEmpty) || (c.centralPhMin != '—' && c.centralPhMin.isNotEmpty) || (c.centralPhMax != '—' && c.centralPhMax.isNotEmpty) || (c.centralPhAvg != '—' && c.centralPhAvg.isNotEmpty));

    bool showLocalEc = cards.any((c) => (c.localEcSet != '—' && c.localEcSet.isNotEmpty) || (c.localEcMin != '—' && c.localEcMin.isNotEmpty) || (c.localEcMax != '—' && c.localEcMax.isNotEmpty) || (c.localEcAvg != '—' && c.localEcAvg.isNotEmpty));
    bool showLocalPh = cards.any((c) => (c.localPhSet != '—' && c.localPhSet.isNotEmpty) || (c.localPhMin != '—' && c.localPhMin.isNotEmpty) || (c.localPhMax != '—' && c.localPhMax.isNotEmpty) || (c.localPhAvg != '—' && c.localPhAvg.isNotEmpty));

    // Determine active central and local channel numbers across all cards
    Set<int> activeCentralChannels = {};
    Set<int> activeLocalChannels = {};
    for (var card in cards) {
      for (var c in card.centralChannels) {
        if (c.planned != '—' || c.actual != '—') {
          int? chNum = int.tryParse(c.name.replaceAll(RegExp(r'[^0-9]'), ''));
          if (chNum != null) activeCentralChannels.add(chNum);
        }
      }
      for (var l in card.localChannels) {
        if (l.planned != '—' || l.actual != '—') {
          int? chNum = int.tryParse(l.name.replaceAll(RegExp(r'[^0-9]'), ''));
          if (chNum != null) activeLocalChannels.add(chNum);
        }
      }
    }

    List<int> sortedCentral = activeCentralChannels.toList()..sort();
    List<int> sortedLocal = activeLocalChannels.toList()..sort();

    if (sortedCentral.isEmpty && sortedLocal.isEmpty) {
      sortedCentral = [1, 2, 3, 4];
    }

    List<DataColumn2> columns = [
      const DataColumn2(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.S),
      const DataColumn2(label: Text('Program', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.M),
      const DataColumn2(label: Text('Sequence', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.M),
      const DataColumn2(label: Text('Line', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.S),
      const DataColumn2(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.S),
      const DataColumn2(label: Text('Water Planned', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.S),
      const DataColumn2(label: Text('Water Actual', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.S),
    ];

    if (showPre) {
      columns.add(const DataColumn2(label: Text('PRE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.S));
    }
    if (showPost) {
      columns.add(const DataColumn2(label: Text('POST', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.S));
    }
    if (showCentralEc) {
      columns.add(const DataColumn2(label: Text('Central EC', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.M));
    }
    if (showCentralPh) {
      columns.add(const DataColumn2(label: Text('Central pH', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.M));
    }
    if (showLocalEc) {
      columns.add(const DataColumn2(label: Text('Local EC', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.M));
    }
    if (showLocalPh) {
      columns.add(const DataColumn2(label: Text('Local pH', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.M));
    }

    for (var ch in sortedCentral) {
      columns.add(DataColumn2(label: Text('C-CH$ch', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.S));
    }
    for (var ch in sortedLocal) {
      columns.add(DataColumn2(label: Text('L-CH$ch', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.S));
    }

    columns.addAll(const [
      DataColumn2(label: Text('Start Time', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.S),
      DataColumn2(label: Text('Stop Time', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006573))), size: ColumnSize.S),
    ]);

    double minTableWidth = 1100.0 + (sortedCentral.length + sortedLocal.length + (showPre ? 1 : 0) + (showPost ? 1 : 0) + (showCentralEc ? 1 : 0) + (showCentralPh ? 1 : 0) + (showLocalEc ? 1 : 0) + (showLocalPh ? 1 : 0)) * 90.0;
    double tableHeight = (cards.length * 72.0 + 48.0 + 24.0).clamp(250.0, 650.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EEEE), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: tableHeight,
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 16,
            minWidth: minTableWidth,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFEDF4F4)),
            headingRowHeight: 48,
            dataRowHeight: 72.0,
            border: TableBorder.all(
              color: Colors.grey.shade300,
              width: 0.8,
            ),
            columns: columns,
            rows: cards.map((card) {
              List<DataCell> cells = [
                DataCell(Text(card.date)),
                DataCell(Text(card.programName)),
                DataCell(Text(card.sequenceName)),
                DataCell(Text(card.lineName)),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: card.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(card.status, style: TextStyle(color: card.statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                )),
                DataCell(Text(card.waterPlanned)),
                DataCell(Text(card.waterActual)),
              ];

              if (showPre) {
                String preVal = (card.preTimeQty != '—' && card.preTimeQty != '-' && card.preTimeQty != '' && card.preTimeQty != '0' && card.preTimeQty != '0m' && card.preTimeQty != '00:00:00')
                    ? '${card.preMethod}: ${card.preTimeQty}'
                    : '—';
                cells.add(DataCell(Text(preVal, style: const TextStyle(fontSize: 11))));
              }
              if (showPost) {
                String postVal = (card.postTimeQty != '—' && card.postTimeQty != '-' && card.postTimeQty != '' && card.postTimeQty != '0' && card.postTimeQty != '0m' && card.postTimeQty != '00:00:00')
                    ? '${card.preMethod}: ${card.postTimeQty}'
                    : '—';
                cells.add(DataCell(Text(postVal, style: const TextStyle(fontSize: 11))));
              }
              if (showCentralEc) {
                String ecStr = _formatEcPh(card.centralEcSet, card.centralEcMin, card.centralEcMax, card.centralEcAvg);
                cells.add(DataCell(Text(ecStr, style: const TextStyle(fontSize: 11, height: 1.3))));
              }
              if (showCentralPh) {
                String phStr = _formatEcPh(card.centralPhSet, card.centralPhMin, card.centralPhMax, card.centralPhAvg);
                cells.add(DataCell(Text(phStr, style: const TextStyle(fontSize: 11, height: 1.3))));
              }
              if (showLocalEc) {
                String ecStr = _formatEcPh(card.localEcSet, card.localEcMin, card.localEcMax, card.localEcAvg);
                cells.add(DataCell(Text(ecStr, style: const TextStyle(fontSize: 11, height: 1.3))));
              }
              if (showLocalPh) {
                String phStr = _formatEcPh(card.localPhSet, card.localPhMin, card.localPhMax, card.localPhAvg);
                cells.add(DataCell(Text(phStr, style: const TextStyle(fontSize: 11, height: 1.3))));
              }

              for (var ch in sortedCentral) {
                var found = card.centralChannels.firstWhere(
                  (c) => c.name.replaceAll(RegExp(r'[^0-9]'), '') == ch.toString(),
                  orElse: () => FertigationChannelModel(name: 'C-CH$ch', planned: '—', actual: '—', isCentral: true),
                );
                bool hasData = card.centralChannels.any((c) => c.name.replaceAll(RegExp(r'[^0-9]'), '') == ch.toString() && (c.planned != '—' && c.planned != '0' || c.actual != '—' && c.actual != '0'));
                String text = hasData ? 'P: ${found.planned}\nA: ${found.actual}' : '—';
                cells.add(DataCell(Text(text, style: const TextStyle(fontSize: 11, height: 1.3))));
              }

              for (var ch in sortedLocal) {
                var found = card.localChannels.firstWhere(
                  (c) => c.name.replaceAll(RegExp(r'[^0-9]'), '') == ch.toString(),
                  orElse: () => FertigationChannelModel(name: 'L-CH$ch', planned: '—', actual: '—', isCentral: false),
                );
                bool hasData = card.localChannels.any((c) => c.name.replaceAll(RegExp(r'[^0-9]'), '') == ch.toString() && (c.planned != '—' && c.planned != '0' || c.actual != '—' && c.actual != '0'));
                String text = hasData ? 'P: ${found.planned}\nA: ${found.actual}' : '—';
                cells.add(DataCell(Text(text, style: const TextStyle(fontSize: 11, height: 1.3))));
              }

      cells.addAll([
                DataCell(Text(card.startTime)),
                DataCell(Text(card.stopTime)),
              ]);

              return DataRow2(cells: cells);
            }).toList(),
          ),
        ),
      ),
    );
  }

  static String _formatEcPh(String set, String min, String max, String avg) {
    List<String> parts = [];
    if (set != '—' && set.isNotEmpty) parts.add('Set: $set');
    if (min != '—' && min.isNotEmpty) parts.add('Min: $min');
    if (max != '—' && max.isNotEmpty) parts.add('Max: $max');
    if (avg != '—' && avg.isNotEmpty) parts.add('Avg: $avg');
    return parts.isEmpty ? '—' : parts.join('\n');
  }
}
