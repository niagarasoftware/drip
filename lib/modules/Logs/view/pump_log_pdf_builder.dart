import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'pump_log_excel_builder.dart';

class _PdfPageData {
  final String sectionTitle;
  final List<Map<String, dynamic>> headers;
  final List<List<String>> rows;

  _PdfPageData({
    required this.sectionTitle,
    required this.headers,
    required this.rows,
  });
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

  void chunkSection(String title, List<Map<String, dynamic>> headers, List<List<String>> rows) {
    int count = rows.length;
    int pages = (count == 0) ? 1 : (count / recordsPerPage).ceil();
    for (int p = 0; p < pages; p++) {
      int start = p * recordsPerPage;
      int end = (start + recordsPerPage < count) ? start + recordsPerPage : count;
      allPages.add(_PdfPageData(
        sectionTitle: title,
        headers: headers,
        rows: count == 0 ? [] : rows.sublist(start, end),
      ));
    }
  }

  chunkSection('PUMP LOG', pumpHeaders, pumpRows);
  chunkSection('VOLTAGE & CURRENT LOG', voltageHeaders, voltageRows);
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
      bool isEven = (r % 2 == 0);
      if (isEven) {
        streamBuf.write("0.97 0.98 0.99 rg 40 ${currentY - 4} 762 17 re f\n");
      }
      streamBuf.write("0.88 0.90 0.92 RG 0.5 w 40 ${currentY - 4} 762 17 re S\n");
      streamBuf.write("0.15 0.15 0.15 rg\n");

      for (int c = 0; c < pageData.headers.length; c++) {
        int xPos = pageData.headers[c]['x'] as int;
        int maxL = pageData.headers[c]['max'] as int;
        String val = c < rowValues.length ? rowValues[c] : '-';
        if (val.length > maxL) {
          val = "${val.substring(0, maxL - 1)}..";
        }
        String safeVal = sanitizePdfText(val);
        streamBuf.write("BT /F2 8 Tf $xPos $currentY Td ($safeVal) Tj ET\n");
      }

      currentY -= 17;
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
