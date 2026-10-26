import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'pump_log_excel_builder.dart';

class _PdfPageData {
  final String sectionTitle;
  final List<Map<String, dynamic>> headers;
  final List<List<String>> rows;
  final List<String>? summaryRow;
  final bool isLastSectionPage;

  _PdfPageData({
    required this.sectionTitle,
    required this.headers,
    required this.rows,
    this.summaryRow,
    this.isLastSectionPage = false,
  });
}

List<String> _wrapTextLines(String text, int maxCharsPerLine, {int maxLines = 2}) {
  final cleanText = text.trim();
  if (cleanText.isEmpty || cleanText == '-') return ['-'];
  if (cleanText.length <= maxCharsPerLine) return [cleanText];

  List<String> lines = [];
  String remaining = cleanText;

  while (remaining.isNotEmpty && lines.length < maxLines) {
    if (remaining.length <= maxCharsPerLine) {
      lines.add(remaining);
      break;
    }

    if (lines.length == maxLines - 1) {
      if (remaining.length <= maxCharsPerLine + 3) {
        lines.add(remaining);
      } else {
        lines.add(remaining.substring(0, maxCharsPerLine));
      }
      break;
    }

    int breakIndex = -1;
    final searchSub = remaining.substring(0, maxCharsPerLine + 1);

    for (String delim in ['__', ' ', ',', '/', '-']) {
      int idx = searchSub.lastIndexOf(delim);
      if (idx > 0 && idx < maxCharsPerLine) {
        if (idx > breakIndex) breakIndex = idx + (delim == ' ' ? 0 : delim.length);
      }
    }

    if (breakIndex <= 0) {
      breakIndex = maxCharsPerLine;
    }

    lines.add(remaining.substring(0, breakIndex).trim());
    remaining = remaining.substring(breakIndex).trim();
    if (remaining.startsWith('__')) remaining = remaining.substring(2);
  }

  return lines.isEmpty ? ['-'] : lines;
}

int _parsePumpDurationSec(String val) {
  final clean = val.trim();
  if (clean.isEmpty || clean == '-') return 0;
  final parts = clean.split(':');
  if (parts.length == 3) {
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final s = int.tryParse(parts[2]) ?? 0;
    return h * 3600 + m * 60 + s;
  } else if (parts.length == 2) {
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 3600 + m * 60;
  }
  return 0;
}

String _formatPumpSecs(int secs) {
  if (secs <= 0) return "00:00:00";
  int h = secs ~/ 3600;
  int m = (secs % 3600) ~/ 60;
  int s = secs % 60;
  return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
}

