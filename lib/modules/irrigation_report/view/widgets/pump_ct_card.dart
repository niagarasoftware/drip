import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

import '../../../../Constants/data_convertion.dart';

/// Phase colour palette (main / soft background / border)
class _Phase {
  final String label;
  final Color main;
  final Color bg;
  final Color border;
  const _Phase(this.label, this.main, this.bg, this.border);

  static const red = _Phase('R', Color(0xFFE53935), Color(0xFFFFF1F1), Color(0xFFFFCDD2));
  static const yellow = _Phase('Y', Color(0xFFF9A825), Color(0xFFFFF8E1), Color(0xFFFFECB3));
  static const blue = _Phase('B', Color(0xFF1E88E5), Color(0xFFEAF4FE), Color(0xFFBBDEFB));
  static const idle = _Phase('', Color(0xFF9E9E9E), Color(0xFFF5F5F5), Color(0xFFE0E0E0));
}

List<List<String?>>? parseAllPumpCtData(String? raw) {
  return DataConvert().parseAllPumpCtData(raw);
}

List<String?>? parsePumpCtData(String? raw) {
  return DataConvert().parsePumpCtData(raw);
}

Widget buildPumpCtCard(String rawValue) {
  final List<List<String?>>? allPumps = parseAllPumpCtData(rawValue);

  // Empty state
  if (allPumps == null || allPumps.isEmpty) {
    return const Center(
      child: Text(
        '–',
        style: TextStyle(fontSize: 13, color: Colors.black38),
      ),
    );
  }

  final phases = [_Phase.red, _Phase.yellow, _Phase.blue];

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      for (int pIdx = 0; pIdx < allPumps.length; pIdx++) ...[
        _buildPumpPhaseRow(allPumps[pIdx], phases),
        if (pIdx < allPumps.length - 1) const SizedBox(height: 4),
      ],
    ],
  );
}

Widget _buildPumpPhaseRow(List<String?> values, List<_Phase> phases) {
  final activeIndices = <int>[];
  for (int i = 0; i < values.length && i < 3; i++) {
    if (values[i] != null && values[i]!.trim().isNotEmpty) {
      activeIndices.add(i);
    }
  }

  if (activeIndices.isEmpty) {
    return const SizedBox(
      height: 20,
      child: Center(
        child: Text('–', style: TextStyle(fontSize: 13, color: Colors.black38)),
      ),
    );
  }

  final nums = activeIndices.map((i) => double.tryParse(values[i]!) ?? 0.0).toList();
  final bool isIdle = nums.every((n) => n == 0);

  return Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (int idx = 0; idx < activeIndices.length; idx++) ...[
        _buildCtPhaseItem(
          phase: isIdle ? _Phase.idle : phases[activeIndices[idx]],
          label: phases[activeIndices[idx]].label,
          value: values[activeIndices[idx]]!,
          muted: isIdle,
        ),
        if (idx < activeIndices.length - 1) const SizedBox(width: 4),
      ],
    ],
  );
}

Widget _buildCtPhaseItem({
  required _Phase phase,
  required String label,
  required String value,
  bool muted = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      color: phase.bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: phase.border, width: 0.8),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: phase.main, shape: BoxShape.circle),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: muted ? Colors.black45 : phase.main,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    ),
  );
}