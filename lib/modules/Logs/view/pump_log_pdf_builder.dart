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

String _powerOffTime(MotorDataHourly? m) {
  if (m == null) return '00:00:00';
  if (m.powerOffTime.isNotEmpty && m.powerOffTime != '0:0:00' && m.powerOffTime != '00:00:00' && m.powerOffTime != '-') {
    return _hms(_secs(m.powerOffTime));
  }
  return _hms(_secs(m.totalPowerOffTime));
}

({String label, String value}) _pdfFlowRate(MotorDataHourly? m, String periodStr) {
  if (m == null) return (label: 'Flow rate', value: '0.0');
  final live = double.tryParse(m.flowRate) ?? 0.0;

  if (periodStr == 'Daily' && live > 0) {
    return (label: 'Flow rate', value: live.toStringAsFixed(2));
  }

  double totalLitres = double.tryParse(m.totalFlowToday1.replaceAll(',', '')) ??
      double.tryParse(m.totalFlowToday2.replaceAll(',', '')) ??
      double.tryParse(m.totalFlowToday3.replaceAll(',', '')) ?? 0.0;

  if (totalLitres == 0) {
    totalLitres = double.tryParse(m.overAllCumulativeFlow.replaceAll(',', '')) ?? 0.0;
  }

  int runSecs = _secs(m.motorRunTime1);
  if (runSecs == 0) runSecs = _secs(m.motorRunTime2);
  if (runSecs == 0) runSecs = _secs(m.motorRunTime3);

  if (runSecs > 0 && totalLitres > 0) {
    final avg = totalLitres / runSecs;
    return (label: 'Avg flow rate', value: avg.toStringAsFixed(2));
  }

  return (
    label: live > 0 ? 'Flow rate' : 'Avg flow rate',
    value: live > 0 ? live.toStringAsFixed(2) : (m.flowRate.isEmpty ? '0.0' : m.flowRate)
  );
}

// -----------------------------------------------------------------------------
// Reusable widgets
// -----------------------------------------------------------------------------
pw.Widget _slideTitle(String text, {String? subtitle}) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8, top: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(width: 4, height: subtitle == null ? 18 : 28, color: _teal),
        pw.SizedBox(width: 8),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(text, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _ink)),
            if (subtitle != null)
              pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9, color: _muted)),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _kpiRow(List<pw.Widget> items) {
  return pw.Row(
    children: [
      for (int i = 0; i < items.length; i++) ...[
        if (i > 0) pw.SizedBox(width: 8),
        pw.Expanded(child: items[i]),
      ],
    ],
  );
}

pw.Widget _compactKpi(String label, String value, String unit, {PdfColor accent = _teal}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: _border, width: 0.8),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _ink), maxLines: 1),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent), maxLines: 1),
        if (unit.isNotEmpty) pw.Text(unit, style: const pw.TextStyle(fontSize: 7, color: _muted), maxLines: 1),
      ],
    ),
  );
}

pw.Widget _legendDot(String text, PdfColor color) {
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Container(width: 8, height: 8, color: color),
      pw.SizedBox(width: 4),
      pw.Text(text, style: const pw.TextStyle(fontSize: 8, color: _ink)),
      pw.SizedBox(width: 12),
    ],
  );
}

