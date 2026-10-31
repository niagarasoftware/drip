import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:oro_drip_irrigation/modules/Logs/model/event_log_model.dart';
import 'package:oro_drip_irrigation/modules/Logs/model/motor_data_hourly.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pump_log_excel_builder.dart';

// -----------------------------------------------------------------------------
// Design tokens (same palette as the dashboard)
// -----------------------------------------------------------------------------
const PdfColor _teal = PdfColor.fromInt(0xFF006775);
const PdfColor _tealLight = PdfColor.fromInt(0xFFE3F1F3);
const PdfColor _ink = PdfColor.fromInt(0xFF1E293B);
const PdfColor _muted = PdfColor.fromInt(0xFF8C98A4);
const PdfColor _border = PdfColor.fromInt(0xFFE5E9EB);
const PdfColor _green = PdfColor.fromInt(0xFF2E9E57);
const PdfColor _red = PdfColor.fromInt(0xFFE53935);
const PdfColor _amber = PdfColor.fromInt(0xFFF9A825);
const PdfColor _blue = PdfColor.fromInt(0xFF1E88E5);

// -----------------------------------------------------------------------------
// Small helpers
// -----------------------------------------------------------------------------
double? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) {
    final d = v.toDouble();
    return d.isNaN || d.isInfinite ? null : d;
  }
  final s = v.toString().trim();
  if (s.isEmpty || s == '-' || s == '--' || s.toLowerCase() == 'null' || s.toLowerCase() == 'na') {
    return null;
  }
  final d = double.tryParse(s);
  return d == null || d.isNaN || d.isInfinite ? null : d;
}

int _secs(String hms) {
  final p = hms.trim().split(':');
  if (p.length < 2) return 0;
  final h = int.tryParse(p[0]) ?? 0;
  final m = int.tryParse(p[1]) ?? 0;
  final s = p.length > 2 ? (int.tryParse(p[2]) ?? 0) : 0;
  return h * 3600 + m * 60 + s;
}

String _hms(int secs) {
  final h = secs ~/ 3600;
  final m = (secs % 3600) ~/ 60;
  final s = secs % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// "HH:MM..." -> minutes since midnight (null if it can't be read)
int? _minutes(String t) {
  final s = t.trim();
  if (s.length < 5) return null;
  final h = int.tryParse(s.substring(0, 2));
  final m = int.tryParse(s.substring(3, 5));
  if (h == null || m == null || h > 24 || m > 59) return null;
  return h * 60 + m;
}

class _Phase {
  final String label;
  final String suffix;
  final PdfColor color;
  const _Phase(this.label, this.suffix, this.color);
}

const _allPhases = <_Phase>[
  _Phase('R', 'R', _red),
  _Phase('Y', 'Y', _amber),
  _Phase('B', 'B', _blue),
];

// -----------------------------------------------------------------------------
// Reusable widgets
// -----------------------------------------------------------------------------
pw.Widget _slideTitle(String text, {String? subtitle}) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 14),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(width: 5, height: subtitle == null ? 24 : 36, color: _teal),
        pw.SizedBox(width: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(text, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _ink)),
            if (subtitle != null)
              pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10, color: _muted)),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _kpi(String label, String value, String unit, {PdfColor accent = _teal, double width = 190}) {
  return pw.Container(
    width: width,
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: _border, width: 0.8),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _muted)),
        pw.SizedBox(height: 5),
        pw.Text(value, style: pw.TextStyle(fontSize: 19, fontWeight: pw.FontWeight.bold, color: accent)),
        if (unit.isNotEmpty) pw.Text(unit, style: const pw.TextStyle(fontSize: 8, color: _muted)),
      ],
    ),
  );
}

pw.Widget _legendDot(String text, PdfColor color) {
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Container(width: 9, height: 9, color: color),
      pw.SizedBox(width: 4),
      pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: _ink)),
      pw.SizedBox(width: 14),
    ],
  );
}

