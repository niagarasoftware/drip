import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _ink = Color(0xFF142238);
const _muted = Color(0xFF64748B);
const _panel = Color(0xFFF5F8FB);

class SensorStatusBadge extends StatelessWidget {
  final int code;
  const SensorStatusBadge({super.key, required this.code});
  @override
  Widget build(BuildContext context) {
    final label = switch (code) {
      255 => 'Normal', 1 => 'Alert', 2 => 'Warning',
      3 => 'Attention', _ => 'Unknown',
    };
    final color = switch (code) {
      255 => const Color(0xFF15803D), 1 => const Color(0xFFDC2626),
      2 => const Color(0xFFB45309), 3 => const Color(0xFFEA580C),
      _ => _muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class SensorDailyStats extends StatelessWidget {
  final double min, max, average;
  final VoidCallback? onTap;
  const SensorDailyStats({super.key, required this.min, required this.max, required this.average,required this.onTap,});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(11)),
    child: InkWell(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Current Day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 8),
        Row(children: [
          _item('Min', min), _item('Max', max), _item('Average', average),
        ]),
      ]),
    ),
  );
  Widget _item(String label, double number) => Expanded(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
      const SizedBox(height: 3),
      Text(number.toStringAsFixed(2), maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
    ],
  ));
}

class SensorPeriodRow extends StatelessWidget {
  final String title;
  final double average;
  final VoidCallback? onTap;
  final bool monthly;
  const SensorPeriodRow({super.key, required this.title, required this.average,
    required this.onTap, this.monthly = false});
  @override
  Widget build(BuildContext context) => Material(
    color: monthly ? const Color(0xFFFFF2F4) : const Color(0xFFF0F6FF),
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10), onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(children: [
          Icon(monthly ? Icons.calendar_month_outlined : Icons.calendar_today_outlined,
            size: 16, color: const Color(0xFF2374C6)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink))),
          Text('Avg ${average.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: _ink, fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right, size: 20, color: _ink),
        ]),
      ),
    ),
  );
}

class WindCompass extends StatelessWidget {
  final double angle;
  const WindCompass({super.key, required this.angle});
  @override
  Widget build(BuildContext context) {
    final normalized = angle.isFinite ? ((angle % 360) + 360) % 360 : 0.0;
    return SizedBox(width: 112, height: 112, child: Stack(alignment: Alignment.center, children: [
      SvgPicture.asset('assets/Images/Svg/winddirection.svg', width: 112, height: 112),
      AnimatedRotation(
        turns: normalized / 360,
        duration: const Duration(milliseconds: 450),
        child: Transform.translate(
          offset: const Offset(0, -26),
          child: const Icon(Icons.navigation, size: 24, color: Color(0xFFEF4444)),
        ),
      ),
      Positioned(bottom: 48, child: Text('${normalized.toStringAsFixed(0)}°',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink))),
    ]));
  }
}

String windDirectionName(double angle) {
  if (!angle.isFinite) return '--';
  const names = ['North', 'North-East', 'East', 'South-East',
    'South', 'South-West', 'West', 'North-West'];
  final d = ((angle % 360) + 360) % 360;
  return names[((d + 22.5) ~/ 45) % 8];
}

class ReusableSensorCard extends StatelessWidget {
  final String title;
  final String unit;
  final double value;
  final int statusCode;
  final double todayMin, todayMax, todayAverage;
  final double weekAverage, monthAverage;
  final IconData icon;
  final Color accent;
  final bool isWindDirection;
  final VoidCallback? onWeekTap, onMonthTap,onCurrentTap;

  const ReusableSensorCard({
    super.key,
    required this.title, required this.unit, required this.value,
    required this.statusCode, required this.todayMin, required this.todayMax,
    required this.todayAverage, required this.weekAverage, required this.monthAverage,
    required this.icon, required this.accent, this.isWindDirection = false,
    this.onWeekTap, this.onMonthTap,this.onCurrentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4EAEF)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0B182B40), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accent.withOpacity(.10), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink))),
          const SizedBox(width: 5),
          SensorStatusBadge(code: statusCode),
        ]),
        const SizedBox(height: 13),
        if (isWindDirection)
          Row(children: [
            WindCompass(angle: value),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${value.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: _ink)),
              Text(windDirectionName(value), style: const TextStyle(fontSize: 13, color: _muted)),
            ])),
          ])
        else
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(child: Text(value.toStringAsFixed(2), maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800, color: _ink))),
            const SizedBox(width: 6),
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(unit,
              style: const TextStyle(fontSize: 14, color: _muted))),
          ]),
        const SizedBox(height: 12),
        if (!isWindDirection) ...[
          SensorDailyStats(min: todayMin, max: todayMax, average: todayAverage,onTap: onCurrentTap),
          const SizedBox(height: 8),
          SensorPeriodRow(title: 'Last 7 Days', average: weekAverage, onTap: onWeekTap),
          const SizedBox(height: 7),
          SensorPeriodRow(title: 'Last Month', average: monthAverage, monthly: true, onTap: onMonthTap),
        ] else ...[
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(11)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Current Direction', style: TextStyle(fontSize: 12, color: _muted)),
              const SizedBox(height: 4),
              Text('${value.toStringAsFixed(0)}°  ${windDirectionName(value)}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
            ]),
          ),
        ],
      ]),
    );
  }
}