pw.Widget _cell(String text, {bool header = false, pw.Alignment align = pw.Alignment.centerLeft}) {
  return pw.Container(
    alignment: align,
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 8,
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
  final bool isToday = data.dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());
  final segments = data.segments.isNotEmpty ? data.segments : <int, String>{0: 'Motor 1'};
  final motor = data.motorData;

  final slides = <pw.Widget>[];

  // Header Block at top of report
  slides.addAll([
    pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PUMP LOG REPORT',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _teal, letterSpacing: 2)),
              pw.SizedBox(height: 2),
              pw.Text(data.deviceName.isEmpty ? 'Pump Controller' : data.deviceName,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _ink)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Date: ${data.dateStr}', style: const pw.TextStyle(fontSize: 9, color: _ink)),
              pw.Text('Period: ${data.periodStr}', style: const pw.TextStyle(fontSize: 9, color: _muted)),
              if (data.deviceId.isNotEmpty)
                pw.Text('Device MAC: ${data.deviceId}', style: const pw.TextStyle(fontSize: 8, color: _muted)),
            ],
          ),
        ],
      ),
    ),
    pw.Container(height: 1.5, color: _teal),
    pw.SizedBox(height: 10),
  ]);

  // Section: Overview
  slides.add(_slideTitle('Overview', subtitle: '${data.dateStr}  |  ${data.periodStr}'));

  final flowRateInfo = _pdfFlowRate(motor, data.periodStr);
  final String powerOffVal = _powerOffTime(motor);

  // Motor KPIs and pump log sections per motor
  for (final e in segments.entries) {
    final st = _motorStats(motor, e.key);
    final events = _eventsFor(data, e.key);

    slides.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: 4 Rows x 3 Columns KPI Cards (12 metrics)
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _kpiRow([
                  _compactKpi('Total power ON', _hms(_secs(motor?.totalPowerOnTime ?? '00:00:00')), 'HH:MM:SS', accent: _green),
                  _compactKpi('Total power OFF', powerOffVal, 'HH:MM:SS', accent: _red),
                  _compactKpi('Cumulative flow', motor?.overAllCumulativeFlow ?? '0', 'Litres'),
                ]),
                pw.SizedBox(height: 5),
                _kpiRow([
                  _compactKpi('Pressure', motor?.pressure ?? '0.0', 'bar'),
                  _compactKpi(flowRateInfo.label, flowRateInfo.value, 'Lps'),
                  _compactKpi('Level', motor?.level ?? '0.0', 'feet'),
                ]),
                pw.SizedBox(height: 5),
                _kpiRow([
                  _compactKpi('${e.value} Run time', st.run, 'HH:MM:SS', accent: _green),
                  _compactKpi('Idle time', st.idle, 'HH:MM:SS'),
                  _compactKpi('Dry run trip', st.dry, 'HH:MM:SS', accent: _red),
                ]),
                pw.SizedBox(height: 5),
                _kpiRow([
                  _compactKpi('Cyclic trip', st.cyclic, 'HH:MM:SS', accent: _amber),
                  _compactKpi('Other trip', st.other, 'HH:MM:SS', accent: _red),
                  _compactKpi('Total flow', st.flow, 'Litres', accent: _blue),
                ]),
              ],
            ),
          ),
          pw.SizedBox(width: 12),

          // Right: Big Pie Chart (Time distribution)
          pw.Expanded(
            flex: 4,
            child: _buildBigPieChart(st),
          ),
        ],
      ),
    );

    // Pump log section
    slides.addAll([
      pw.SizedBox(height: 12),
      _slideTitle('${e.value} - Pump log', subtitle: '${events.length} event(s)  |  ${data.dateStr}'),
    ]);
    if (events.isEmpty) {
      slides.add(pw.Text('No events recorded for this period.',
          style: const pw.TextStyle(fontSize: 9.5, color: _muted)));
    } else {
      slides.addAll([
        pw.Text('ON periods across 24 hours',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink)),
        pw.SizedBox(height: 4),
        _timeline(events, isToday: isToday),
        pw.SizedBox(height: 8),
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

  // Voltage / current section (grouped by date, newest first)
  final voltageRows = data.voltageData;
  if (voltageRows.isNotEmpty) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final r in voltageRows) {
      final String d = r['date']?.toString() ?? r['logDate']?.toString() ?? '';
      grouped.putIfAbsent(d, () => []).add(r);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    slides.addAll([
      pw.SizedBox(height: 12),
      _slideTitle('Voltage & Current Hourly Log', subtitle: data.dateStr),
      pw.SizedBox(height: 4),
    ]);

    for (final dStr in sortedDates) {
      slides.add(_buildVoltagePdfTable(grouped.length > 1 ? dStr : '', grouped[dStr]!));
      slides.add(pw.SizedBox(height: 10));
    }
  }

  doc.addPage(pw.MultiPage(
    pageFormat: fmt,
    margin: const pw.EdgeInsets.fromLTRB(36, 28, 36, 28),
    header: (ctx) => ctx.pageNumber == 1
        ? pw.SizedBox.shrink()
        : pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Pump Log Report - ${data.deviceName}', style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
                pw.Text('Date: ${data.dateStr}', style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
              ],
            ),
          ),
    footer: (ctx) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Page ${ctx.pageNumber}', style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
          pw.Text('Niagara Automations', style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
        ],
      ),
    ),
    build: (ctx) => slides,
  ));

  return await doc.save();
}