pw.Widget _cell(String text, {bool header = false, pw.Alignment align = pw.Alignment.centerLeft}) {
  return pw.Container(
    alignment: align,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: header ? PdfColors.white : _ink,
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
// Data access
// -----------------------------------------------------------------------------
List<EventLog> _eventsFor(PumpLogExportData d, int key) =>
    key == 1 ? d.motor2Events : (key == 2 ? d.motor3Events : d.motor1Events);

class _MotorStats {
  final String run, idle, dry, cyclic, other, flow;
  const _MotorStats(this.run, this.idle, this.dry, this.cyclic, this.other, this.flow);
}

_MotorStats _motorStats(MotorDataHourly? m, int key) {
  const z = '00:00:00';
  if (m == null) return const _MotorStats(z, z, z, z, z, '0');
  if (key == 1) {
    return _MotorStats(
      _hms(_secs(m.motorRunTime2)),
      _hms(_secs(m.motorIdleTime2)),
      _hms(_secs(m.dryRunTripTime2)),
      _hms(_secs(m.cyclicTripTime2)),
      _hms(_secs(m.otherTripTime2)),
      m.totalFlowToday2,
    );
  }
  if (key == 2) {
    return _MotorStats(
      _hms(_secs(m.motorRunTime3)),
      _hms(_secs(m.motorIdleTime3)),
      _hms(_secs(m.dryRunTripTime3)),
      _hms(_secs(m.cyclicTripTime3)),
      _hms(_secs(m.otherTripTime3)),
      m.totalFlowToday3,
    );
  }
  return _MotorStats(
    _hms(_secs(m.motorRunTime1)),
    _hms(_secs(m.motorIdleTime1)),
    _hms(_secs(m.dryRunTripTime1)),
    _hms(_secs(m.cyclicTripTime1)),
    _hms(_secs(m.otherTripTime1)),
    m.totalFlowToday1,
  );
}

String _reasonText(String reason, String motorName) {
  if (reason.isEmpty) return '-';
  var t = reason;
  if (motorName.isNotEmpty && !motorName.toLowerCase().startsWith('motor')) {
    t = t.replaceAll(RegExp(r'motor[1-3]?', caseSensitive: false), motorName);
  }
  return t[0].toUpperCase() + t.substring(1);
}

// -----------------------------------------------------------------------------
// BUILDER
// -----------------------------------------------------------------------------
Future<Uint8List> generatePumpLogPdfBytes(PumpLogExportData data, String name) async {
  final doc = pw.Document(title: name, author: 'Niagara Automations', creator: 'ORO Drip Irrigation');
  final fmt = PdfPageFormat.a4.landscape;
  final generatedOn = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
  final bool isToday = data.dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());
  final segments = data.segments.isNotEmpty ? data.segments : <int, String>{0: 'Motor 1'};
  final motor = data.motorData;

  // ---------------- Cover ----------------
  doc.addPage(pw.Page(
    pageFormat: fmt,
    margin: pw.EdgeInsets.zero,
    build: (ctx) => pw.Container(
      width: fmt.width,
      height: fmt.height,
      color: _teal,
      padding: const pw.EdgeInsets.symmetric(horizontal: 64, vertical: 56),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PUMP LOG REPORT',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.white, letterSpacing: 4)),
          pw.SizedBox(height: 14),
          pw.Text(data.deviceName.isEmpty ? 'Pump Controller' : data.deviceName,
              style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.SizedBox(height: 28),
          pw.Container(width: 90, height: 3, color: PdfColors.white),
          pw.SizedBox(height: 28),
          pw.Text('Date: ${data.dateStr}', style: const pw.TextStyle(fontSize: 16, color: PdfColors.white)),
          pw.SizedBox(height: 6),
          pw.Text('Period: ${data.periodStr}', style: const pw.TextStyle(fontSize: 16, color: PdfColors.white)),
          if (data.deviceId.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('Device MAC: ${data.deviceId}',
                style: const pw.TextStyle(fontSize: 16, color: PdfColors.white)),
          ],
          pw.Spacer(),
          pw.Text('Generated on $generatedOn  |  Niagara Automations',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
        ],
      ),
    ),
  ));

  // ---------------- Content slides ----------------
  final slides = <pw.Widget>[];

  // Slide: Overview
  slides.addAll([
    _slideTitle('Overview', subtitle: '${data.deviceName}  |  ${data.dateStr}  |  ${data.periodStr}'),
    pw.Wrap(spacing: 12, runSpacing: 12, children: [
      _kpi('Total power ON time', _hms(_secs(motor?.totalPowerOnTime ?? '00:00:00')), 'HH:MM:SS', accent: _green),
      _kpi('Total power OFF time', _hms(_secs(motor?.totalPowerOffTime ?? '00:00:00')), 'HH:MM:SS', accent: _red),
      _kpi('Cumulative flow', motor?.overAllCumulativeFlow ?? '0', 'Litres'),
      _kpi('Pressure', motor?.pressure ?? '0.0', 'bar'),
      _kpi('Flow rate', motor?.flowRate ?? '0.0', 'Lps'),
      _kpi('Level', motor?.level ?? '0.0', 'feet'),
    ]),
    pw.SizedBox(height: 20),
    pw.Text('Motor run time comparison',
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink)),
    pw.SizedBox(height: 8),
  ]);

  final runSecs = <int, int>{
    for (final e in segments.entries) e.key: _secs(_motorStats(motor, e.key).run),
  };
  final maxRun = runSecs.values.fold<int>(0, math.max);
  for (final e in segments.entries) {
    final secs = runSecs[e.key] ?? 0;
    final frac = maxRun == 0 ? 0 : (secs * 1000 / maxRun).round();
    slides.add(pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(children: [
        pw.SizedBox(width: 130, child: pw.Text(e.value, style: const pw.TextStyle(fontSize: 10, color: _ink))),
        pw.Expanded(
          child: pw.Row(children: [
            if (frac > 0) pw.Expanded(flex: frac, child: pw.Container(height: 16, color: _teal)),
            pw.Expanded(flex: math.max(1, 1000 - frac), child: pw.Container(height: 16, color: _tealLight)),
          ]),
        ),
        pw.SizedBox(
          width: 80,
          child: pw.Text(_hms(secs),
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink)),
        ),
      ]),
    ));
  }

  // Slides per motor: performance + pump log
  for (final e in segments.entries) {
    final st = _motorStats(motor, e.key);
    final events = _eventsFor(data, e.key);

    slides.add(pw.NewPage());
    slides.addAll([
      _slideTitle('${e.value} - Performance', subtitle: '${data.dateStr}  |  ${data.periodStr}'),
      pw.Wrap(spacing: 12, runSpacing: 12, children: [
        _kpi('Run time', st.run, 'HH:MM:SS', accent: _green),
        _kpi('Idle time', st.idle, 'HH:MM:SS'),
        _kpi('Dry run trip time', st.dry, 'HH:MM:SS', accent: _red),
        _kpi('Cyclic trip time', st.cyclic, 'HH:MM:SS', accent: _amber),
        _kpi('Other trip time', st.other, 'HH:MM:SS', accent: _red),
        _kpi('Total flow', st.flow, 'Litres', accent: _blue),
      ]),
      pw.SizedBox(height: 22),
      pw.Text('Time distribution',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink)),
      pw.SizedBox(height: 8),
    ]);

    final parts = <MapEntry<String, MapEntry<int, PdfColor>>>[
      MapEntry('Run ${st.run}', MapEntry(_secs(st.run), _green)),
      MapEntry('Idle ${st.idle}', MapEntry(_secs(st.idle), PdfColors.grey500)),
      MapEntry('Dry run ${st.dry}', MapEntry(_secs(st.dry), _red)),
      MapEntry('Cyclic ${st.cyclic}', MapEntry(_secs(st.cyclic), _amber)),
      MapEntry('Other ${st.other}', MapEntry(_secs(st.other), _blue)),
    ];
    final total = parts.fold<int>(0, (s, p) => s + p.value.key);
    if (total == 0) {
      slides.add(pw.Text('No run-time data recorded for this period.',
          style: const pw.TextStyle(fontSize: 11, color: _muted)));
    } else {
      slides.add(pw.Row(children: [
        for (final p in parts)
          if (p.value.key > 0)
            pw.Expanded(
              flex: math.max(1, (p.value.key * 1000 / total).round()),
              child: pw.Container(height: 26, color: p.value.value),
            ),
      ]));
      slides.add(pw.SizedBox(height: 8));
      slides.add(pw.Wrap(children: [for (final p in parts) _legendDot(p.key, p.value.value)]));
    }

    // Pump log slide
    slides.add(pw.NewPage());
    slides.addAll([
      _slideTitle('${e.value} - Pump log', subtitle: '${events.length} event(s)  |  ${data.dateStr}'),
    ]);
    if (events.isEmpty) {
      slides.add(pw.Text('No events recorded for this date.',
          style: const pw.TextStyle(fontSize: 11, color: _muted)));
    } else {
      slides.addAll([
        pw.Text('ON periods across 24 hours',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink)),
        pw.SizedBox(height: 6),
        _timeline(events, isToday: isToday),
        pw.SizedBox(height: 14),
        _table(
          ['#', 'On time', 'Off time', 'Duration', 'On reason', 'Off reason'],
          [
            for (var i = 0; i < events.length; i++)
              [
                '${i + 1}',
                events[i].onTime.isNotEmpty && events[i].onTime != '-' ? _hms(_secs(events[i].onTime)) : '-',
                events[i].offTime.isNotEmpty && events[i].offTime != '-' ? _hms(_secs(events[i].offTime)) : '-',
                events[i].duration.isNotEmpty && events[i].duration != '-' ? _hms(_secs(events[i].duration)) : '-',
                _reasonText(events[i].onReason, e.value),
                _reasonText(events[i].offReason, e.value),
              ],
          ],
          flex: [0.5, 1.2, 1.2, 1.2, 3.2, 3.2],
        ),
      ]);
    }
  }

  // Voltage / current (and power factor / power when the device reports them)
  final voltageRows = data.voltageData;
  if (voltageRows.isNotEmpty) {
    slides.add(pw.NewPage());
    slides.addAll([
      _slideTitle('Voltage & Current Hourly Log', subtitle: '${data.deviceName}  |  ${data.dateStr}'),
      pw.SizedBox(height: 4),
      _voltageTable(voltageRows),
    ]);
  }

  doc.addPage(pw.MultiPage(
    pageFormat: fmt,
    margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
    header: (ctx) => ctx.pageNumber == 1
        ? pw.SizedBox.shrink()
        : pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Pump Log Report — ${data.deviceName}', style: const pw.TextStyle(fontSize: 9, color: _muted)),
              pw.Text('Date: ${data.dateStr}', style: const pw.TextStyle(fontSize: 9, color: _muted)),
            ],
          ),
    footer: (ctx) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Page ${ctx.pageNumber}', style: const pw.TextStyle(fontSize: 9, color: _muted)),
        pw.Text('Niagara Automations', style: const pw.TextStyle(fontSize: 9, color: _muted)),
      ],
    ),
    build: (ctx) => slides,
  ));

  return await doc.save();
}