Uint8List generatePumpLogPdfBytes(PumpLogExportData exportData, String fileName) {
  final List<int> pdfBytes = [];
  final List<int> offsets = [0];

  void writeString(String s) {
    pdfBytes.addAll(utf8.encode(s));
  }

  void startObj(int id) {
    while (offsets.length <= id) {
      offsets.add(0);
    }
    offsets[id] = pdfBytes.length;
    writeString("$id 0 obj\n");
  }

  String sanitizePdfText(String txt) {
    return txt
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  // ---------------------------------------------------------------------------
  // 1. COLLECT DATA FOR ALL 3 SECTIONS
  // ---------------------------------------------------------------------------

  const int recordsPerPage = 20;

  // --- SECTION 1: PUMP LOG ---
  final segments = exportData.segments.isNotEmpty
      ? exportData.segments
      : {0: 'Motor 1'};

  List<List<String>> pumpRows = [];
  segments.forEach((key, motorName) {
    List events = [];
    if (key == 0) events = exportData.motor1Events;
    if (key == 1) events = exportData.motor2Events;
    if (key == 2) events = exportData.motor3Events;

    if (events.isEmpty) {
      pumpRows.add([motorName, '-', '-', '-', 'No events recorded', '-']);
    } else {
      for (final e in events) {
        pumpRows.add([
          motorName,
          e.onTime.isNotEmpty ? e.onTime : '-',
          e.offTime.isNotEmpty ? e.offTime : '-',
          e.duration.isNotEmpty ? e.duration : '-',
          e.onReason.isNotEmpty ? e.onReason : '-',
          e.offReason.isNotEmpty ? e.offReason : '-',
        ]);
      }
    }
  });

  final pumpHeaders = [
    {'title': 'Motor/Pump', 'x': 45, 'max': 12},
    {'title': 'On Time', 'x': 130, 'max': 10},
    {'title': 'Off Time', 'x': 200, 'max': 10},
    {'title': 'Duration', 'x': 270, 'max': 10},
    {'title': 'On Reason', 'x': 350, 'max': 30},
    {'title': 'Off Reason', 'x': 570, 'max': 30},
  ];

  int totalPumpSecs = 0;
  for (final r in pumpRows) {
    if (r.length > 3) {
      totalPumpSecs += _parsePumpDurationSec(r[3]);
    }
  }
  final pumpSummaryRow = [
    'Total (${pumpRows.length} events)',
    '-',
    '-',
    _formatPumpSecs(totalPumpSecs),
    '-',
    '-',
  ];

  // --- SECTION 2: VOLTAGE & CURRENT LOG ---
  List<List<String>> voltageRows = [];
  if (exportData.voltageData.isEmpty) {
    voltageRows.add(['-', '-', '-', '-', '-', '-', '-']);
  } else {
    for (final r in exportData.voltageData) {
      voltageRows.add([
        '${r['hour'] ?? '-'}',
        '${r['voltageR'] ?? '-'}',
        '${r['voltageY'] ?? '-'}',
        '${r['voltageB'] ?? '-'}',
        '${r['currentR'] ?? '-'}',
        '${r['currentY'] ?? '-'}',
        '${r['currentB'] ?? '-'}',
      ]);
    }
  }

  final voltageHeaders = [
    {'title': 'Hour', 'x': 45, 'max': 8},
    {'title': 'Voltage R (V)', 'x': 120, 'max': 12},
    {'title': 'Voltage Y (V)', 'x': 230, 'max': 12},
    {'title': 'Voltage B (V)', 'x': 340, 'max': 12},
    {'title': 'Current R (A)', 'x': 450, 'max': 12},
    {'title': 'Current Y (A)', 'x': 560, 'max': 12},
    {'title': 'Current B (A)', 'x': 670, 'max': 12},
  ];

  double sumVR = 0, sumVY = 0, sumVB = 0;
  double sumCR = 0, sumCY = 0, sumCB = 0;
  int vCount = 0;

  for (final r in voltageRows) {
    if (r.length >= 7 && r[0] != '-') {
      double? vr = double.tryParse(r[1]);
      double? vy = double.tryParse(r[2]);
      double? vb = double.tryParse(r[3]);
      double? cr = double.tryParse(r[4]);
      double? cy = double.tryParse(r[5]);
      double? cb = double.tryParse(r[6]);
      if (vr != null) {
        sumVR += vr; sumVY += (vy ?? 0); sumVB += (vb ?? 0);
        sumCR += (cr ?? 0); sumCY += (cy ?? 0); sumCB += (cb ?? 0);
        vCount++;
      }
    }
  }

  List<String>? voltageSummaryRow;
  if (vCount > 0) {
    voltageSummaryRow = [
      'Average',
      '${(sumVR / vCount).round()} V',
      '${(sumVY / vCount).round()} V',
      '${(sumVB / vCount).round()} V',
      '${(sumCR / vCount).toStringAsFixed(1)} A',
      '${(sumCY / vCount).toStringAsFixed(1)} A',
      '${(sumCB / vCount).toStringAsFixed(1)} A',
    ];
  }

  // --- SECTION 3: POWER GRAPH SUMMARY ---
  List<List<String>> powerRows = [];
  final md = exportData.motorData;

  powerRows.add(['Total Power On Time', md?.totalPowerOnTime ?? '00:00:00', 'HH:MM:SS']);
  powerRows.add(['Total Power Off Time', md?.totalPowerOffTime ?? '00:00:00', 'HH:MM:SS']);
  powerRows.add(['Cumulative Flow', md?.overAllCumulativeFlow ?? '0', 'Litres']);
  powerRows.add(['Pressure', md?.pressure ?? '0.0', 'bar']);
  powerRows.add(['Flow Rate', md?.flowRate ?? '0.0', 'Lps']);
  powerRows.add(['Level', md?.level ?? '0.0', 'feet']);

  segments.forEach((key, motorName) {
    String runTime = md?.motorRunTime1 ?? '00:00:00';
    String idleTime = md?.motorIdleTime1 ?? '00:00:00';
    String dryRun = md?.dryRunTripTime1 ?? '00:00:00';
    String cyclic = md?.cyclicTripTime1 ?? '00:00:00';
    String other = md?.otherTripTime1 ?? '00:00:00';
    String totalFlow = md?.totalFlowToday1 ?? '0';

    if (key == 1 && md != null) {
      runTime = md.motorRunTime2;
      idleTime = md.motorIdleTime2;
      dryRun = md.dryRunTripTime2;
      cyclic = md.cyclicTripTime2;
      other = md.otherTripTime2;
      totalFlow = md.totalFlowToday2;
    } else if (key == 2 && md != null) {
      runTime = md.motorRunTime3;
      idleTime = md.motorIdleTime3;
      dryRun = md.dryRunTripTime3;
      cyclic = md.cyclicTripTime3;
      other = md.otherTripTime3;
      totalFlow = md.totalFlowToday3;
    }

    powerRows.add(['$motorName Run Time', runTime, 'HH:MM:SS']);
    powerRows.add(['$motorName Idle Time', idleTime, 'HH:MM:SS']);
    powerRows.add(['$motorName Dry Run Trip Time', dryRun, 'HH:MM:SS']);
    powerRows.add(['$motorName Cyclic Trip Time', cyclic, 'HH:MM:SS']);
    powerRows.add(['$motorName Other Trip Time', other, 'HH:MM:SS']);
    powerRows.add(['$motorName Total Flow Today', totalFlow, 'Litres']);
  });

  final powerHeaders = [
    {'title': 'Metric', 'x': 45, 'max': 35},
    {'title': 'Value', 'x': 350, 'max': 25},
    {'title': 'Unit', 'x': 580, 'max': 15},
  ];

  // ---------------------------------------------------------------------------
  // 2. CHUNK ROWS INTO PAGES
  // ---------------------------------------------------------------------------
  List<_PdfPageData> allPages = [];

  void chunkSection(String title, List<Map<String, dynamic>> headers, List<List<String>> rows, {List<String>? summaryRow}) {
    int count = rows.length;
    int pages = (count == 0) ? 1 : (count / recordsPerPage).ceil();
    for (int p = 0; p < pages; p++) {
      int start = p * recordsPerPage;
      int end = (start + recordsPerPage < count) ? start + recordsPerPage : count;
      allPages.add(_PdfPageData(
        sectionTitle: title,
        headers: headers,
        rows: count == 0 ? [] : rows.sublist(start, end),
        summaryRow: summaryRow,
        isLastSectionPage: (p == pages - 1),
      ));
    }
  }

  chunkSection('PUMP LOG', pumpHeaders, pumpRows, summaryRow: pumpSummaryRow);
  chunkSection('VOLTAGE & CURRENT LOG', voltageHeaders, voltageRows, summaryRow: voltageSummaryRow);
  chunkSection('POWER GRAPH SUMMARY', powerHeaders, powerRows);

  int numPages = allPages.length;

  // ---------------------------------------------------------------------------
  // 3. WRITE PDF OBJECTS
  // ---------------------------------------------------------------------------
  writeString("%PDF-1.4\n%\xFF\xFF\xFF\xFF\n");

  startObj(1);
  writeString("<< /Type /Catalog /Pages 2 0 R >>\nendobj\n");

  startObj(2);
  StringBuffer kidsBuf = StringBuffer();
  for (int i = 0; i < numPages; i++) {
    int pageObjId = 6 + i * 2;
    kidsBuf.write("$pageObjId 0 R ");
  }
  writeString("<< /Type /Pages /Kids [ ${kidsBuf.toString().trim()} ] /Count $numPages >>\nendobj\n");

  startObj(3);
  writeString("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj\n");

  startObj(4);
  writeString("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n");

  startObj(5);
  writeString("<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>\nendobj\n");

  final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  for (int p = 0; p < numPages; p++) {
    int pageObjId = 6 + p * 2;
    int contentObjId = 6 + p * 2 + 1;
    final pageData = allPages[p];

    startObj(pageObjId);
    writeString("<< /Type /Page /Parent 2 0 R /MediaBox [ 0 0 842 595 ] /Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R >> >> /Contents $contentObjId 0 R >>\nendobj\n");

    StringBuffer streamBuf = StringBuffer();

    // Title
    streamBuf.write("0.0 0.4 0.46 rg\n"); // Teal color
    streamBuf.write("BT /F1 15 Tf 40 555 Td (${sanitizePdfText("PUMP DASHBOARD REPORT - ${exportData.deviceName}")}) Tj ET\n");

    // Subheader / Metadata
    streamBuf.write("0.4 0.4 0.4 rg\n");
    String metaStr = "Section: ${pageData.sectionTitle}  |  Date: ${exportData.dateStr}  |  Period: ${exportData.periodStr}  |  MAC: ${exportData.deviceId}  |  Generated: $nowStr";
    streamBuf.write("BT /F2 8 Tf 40 538 Td (${sanitizePdfText(metaStr)}) Tj ET\n");

    // Table Header Box
    streamBuf.write("0.90 0.93 0.96 rg 40 508 762 22 re f\n");
    streamBuf.write("0.75 0.80 0.85 RG 0.8 w 40 508 762 22 re S\n");

    streamBuf.write("0.1 0.1 0.1 rg\n");
    for (var h in pageData.headers) {
      String titleTxt = sanitizePdfText(h['title'] as String);
      int xPos = h['x'] as int;
      streamBuf.write("BT /F1 9 Tf $xPos 515 Td ($titleTxt) Tj ET\n");
    }

    double currentY = 488;
    for (int r = 0; r < pageData.rows.length; r++) {
      var rowValues = pageData.rows[r];

      int maxRowLines = 1;
      List<List<String>> cellLines = [];
      for (int c = 0; c < pageData.headers.length; c++) {
        int maxL = pageData.headers[c]['max'] as int;
        String val = c < rowValues.length ? rowValues[c] : '-';
        List<String> lines = _wrapTextLines(val, maxL, maxLines: 2);
        cellLines.add(lines);
        if (lines.length > maxRowLines) maxRowLines = lines.length;
      }

      double rHeight = 12.0 + (maxRowLines * 9.5);
      double drawTop = currentY - rHeight + 14;

      bool isEven = (r % 2 == 0);
      if (isEven) {
        streamBuf.write("0.97 0.98 0.99 rg 40 $drawTop 762 $rHeight re f\n");
      }
      streamBuf.write("0.88 0.90 0.92 RG 0.5 w 40 $drawTop 762 $rHeight re S\n");
      streamBuf.write("0.15 0.15 0.15 rg\n");

      for (int c = 0; c < pageData.headers.length; c++) {
        int xPos = pageData.headers[c]['x'] as int;
        List<String> lines = cellLines[c];
        for (int lIdx = 0; lIdx < lines.length; lIdx++) {
          double lineY = currentY - (lIdx * 9.5);
          streamBuf.write("BT /F2 8 Tf $xPos $lineY Td (${sanitizePdfText(lines[lIdx])}) Tj ET\n");
        }
      }

      currentY -= rHeight;
    }

    // BOTTOM SUMMARY ROW FOR THIS SECTION
    if (pageData.isLastSectionPage && pageData.summaryRow != null && pageData.summaryRow!.isNotEmpty) {
      final summaryVals = pageData.summaryRow!;
      int maxSumLines = 1;
      List<List<String>> sumCellLines = [];
      for (int c = 0; c < pageData.headers.length; c++) {
        int maxL = pageData.headers[c]['max'] as int;
        String val = c < summaryVals.length ? summaryVals[c] : '-';
        List<String> lines = _wrapTextLines(val, maxL, maxLines: 2);
        sumCellLines.add(lines);
        if (lines.length > maxSumLines) maxSumLines = lines.length;
      }

      double sHeight = 13.0 + (maxSumLines * 9.5);
      double drawTop = currentY - sHeight + 14;

      // Highlighted summary background box
      streamBuf.write("0.85 0.92 0.94 rg 40 $drawTop 762 $sHeight re f\n");
      streamBuf.write("0.60 0.75 0.80 RG 0.8 w 40 $drawTop 762 $sHeight re S\n");

      streamBuf.write("0.0 0.25 0.35 rg\n");
      for (int c = 0; c < pageData.headers.length; c++) {
        int xPos = pageData.headers[c]['x'] as int;
        List<String> lines = sumCellLines[c];
        for (int lIdx = 0; lIdx < lines.length; lIdx++) {
          double lineY = currentY - (lIdx * 9.5);
          streamBuf.write("BT /F1 8 Tf $xPos $lineY Td (${sanitizePdfText(lines[lIdx])}) Tj ET\n");
        }
      }

      currentY -= sHeight;
    }

    // Page Footer
    streamBuf.write("0.5 0.5 0.5 rg\n");
    streamBuf.write("BT /F2 8 Tf 40 20 Td (${sanitizePdfText("Page ${p + 1} of $numPages")}) Tj ET\n");

    List<int> streamBytes = utf8.encode(streamBuf.toString());

    startObj(contentObjId);
    writeString("<< /Length ${streamBytes.length} >>\nstream\n");
    pdfBytes.addAll(streamBytes);
    writeString("\nendstream\nendobj\n");
  }

  // Cross-reference table
  int xrefOffset = pdfBytes.length;
  int totalObjects = 6 + numPages * 2;

  writeString("xref\n0 $totalObjects\n0000000000 65535 f \n");
  for (int i = 1; i < totalObjects; i++) {
    int off = offsets[i];
    String offStr = off.toString().padLeft(10, '0');
    writeString("$offStr 00000 n \n");
  }

  writeString("trailer\n<< /Size $totalObjects /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n");

  return Uint8List.fromList(pdfBytes);
}