pw.Widget _timeline(List<EventLog> events, {required bool isToday}) {
  const double w = 722; // Printable width on landscape A4 (842 - 80)
  const double barH = 18;
  final now = DateTime.now();
  final nowMin = now.hour * 60 + now.minute;

  final bars = <pw.Widget>[];
  final labels = <pw.Widget>[];

  for (final e in events) {
    final s = _minutes(e.onTime);
    if (s == null) continue;
    var f = _minutes(e.offTime) ?? (isToday ? nowMin : 1440);
    if (f < s) f = s;
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
            borderRadius: pw.BorderRadius.circular(2),
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
      top: barH + 2,
      child: pw.SizedBox(
        width: 30,
        child: pw.Text(
          '${h.toString().padLeft(2, '0')}:00',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 7.5, color: _muted),
        ),
      ),
    ));
  }

  return pw.SizedBox(
    width: w,
    height: barH + 12,
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

pw.Widget _buildVoltagePdfTable(String dateStr, List<Map<String, dynamic>> rows) {
  final headers = ['Hour', 'Voltage R (V)', 'Voltage Y (V)', 'Voltage B (V)', 'Current R (A)', 'Current Y (A)', 'Current B (A)'];
  final flex = [0.8, 1.2, 1.2, 1.2, 1.2, 1.2, 1.2];

  return pw.Table(
    border: pw.TableBorder.all(color: _border, width: 0.6),
    columnWidths: {for (int i = 0; i < flex.length; i++) i: pw.FlexColumnWidth(flex[i])},
    children: [
      if (dateStr.isNotEmpty)
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _tealLight),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text('Date: $dateStr',
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _teal)),
            ),
            for (int i = 0; i < 6; i++) pw.Container(),
          ],
        ),
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

pw.Widget _buildBigPieChart(_MotorStats st) {
  final items = [
    (label: 'Run time', value: st.run, secs: _secs(st.run), color: _green),
    (label: 'Idle time', value: st.idle, secs: _secs(st.idle), color: PdfColors.grey500),
    (label: 'Dry run trip', value: st.dry, secs: _secs(st.dry), color: _red),
    (label: 'Cyclic trip', value: st.cyclic, secs: _secs(st.cyclic), color: _amber),
    (label: 'Other trip', value: st.other, secs: _secs(st.other), color: _blue),
  ];

  final total = items.fold<int>(0, (s, i) => s + i.secs);
  if (total == 0) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _border, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      alignment: pw.Alignment.center,
      child: pw.Text('No run-time data recorded for this period.',
          style: const pw.TextStyle(fontSize: 9.5, color: _muted)),
    );
  }

  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: _border, width: 0.8),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(width: 3, height: 12, color: _teal),
            pw.SizedBox(width: 6),
            pw.Text(
              'TIME DISTRIBUTION',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Left: Donut Chart with Center Text
            pw.Stack(
              alignment: pw.Alignment.center,
              children: [
                pw.SizedBox(
                  width: 135,
                  height: 135,
                  child: pw.Chart(
                    grid: pw.PieGrid(),
                    datasets: [
                      for (final item in items)
                        if (item.secs > 0)
                          pw.PieDataSet(
                            legend: '',
                            value: item.secs,
                            color: item.color,
                          ),
                    ],
                  ),
                ),
                pw.Container(
                  width: 58,
                  height: 58,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.white,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('Total time', style: const pw.TextStyle(fontSize: 6, color: _muted)),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        _hms(total),
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _ink),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text('hh:mm:ss', style: const pw.TextStyle(fontSize: 5.5, color: _muted)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(width: 12),

            // Right: Legend Cards with Color Indicator & Accent Line
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  for (final item in items)
                    if (item.secs > 0)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey50,
                          border: pw.Border.all(color: _border, width: 0.6),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Row(
                                  children: [
                                    pw.Container(
                                      width: 6,
                                      height: 6,
                                      decoration: pw.BoxDecoration(
                                        color: item.color,
                                        borderRadius: pw.BorderRadius.circular(1.5),
                                      ),
                                    ),
                                    pw.SizedBox(width: 4),
                                    pw.Text(
                                      item.label,
                                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _ink),
                                    ),
                                  ],
                                ),
                                pw.Text(
                                  '${(item.secs * 100 / total).toStringAsFixed(1)}%',
                                  style: const pw.TextStyle(fontSize: 7, color: _muted),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              item.value,
                              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _ink),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Container(
                              height: 1.5,
                              width: 32,
                              decoration: pw.BoxDecoration(
                                color: item.color,
                                borderRadius: pw.BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

