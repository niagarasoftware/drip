import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

import '../scrollingTable.dart';

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
List<String>? parsePumpCtData(String? raw) {
  if (raw == null) return null;
  String data = raw.trim();
  if (data.isEmpty || data == '-' || data == 'null' || data == 'N/A') return null;

  List<String> parts = data.split(',');
  String? rVal, yVal, bVal;

  for (int idx = 0; idx < parts.length; idx++) {
    String p = parts[idx].trim();
    if (p.contains(':')) {
      List<String> kv = p.split(':');
      if (kv.length >= 2) {
        String key = kv[0].trim();
        String val = kv[1].trim();
        if (key == '1') {
          rVal = val;
        } else if (key == '2') {
          yVal = val;
        } else if (key == '3') {
          bVal = val;
        }
      }
    } else {
      if (idx == 0) {
        rVal = p;
      } else if (idx == 1) {
        yVal = p;
      } else if (idx == 2) {
        bVal = p;
      }
    }
  }

  if (rVal == null && yVal == null && bVal == null) return null;
  return [rVal ?? '0.00', yVal ?? '0.00', bVal ?? '0.00'];
}


Widget buildPumpCtCard(String rawValue) {
  final List<String>? values = parsePumpCtData(rawValue);

  // Empty state
  if (values == null) {
    return const Center(
      child: Text(
        '–',
        style: TextStyle(fontSize: 13, color: Colors.black38),
      ),
    );
  }

  final nums = values.map((v) => double.tryParse(v) ?? 0.0).toList();
  final bool isIdle = nums.every((n) => n == 0);

  // Phase imbalance (max deviation between phases, in %)
  final double maxV = nums.reduce((a, b) => a > b ? a : b);
  final double minV = nums.reduce((a, b) => a < b ? a : b);
  final double imbalance = maxV > 0 ? ((maxV - minV) / maxV) * 100 : 0;
  final bool imbalanced = imbalance > 10;

  final phases = [_Phase.red, _Phase.yellow, _Phase.blue];

  final Color borderColor = imbalanced
      ? const Color(0xFFFFB74D)
      : (isIdle ? const Color(0xFFE0E0E0) : const Color(0xFFDCE3EA));

  return Tooltip(
    waitDuration: const Duration(milliseconds: 300),
    preferBelow: false,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF263238),
      borderRadius: BorderRadius.circular(8),
    ),
    richMessage: TextSpan(
      style: const TextStyle(fontSize: 12, color: Colors.white),
      children: [
        for (int i = 0; i < 3; i++) ...[
          TextSpan(text: '● ', style: TextStyle(color: phases[i].main)),
          TextSpan(text: '${phases[i].label}: ${values[i]}'),
          if (i < 2) const TextSpan(text: '   '),
        ],
        if (imbalanced)
          TextSpan(
            text: '\nPhase imbalance ${imbalance.toStringAsFixed(1)}%',
            style: const TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.w600),
          ),
      ],
    ),
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: imbalanced ? 1.2 : 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            Expanded(
              child: _buildCtPhaseItem(
                phase: isIdle ? _Phase.idle : phases[i],
                label: phases[i].label,
                value: values[i],
                muted: isIdle,
              ),
            ),
            if (i < 2) const SizedBox(width: 4),
          ],
        ],
      ),
    ),
  );
}

Widget _buildCtPhaseItem({
  required _Phase phase,
  required String label,
  required String value,
  bool muted = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    decoration: BoxDecoration(
      color: phase.bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: phase.border, width: 0.8),
    ),
    // FittedBox prevents overflow when the column gets narrow
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
              // Fixed-width digits so values line up row to row
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    ),
  );
}