pw.Widget _timeline(List<EventLog> events, {required bool isToday}) {
  const double w = 722; // Printable width on landscape A4 (842 - 80)
  const double barH = 24;
  final now = DateTime.now();
  final nowMin = now.hour * 60 + now.minute;

  final bars = <pw.Widget>[];
  final labels = <pw.Widget>[];

  for (final e in events) {
    final s = _minutes(e.onTime);
    if (s == null) continue;
    var f = _minutes(e.offTime) ?? (isToday ? nowMin : 1440);
    if (f < s) f = s; // midnight wrap safeguard
    final leftFrac = s / 1440.0;
    final widthFrac = (f - s) / 1440.0;
    if (widthFrac <= 0) continue;

    bars.add(pw.Positioned(
      left: leftFrac * w,
      top: 0,
      child: pw.SizedBox(
        width: math.max(2.0, widthFrac * w),
        height: barH,
        child: pw.Container(
          decoration: pw.BoxDecoration(
            color: _teal,
            borderRadius: pw.BorderRadius.circular(3),
          ),
        ),
      ),
    ));
  }

  // Hour markers
  for (int h = 0; h <= 24; h += 3) {
    final x = (h / 24.0) * w;
    labels.add(pw.Positioned(
      left: x - 15,
      top: barH + 4,
      child: pw.SizedBox(
        width: 30,
        child: pw.Text(
          '${h.toString().padLeft(2, '0')}:00',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ),
    ));
  }

  return pw.SizedBox(
    width: w,
    height: barH + 16,
    child: pw.Stack(children: [
      pw.Container(width: w, height: barH, color: PdfColors.grey200),
      ...bars,
      ...labels,
    ]),
  );
}

pw.Widget _table(List<String> headers, List<List<String>> rows, {List<double>? flex}) {
  return pw.Table(
    border: pw.TableBorder.all(color: _border, width: 0.6),
    columnWidths: flex == null
        ? null
        : {for (int i = 0; i < flex.length; i++) i: pw.FlexColumnWidth(flex[i])},
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _teal),
        children: [for (final h in headers) _cell(h, header: true)],
      ),
      for (int r = 0; r < rows.length; r++)
        pw.TableRow(
          decoration: pw.BoxDecoration(color: r.isEven ? PdfColors.white : PdfColors.grey50),
          children: [for (final c in rows[r]) _cell(c)],
        ),
    ],
  );
}

pw.Widget _voltageTable(List<Map<String, dynamic>> rows) {
  final headers = ['Hour', 'Voltage R (V)', 'Voltage Y (V)', 'Voltage B (V)', 'Current R (A)', 'Current Y (A)', 'Current B (A)'];
  return pw.Table(
    border: pw.TableBorder.all(color: _border, width: 0.6),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _teal),
        children: [for (final h in headers) _cell(h, header: true)],
      ),
      for (int r = 0; r < rows.length; r++)
        pw.TableRow(
          decoration: pw.BoxDecoration(color: r.isEven ? PdfColors.white : PdfColors.grey50),
          children: [
            _cell('${rows[r]['hour'] ?? '-'}'),
            _cell('${rows[r]['voltageR'] ?? '-'}'),
            _cell('${rows[r]['voltageY'] ?? '-'}'),
            _cell('${rows[r]['voltageB'] ?? '-'}'),
            _cell('${rows[r]['currentR'] ?? '-'}'),
            _cell('${rows[r]['currentY'] ?? '-'}'),
            _cell('${rows[r]['currentB'] ?? '-'}'),
          ],
        ),
    ],
  );
}
