import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

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

Uint8List generateZoneLogPdfBytes(List<dynamic> records, String fileName) {
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

  writeString("%PDF-1.4\n%\xFF\xFF\xFF\xFF\n");

  int totalRecords = records.length;
  int recordsPerPage = 20;
  int numPages = (totalRecords == 0) ? 1 : (totalRecords / recordsPerPage).ceil();

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

  String sanitizePdfText(String txt) {
    return txt
        .replaceAll('\n', ' ')
        .replaceAll('\r', '')
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  for (int p = 0; p < numPages; p++) {
    int pageObjId = 6 + p * 2;
    int contentObjId = 6 + p * 2 + 1;

    startObj(pageObjId);
    writeString("<< /Type /Page /Parent 2 0 R /MediaBox [ 0 0 842 595 ] /Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R >> >> /Contents $contentObjId 0 R >>\nendobj\n");

    StringBuffer streamBuf = StringBuffer();

    streamBuf.write("0.12 0.23 0.37 rg\n");
    streamBuf.write("BT /F1 15 Tf 40 555 Td (${sanitizePdfText("ZONE LOG REPORT - $fileName")}) Tj ET\n");
    streamBuf.write("0.4 0.4 0.4 rg\n");
    streamBuf.write("BT /F2 9 Tf 40 538 Td (${sanitizePdfText("Generated on: $nowStr")}) Tj ET\n");

    streamBuf.write("0.90 0.93 0.96 rg 40 508 762 22 re f\n");
    streamBuf.write("0.75 0.80 0.85 RG 0.8 w 40 508 762 22 re S\n");

    final headers = [
      {'title': 'Date', 'x': 45, 'max': 14},
      {'title': 'Program Name', 'x': 115, 'max': 16},
      {'title': 'Sequence Name', 'x': 200, 'max': 16},
      {'title': 'HeadUnit', 'x': 285, 'max': 10},
      {'title': 'Pump', 'x': 345, 'max': 8},
      {'title': 'Start', 'x': 395, 'max': 10},
      {'title': 'End', 'x': 455, 'max': 10},
      {'title': 'Duration', 'x': 515, 'max': 10},
      {'title': 'Start Reason', 'x': 575, 'max': 20},
      {'title': 'End Reason', 'x': 685, 'max': 20},
    ];

    streamBuf.write("0.1 0.1 0.1 rg\n");
    for (var h in headers) {
      String titleTxt = sanitizePdfText(h['title'] as String);
      int xPos = h['x'] as int;
      streamBuf.write("BT /F1 9 Tf $xPos 515 Td ($titleTxt) Tj ET\n");
    }

    int startIdx = p * recordsPerPage;
    int endIdx = (startIdx + recordsPerPage < totalRecords) ? startIdx + recordsPerPage : totalRecords;

    double yPos = 485;
    for (int r = startIdx; r < endIdx; r++) {
      var rec = records[r];
      final rowVals = [
        rec.dateStr ?? '-',
        rec.programTitle ?? '-',
        rec.sequenceTitle ?? '-',
        rec.headUnit ?? '-',
        rec.pump ?? '-',
        rec.startTime ?? '-',
        rec.endTime ?? '-',
        rec.duration ?? '-',
        rec.startReason ?? '-',
        rec.endReason ?? '-',
      ];

      int maxRowLines = 1;
      List<List<String>> cellLines = [];
      for (int c = 0; c < headers.length; c++) {
        int maxL = headers[c]['max'] as int;
        List<String> lines = _wrapTextLines(rowVals[c], maxL, maxLines: 2);
        cellLines.add(lines);
        if (lines.length > maxRowLines) maxRowLines = lines.length;
      }

      double rHeight = 12.0 + (maxRowLines * 9.5);
      double drawTop = yPos - rHeight + 14;

      if (r % 2 == 1) {
        streamBuf.write("0.96 0.97 0.98 rg 40 $drawTop 762 $rHeight re f\n");
      }
      streamBuf.write("0.85 0.88 0.90 RG 0.4 w 40 $drawTop 762 $rHeight re S\n");

      streamBuf.write("0.2 0.2 0.2 rg\n");
      for (int c = 0; c < headers.length; c++) {
        int xPos = headers[c]['x'] as int;
        List<String> lines = cellLines[c];
        for (int lIdx = 0; lIdx < lines.length; lIdx++) {
          double lineY = yPos - (lIdx * 9.5);
          streamBuf.write("BT /F2 8 Tf $xPos $lineY Td (${sanitizePdfText(lines[lIdx])}) Tj ET\n");
        }
      }

      yPos -= rHeight;
    }

    final bytes = utf8.encode(streamBuf.toString());
    startObj(contentObjId);
    writeString("<< /Length ${bytes.length} >>\nstream\n");
    pdfBytes.addAll(bytes);
    writeString("\nendstream\nendobj\n");
  }

  int xrefOffset = pdfBytes.length;
  writeString("xref\n0 ${offsets.length}\n0000000000 65535 f \n");
  for (int i = 1; i < offsets.length; i++) {
    String offStr = offsets[i].toString().padLeft(10, '0');
    writeString("$offStr 00000 n \n");
  }

  writeString("trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n");

  return Uint8List.fromList(pdfBytes);
}

Uint8List generateZoneLogMatrixPdfBytes({
  required List<DateTime> dateColumns,
  required List<dynamic> rows,
  required Map<String, int> dailyTotals,
  Map<String, num>? dailyTotalQuantities,
  required int grandTotalSeconds,
  num grandTotalQuantity = 0,
  required String fileName,
}) {
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

  writeString("%PDF-1.4\n%\xFF\xFF\xFF\xFF\n");

  String sanitizePdfText(String txt) {
    return txt
        .replaceAll('\n', ' ')
        .replaceAll('\r', '')
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  String formatDurWithSecs(int totalSecs) {
    if (totalSecs <= 0) return "0h 0m";
    int h = totalSecs ~/ 3600;
    int m = (totalSecs % 3600) ~/ 60;
    int s = totalSecs % 60;
    if (s > 0) return "${h}h ${m}m ${s}s";
    return "${h}h ${m}m";
  }

  String formatQtyVal(num val) {
    if (val <= 0) return '-';
    num rounded = num.parse(val.toStringAsFixed(2));
    String numStr = (rounded % 1 == 0)
        ? "${rounded.toInt()}"
        : rounded.toStringAsFixed(2);
    return "$numStr L";
  }

  List<String> extractStartEndPairs(dynamic dayData) {
    if (dayData == null) return [];
    List<String> pairs = [];

    void processStartEnd(String sRaw, String eRaw) {
      if ((sRaw.isEmpty || sRaw == '-') && (eRaw.isEmpty || eRaw == '-')) {
        return;
      }
      List<String> starts = sRaw
          .replaceAll(', ', '_')
          .replaceAll(',', '_')
          .split('_')
          .map((s) => s.trim())
          .toList();
      List<String> ends = eRaw
          .replaceAll(', ', '_')
          .replaceAll(',', '_')
          .split('_')
          .map((e) => e.trim())
          .toList();

      int count = math.max(starts.length, ends.length);
      for (int k = 0; k < count; k++) {
        String s = (k < starts.length && starts[k].isNotEmpty) ? starts[k] : '-';
        String e = (k < ends.length && ends[k].isNotEmpty) ? ends[k] : '-';
        if (s == '-' && e == '-') continue;
        String pair = "$s - $e";
        if (!pairs.contains(pair)) {
          pairs.add(pair);
        }
      }
    }

    try {
      if (dayData.runs != null && dayData.runs.isNotEmpty) {
        for (var run in dayData.runs) {
          String s = run.actualStartTime?.toString() ?? '';
          String e = run.actualEndTime?.toString() ?? '';
          processStartEnd(s, e);
        }
      }
    } catch (_) {}

    if (pairs.isEmpty) {
      try {
        String s = dayData.actualStartTime?.toString() ?? '';
        String e = dayData.actualEndTime?.toString() ?? '';
        processStartEnd(s, e);
      } catch (_) {}
    }

    return pairs;
  }

  const int recordsPerPage = 14;
  const int datesPerPage = 5;

  int totalDates = dateColumns.length;
  int dateChunks = (totalDates / datesPerPage).ceil();
  if (dateChunks < 1) dateChunks = 1;

  int totalRecords = rows.length;
  int rowsPagesPerChunk = (totalRecords == 0) ? 1 : (totalRecords / recordsPerPage).ceil();

  List<Map<String, dynamic>> allPages = [];

  for (int dc = 0; dc < dateChunks; dc++) {
    int startDIdx = dc * datesPerPage;
    int endDIdx = (startDIdx + datesPerPage < totalDates) ? startDIdx + datesPerPage : totalDates;
    List<DateTime> chunkDates = dateColumns.sublist(startDIdx, endDIdx);

    for (int p = 0; p < rowsPagesPerChunk; p++) {
      int startRIdx = p * recordsPerPage;
      int endRIdx = (startRIdx + recordsPerPage < totalRecords) ? startRIdx + recordsPerPage : totalRecords;
      List<dynamic> chunkRows = rows.sublist(startRIdx, endRIdx);

      allPages.add({
        'chunkDates': chunkDates,
        'chunkRows': chunkRows,
        'dateChunkIdx': dc + 1,
        'totalDateChunks': dateChunks,
        'rowPageIdx': p + 1,
        'totalRowPages': rowsPagesPerChunk,
      });
    }
  }

  if (allPages.isEmpty) {
    allPages.add({
      'chunkDates': <DateTime>[],
      'chunkRows': [],
      'dateChunkIdx': 1,
      'totalDateChunks': 1,
      'rowPageIdx': 1,
      'totalRowPages': 1,
    });
  }

  int numPages = allPages.length;

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

    startObj(pageObjId);
    writeString("<< /Type /Page /Parent 2 0 R /MediaBox [ 0 0 842 595 ] /Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R >> >> /Contents $contentObjId 0 R >>\nendobj\n");

    final pageData = allPages[p];
    final List<DateTime> chunkDates = List<DateTime>.from(pageData['chunkDates']);
    final List<dynamic> chunkRows = List<dynamic>.from(pageData['chunkRows']);
    final int dateChunkIdx = pageData['dateChunkIdx'];
    final int totalDateChunks = pageData['totalDateChunks'];
    final int rowPageIdx = pageData['rowPageIdx'];
    final int totalRowPages = pageData['totalRowPages'];

    StringBuffer streamBuf = StringBuffer();

    streamBuf.write("0.00 0.40 0.45 rg\n");
    String chunkTitle = totalDateChunks > 1 ? " (Dates Part $dateChunkIdx/$totalDateChunks)" : "";
    streamBuf.write("BT /F1 14 Tf 40 555 Td (${sanitizePdfText("$fileName$chunkTitle")}) Tj ET\n");
    streamBuf.write("0.4 0.4 0.4 rg\n");
    streamBuf.write("BT /F2 9 Tf 40 540 Td (${sanitizePdfText("Generated on: $nowStr  |  Page ${p + 1} of $numPages")}) Tj ET\n");

    int numDates = chunkDates.length;
    double startX = 40.0;
    double tableWidth = 762.0;

    double col0Width = (numDates <= 2)
        ? 180.0
        : (numDates <= 3
            ? 150.0
            : (numDates <= 4 ? 135.0 : 120.0));
    double colTotalWidth = (numDates <= 2) ? 70.0 : (numDates <= 4 ? 58.0 : 52.0);
    double availableDateWidth = tableWidth - col0Width - colTotalWidth;
    double dateBlockWidth = numDates > 0 ? (availableDateWidth / numDates) : availableDateWidth;

    double colDurQtyWidth = numDates <= 4 ? (dateBlockWidth * 0.38).clamp(45.0, 60.0) : 45.0;
    double colTimeWidth = dateBlockWidth - colDurQtyWidth;

    // Header 1 (Top Date Header) & Header 2 (Subheader)
    // Col 0: Unified header block across both header rows (height 34, Y 498 to 532)
    streamBuf.write("0.90 0.95 0.95 rg $startX 498 $col0Width 34 re f\n");
    streamBuf.write("0.70 0.80 0.80 RG 0.8 w $startX 498 $col0Width 34 re S\n");
    streamBuf.write("0.1 0.1 0.1 rg\n");
    streamBuf.write("BT /F1 7.5 Tf ${startX + 4} 512 Td (${sanitizePdfText('Program / Valve / Sequence')}) Tj ET\n");

    // Total Col: Unified header block across both header rows (height 34, Y 498 to 532)
    double totalX = startX + col0Width + (numDates * dateBlockWidth);
    streamBuf.write("0.90 0.95 0.95 rg $totalX 498 $colTotalWidth 34 re f\n");
    streamBuf.write("0.70 0.80 0.80 RG 0.8 w $totalX 498 $colTotalWidth 34 re S\n");
    streamBuf.write("0.1 0.1 0.1 rg\n");
    streamBuf.write("BT /F1 7.5 Tf ${totalX + 4} 512 Td (Total) Tj ET\n");

    // Date Columns Header 1 (Top: Y 514 to 532, height 18)
    for (int d = 0; d < numDates; d++) {
      double dateBlockX = startX + col0Width + (d * dateBlockWidth);
      String dateText = DateFormat('MM/dd (E)').format(chunkDates[d]);
      streamBuf.write("0.90 0.95 0.95 rg $dateBlockX 514 $dateBlockWidth 18 re f\n");
      streamBuf.write("0.70 0.80 0.80 RG 0.8 w $dateBlockX 514 $dateBlockWidth 18 re S\n");
      streamBuf.write("0.1 0.1 0.1 rg\n");
      streamBuf.write("BT /F1 7.5 Tf ${dateBlockX + 4} 520 Td (${sanitizePdfText(dateText)}) Tj ET\n");
    }

    // Date Columns Header 2 (Subheader: Y 498 to 514, height 16)
    for (int d = 0; d < numDates; d++) {
      double dateBlockX = startX + col0Width + (d * dateBlockWidth);
      double durX = dateBlockX + 3;
      double timeX = dateBlockX + colDurQtyWidth + 3;
      double durSepX = dateBlockX + colDurQtyWidth;

      streamBuf.write("0.94 0.97 0.97 rg $dateBlockX 498 $dateBlockWidth 16 re f\n");
      streamBuf.write("0.75 0.82 0.82 RG 0.5 w $dateBlockX 498 $dateBlockWidth 16 re S\n");

      // Sub-separator line between Dur/Qty and Start/End Time
      streamBuf.write("0.80 0.86 0.86 RG 0.4 w $durSepX 498 m $durSepX 514 l S\n");

      streamBuf.write("0.25 0.35 0.35 rg\n");
      streamBuf.write("BT /F1 6.2 Tf $durX 504 Td (Dur / Qty) Tj ET\n");
      streamBuf.write("BT /F1 5.8 Tf $timeX 504 Td (Start / End Time) Tj ET\n");
    }

    double currentY = 498.0;

    for (int r = 0; r < chunkRows.length; r++) {
      final row = chunkRows[r];
      String vName = (row.valveName ?? '').toString();
      String name = "${row.seqName ?? '-'}";
      if (vName.isNotEmpty) {
        name = (row.progName != null &&
                row.progName.isNotEmpty &&
                row.progName != row.seqName)
            ? "${row.progName} - $vName - ${row.seqName}"
            : "$vName - ${row.seqName}";
      } else if (row.progName != null &&
          row.progName.isNotEmpty &&
          row.progName != row.seqName) {
        name = "${row.progName} - ${row.seqName}";
      }

      int maxCharsCol0 = (numDates <= 3) ? 22 : 18;
      List<String> cell0Lines = _wrapTextLines(name, maxCharsCol0, maxLines: 3);

      List<List<String>> rowDurLines = [];
      List<List<String>> rowTimeLines = [];

      int rowTotalSec = 0;
      num rowTotalQty = 0;

      for (int d = 0; d < numDates; d++) {
        String dKey = DateFormat('yyyy-MM-dd').format(chunkDates[d]);
        var dayData = row.dayEntries[dKey];
        List<String> durQtyLines = ["- /", "-"];
        if (dayData != null && dayData.hasRun) {
          int sec = (dayData.durationQtySeconds as int? ?? dayData.durationSeconds as int? ?? 0);
          num qtyVal = (dayData.quantityCompleted as num? ?? dayData.quantity as num? ?? 0);
          String durStr = (dayData.durationQtyStr != null && dayData.durationQtyStr.toString().isNotEmpty)
              ? dayData.durationQtyStr.toString()
              : formatDurWithSecs(sec);
          String qtyStr = qtyVal > 0 ? formatQtyVal(qtyVal) : '-';
          durQtyLines = ["$durStr /", qtyStr];
          rowTotalSec += sec;
          rowTotalQty += qtyVal;
        }
        rowDurLines.add(durQtyLines);

        List<String> pairs = extractStartEndPairs(dayData);
        List<String> timeLines = pairs.isNotEmpty ? pairs : ["-"];
        rowTimeLines.add(timeLines);
      }

      String rDur = rowTotalSec > 0 ? formatDurWithSecs(rowTotalSec) : '-';
      String rQty = rowTotalQty > 0 ? formatQtyVal(rowTotalQty) : '-';
      List<String> totLines = ["$rDur /", rQty];

      int maxRowLines = cell0Lines.length;
      for (int d = 0; d < numDates; d++) {
        if (rowDurLines[d].length > maxRowLines) maxRowLines = rowDurLines[d].length;
        if (rowTimeLines[d].length > maxRowLines) maxRowLines = rowTimeLines[d].length;
      }
      if (totLines.length > maxRowLines) maxRowLines = totLines.length;

      double lineHeight = 8.5;
      double rowHeight = 6.0 + (maxRowLines * lineHeight);
      double rowTop = currentY;
      double rowBottom = currentY - rowHeight;

      if (r % 2 == 1) {
        streamBuf.write("0.97 0.98 0.98 rg $startX $rowBottom $tableWidth $rowHeight re f\n");
      }
      streamBuf.write("0.88 0.90 0.90 RG 0.5 w $startX $rowBottom $tableWidth $rowHeight re S\n");

      // Vertical separator after col 0
      double sepX0 = startX + col0Width;
      streamBuf.write("0.88 0.90 0.90 RG 0.5 w $sepX0 $rowBottom m $sepX0 $rowTop l S\n");

      for (int d = 0; d < numDates; d++) {
        double dDurSep = startX + col0Width + (d * dateBlockWidth) + colDurQtyWidth;
        double dTimeSep = startX + col0Width + ((d + 1) * dateBlockWidth);
        streamBuf.write("0.92 0.94 0.94 RG 0.4 w $dDurSep $rowBottom m $dDurSep $rowTop l S\n");
        streamBuf.write("0.88 0.90 0.90 RG 0.5 w $dTimeSep $rowBottom m $dTimeSep $rowTop l S\n");
      }

      // Draw Col 0 Text
      streamBuf.write("0.15 0.15 0.15 rg\n");
      for (int lIdx = 0; lIdx < cell0Lines.length; lIdx++) {
        double lineY = rowTop - 8.0 - (lIdx * lineHeight);
        streamBuf.write("BT /F2 6.5 Tf ${startX + 4} $lineY Td (${sanitizePdfText(cell0Lines[lIdx])}) Tj ET\n");
      }

      // Draw Date Cells
      for (int d = 0; d < numDates; d++) {
        double durX = startX + col0Width + (d * dateBlockWidth) + 3;
        double timeX = startX + col0Width + (d * dateBlockWidth) + colDurQtyWidth + 3;

        List<String> dLines = rowDurLines[d];
        List<String> tLines = rowTimeLines[d];

        streamBuf.write("0.2 0.2 0.2 rg\n");
        for (int lIdx = 0; lIdx < dLines.length; lIdx++) {
          double lineY = rowTop - 8.0 - (lIdx * lineHeight);
          streamBuf.write("BT /F2 5.8 Tf $durX $lineY Td (${sanitizePdfText(dLines[lIdx])}) Tj ET\n");
        }

        bool hasValidTime = tLines.isNotEmpty && tLines[0] != '-';
        if (hasValidTime) {
          streamBuf.write("0.06 0.46 0.43 rg\n"); // #0F766E
        } else {
          streamBuf.write("0.55 0.60 0.65 rg\n");
        }
        for (int lIdx = 0; lIdx < tLines.length; lIdx++) {
          double lineY = rowTop - 8.0 - (lIdx * lineHeight);
          String fontName = hasValidTime ? "/F1" : "/F2";
          streamBuf.write("BT $fontName 5.5 Tf $timeX $lineY Td (${sanitizePdfText(tLines[lIdx])}) Tj ET\n");
        }
      }

      // Draw Total Column Text
      double totX = startX + col0Width + (numDates * dateBlockWidth) + 3;
      streamBuf.write("0.08 0.50 0.24 rg\n"); // #15803D
      for (int lIdx = 0; lIdx < totLines.length; lIdx++) {
        double lineY = rowTop - 8.0 - (lIdx * lineHeight);
        streamBuf.write("BT /F1 6.5 Tf $totX $lineY Td (${sanitizePdfText(totLines[lIdx])}) Tj ET\n");
      }

      currentY = rowBottom;
    }

    // BOTTOM TOTAL SUMMARY ROW
    if (rowPageIdx == totalRowPages) {
      double footerHeight = 22.0;
      double footTop = currentY;
      double footBottom = currentY - footerHeight;

      streamBuf.write("0.85 0.92 0.94 rg $startX $footBottom $tableWidth $footerHeight re f\n");
      streamBuf.write("0.60 0.75 0.80 RG 0.8 w $startX $footBottom $tableWidth $footerHeight re S\n");

      // Col 0: Total
      streamBuf.write("0.0 0.25 0.35 rg\n");
      streamBuf.write("BT /F1 8.0 Tf ${startX + 4} ${footTop - 13.5} Td (Total) Tj ET\n");

      double sepX0 = startX + col0Width;
      streamBuf.write("0.60 0.75 0.80 RG 0.6 w $sepX0 $footBottom m $sepX0 $footTop l S\n");

      for (int d = 0; d < numDates; d++) {
        String dKey = DateFormat('yyyy-MM-dd').format(chunkDates[d]);
        int daySec = dailyTotals[dKey] ?? 0;
        num dayQty = dailyTotalQuantities?[dKey] ?? 0;
        String dayDur = formatDurWithSecs(daySec);
        String dayQtyStr = dayQty > 0 ? formatQtyVal(dayQty) : '-';

        double durX = startX + col0Width + (d * dateBlockWidth) + 3;
        double timeX = startX + col0Width + (d * dateBlockWidth) + colDurQtyWidth + 3;
        double dDurSep = startX + col0Width + (d * dateBlockWidth) + colDurQtyWidth;
        double dTimeSep = startX + col0Width + ((d + 1) * dateBlockWidth);

        streamBuf.write("0.60 0.75 0.80 RG 0.4 w $dDurSep $footBottom m $dDurSep $footTop l S\n");
        streamBuf.write("0.60 0.75 0.80 RG 0.6 w $dTimeSep $footBottom m $dTimeSep $footTop l S\n");

        streamBuf.write("0.0 0.25 0.35 rg\n");
        streamBuf.write("BT /F1 6.2 Tf $durX ${footTop - 8.0} Td (${sanitizePdfText("$dayDur /")}) Tj ET\n");
        streamBuf.write("BT /F1 6.2 Tf $durX ${footTop - 16.5} Td (${sanitizePdfText(dayQtyStr)}) Tj ET\n");

        streamBuf.write("0.4 0.5 0.5 rg\n");
        streamBuf.write("BT /F1 6.5 Tf $timeX ${footTop - 13.5} Td (-) Tj ET\n");
      }

      String gDur = formatDurWithSecs(grandTotalSeconds);
      String gQty = grandTotalQuantity > 0 ? formatQtyVal(grandTotalQuantity) : '-';
      double totX = startX + col0Width + (numDates * dateBlockWidth) + 3;
      streamBuf.write("0.08 0.50 0.24 rg\n");
      streamBuf.write("BT /F1 6.5 Tf $totX ${footTop - 8.0} Td (${sanitizePdfText("$gDur /")}) Tj ET\n");
      streamBuf.write("BT /F1 6.5 Tf $totX ${footTop - 16.5} Td (${sanitizePdfText(gQty)}) Tj ET\n");

      currentY = footBottom;
    }

    final bytes = utf8.encode(streamBuf.toString());
    startObj(contentObjId);
    writeString("<< /Length ${bytes.length} >>\nstream\n");
    pdfBytes.addAll(bytes);
    writeString("\nendstream\nendobj\n");
  }

  int xrefOffset = pdfBytes.length;
  writeString("xref\n0 ${offsets.length}\n0000000000 65535 f \n");
  for (int i = 1; i < offsets.length; i++) {
    String offStr = offsets[i].toString().padLeft(10, '0');
    writeString("$offStr 00000 n \n");
  }

  writeString("trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n");

  return Uint8List.fromList(pdfBytes);
}

Uint8List generatePumpLogMatrixPdfBytes({
  required List<DateTime> dateColumns,
  required List<dynamic> rows,
  required Map<String, int> dailyRunTotals,
  required Map<String, int> dailyPowerOnTotals,
  required Map<String, int> dailyPowerOffTotals,
  required int grandTotalRunSeconds,
  required int grandTotalPowerOnSeconds,
  required int grandTotalPowerOffSeconds,
  required String fileName,
}) {
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

  writeString("%PDF-1.4\n%\xFF\xFF\xFF\xFF\n");

  String sanitizePdfText(String txt) {
    return txt
        .replaceAll('\n', ' ')
        .replaceAll('\r', '')
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  String formatDur(int totalSecs) {
    if (totalSecs <= 0) return "0h 0m";
    int h = totalSecs ~/ 3600;
    int m = (totalSecs % 3600) ~/ 60;
    int s = totalSecs % 60;
    if (s > 0) return "${h}h ${m}m ${s}s";
    return "${h}h ${m}m";
  }

  String formatHMS(int totalSecs) {
    int h = totalSecs ~/ 3600;
    int m = (totalSecs % 3600) ~/ 60;
    int s = totalSecs % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  const int recordsPerPage = 10;
  const int datesPerPage = 6;

  int totalDates = dateColumns.length;
  int dateChunks = (totalDates / datesPerPage).ceil();
  if (dateChunks < 1) dateChunks = 1;

  int totalRecords = rows.length;
  int rowsPagesPerChunk =
      (totalRecords == 0) ? 1 : (totalRecords / recordsPerPage).ceil();

  List<Map<String, dynamic>> allPages = [];

  for (int dc = 0; dc < dateChunks; dc++) {
    int startDIdx = dc * datesPerPage;
    int endDIdx = (startDIdx + datesPerPage < totalDates)
        ? startDIdx + datesPerPage
        : totalDates;
    List<DateTime> chunkDates = dateColumns.sublist(startDIdx, endDIdx);

    for (int p = 0; p < rowsPagesPerChunk; p++) {
      int startRIdx = p * recordsPerPage;
      int endRIdx = (startRIdx + recordsPerPage < totalRecords)
          ? startRIdx + recordsPerPage
          : totalRecords;
      List<dynamic> chunkRows = rows.sublist(startRIdx, endRIdx);

      allPages.add({
        'chunkDates': chunkDates,
        'chunkRows': chunkRows,
        'dateChunkIdx': dc + 1,
        'totalDateChunks': dateChunks,
        'rowPageIdx': p + 1,
        'totalRowPages': rowsPagesPerChunk,
      });
    }
  }

  if (allPages.isEmpty) {
    allPages.add({
      'chunkDates': <DateTime>[],
      'chunkRows': [],
      'dateChunkIdx': 1,
      'totalDateChunks': 1,
      'rowPageIdx': 1,
      'totalRowPages': 1,
    });
  }

  int numPages = allPages.length;

  startObj(1);
  writeString("<< /Type /Catalog /Pages 2 0 R >>\nendobj\n");

  startObj(2);
  StringBuffer kidsBuf = StringBuffer();
  for (int i = 0; i < numPages; i++) {
    int pageObjId = 6 + i * 2;
    kidsBuf.write("$pageObjId 0 R ");
  }
  writeString(
      "<< /Type /Pages /Kids [ ${kidsBuf.toString().trim()} ] /Count $numPages >>\nendobj\n");

  startObj(3);
  writeString(
      "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj\n");

  startObj(4);
  writeString("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n");

  startObj(5);
  writeString("<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>\nendobj\n");

  final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  for (int p = 0; p < numPages; p++) {
    int pageObjId = 6 + p * 2;
    int contentObjId = 6 + p * 2 + 1;

    startObj(pageObjId);
    writeString(
        "<< /Type /Page /Parent 2 0 R /MediaBox [ 0 0 842 595 ] /Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R >> >> /Contents $contentObjId 0 R >>\nendobj\n");

    final pageData = allPages[p];
    final List<DateTime> chunkDates =
        List<DateTime>.from(pageData['chunkDates']);
    final List<dynamic> chunkRows = List<dynamic>.from(pageData['chunkRows']);
    final int dateChunkIdx = pageData['dateChunkIdx'];
    final int totalDateChunks = pageData['totalDateChunks'];
    final int rowPageIdx = pageData['rowPageIdx'];
    final int totalRowPages = pageData['totalRowPages'];

    StringBuffer streamBuf = StringBuffer();

    streamBuf.write("0.00 0.40 0.45 rg\n");
    String chunkTitle =
        totalDateChunks > 1 ? " (Dates Part $dateChunkIdx/$totalDateChunks)" : "";
    streamBuf.write(
        "BT /F1 14 Tf 40 555 Td (${sanitizePdfText("$fileName$chunkTitle")}) Tj ET\n");
    streamBuf.write("0.4 0.4 0.4 rg\n");
    streamBuf.write(
        "BT /F2 9 Tf 40 540 Td (${sanitizePdfText("Generated on: $nowStr  |  Page ${p + 1} of $numPages")}) Tj ET\n");

    List<String> headers = ['Pump Details'];
    for (var d in chunkDates) {
      headers.add(DateFormat('MM/dd (E)').format(d));
    }
    headers.add('Total');

    int numCols = headers.length;
    double startX = 40.0;
    double tableWidth = 762.0;

    double col0Width = 142.0;
    double otherColWidth =
        (numCols > 1) ? (tableWidth - col0Width) / (numCols - 1) : tableWidth;

    double getColX(int c) {
      if (c == 0) return startX;
      return startX + col0Width + ((c - 1) * otherColWidth);
    }

    // Header 1 Background
    streamBuf.write("0.90 0.95 0.95 rg 40 508 762 20 re f\n");
    streamBuf.write("0.70 0.80 0.80 RG 0.8 w 40 508 762 20 re S\n");

    streamBuf.write("0.1 0.1 0.1 rg\n");
    for (int c = 0; c < numCols; c++) {
      double cx = getColX(c) + 4;
      String hText = headers[c];
      streamBuf
          .write("BT /F1 8 Tf $cx 514 Td (${sanitizePdfText(hText)}) Tj ET\n");
    }

    // Subheader 2 Background
    streamBuf.write("0.94 0.97 0.97 rg 40 492 762 16 re f\n");
    streamBuf.write("0.75 0.82 0.82 RG 0.5 w 40 492 762 16 re S\n");

    streamBuf.write("0.25 0.35 0.35 rg\n");
    for (int c = 0; c < numCols; c++) {
      double cx = getColX(c) + 4;
      String subText = (c == 0) ? "Pump" : "Run / On / Off";
      streamBuf
          .write("BT /F1 6.5 Tf $cx 497 Td (${sanitizePdfText(subText)}) Tj ET\n");
    }

    double currentY = 492.0;

    for (int r = 0; r < chunkRows.length; r++) {
      final row = chunkRows[r];
      String cat = row.channelCategory?.toString() ?? '';
      String name = row.channelName?.toString() ?? '';

      List<String> cell0Lines = [
        if (cat.isNotEmpty) cat,
        if (name.isNotEmpty) name,
      ];
      if (cell0Lines.isEmpty) cell0Lines = ['Pump'];

      List<List<String>> rowCellLines = [cell0Lines];

      for (int d = 0; d < chunkDates.length; d++) {
        String dKey = DateFormat('yyyy-MM-dd').format(chunkDates[d]);
        var dayData = row.dayEntries[dKey];
        int sec = dayData?.durationSeconds ?? 0;
        int onSec = dayData?.powerOnSeconds ?? 0;
        int offSec = dayData?.powerOffSeconds ?? 0;
        bool hasAct = sec > 0 || onSec > 0 || offSec > 0;
        bool hasRun = dayData != null && dayData.hasRun;

        List<String> dLines;
        if (hasAct || hasRun) {
          dLines = [
            sec > 0 ? "${formatHMS(sec)} /" : "00:00:00 /",
            onSec > 0 ? "${formatHMS(onSec)} /" : "00:00:00 /",
            offSec > 0 ? formatHMS(offSec) : "00:00:00",
          ];
        } else {
          dLines = ['- /', '- /', '-'];
        }
        rowCellLines.add(dLines);
      }

      int totSec = row.totalDurationSeconds ?? 0;
      int totOnSec = row.totalPowerOnSeconds ?? 0;
      int totOffSec = row.totalPowerOffSeconds ?? 0;

      List<String> totLines = [
        totSec > 0 ? "${formatDur(totSec)} /" : "- /",
        totOnSec > 0 ? "${formatDur(totOnSec)} /" : "- /",
        totOffSec > 0 ? formatDur(totOffSec) : "-",
      ];
      rowCellLines.add(totLines);

      double rowHeight = 32.0;
      double drawTop = currentY - rowHeight;

      if (r % 2 == 1) {
        streamBuf.write(
            "0.97 0.98 0.98 rg $startX $drawTop $tableWidth $rowHeight re f\n");
      }
      streamBuf.write(
          "0.88 0.90 0.90 RG 0.5 w $startX $drawTop $tableWidth $rowHeight re S\n");

      for (int c = 0; c < numCols; c++) {
        double cx = getColX(c) + 4;
        List<String> lines = rowCellLines[c];
        if (c == 0) {
          streamBuf.write("0.15 0.20 0.25 rg\n");
          for (int lIdx = 0; lIdx < lines.length && lIdx < 2; lIdx++) {
            double lineY = currentY - 12 - (lIdx * 10.0);
            String font = (lIdx == 1) ? "/F1" : "/F2";
            streamBuf.write(
                "BT $font 7.5 Tf $cx $lineY Td (${sanitizePdfText(lines[lIdx])}) Tj ET\n");
          }
        } else {
          for (int lIdx = 0; lIdx < lines.length && lIdx < 3; lIdx++) {
            double lineY = currentY - 10 - (lIdx * 8.5);
            if (lines[lIdx].startsWith("-")) {
              streamBuf.write("0.6 0.65 0.7 rg\n");
            } else {
              streamBuf.write("0.1 0.1 0.1 rg\n");
            }
            String font = (c == numCols - 1) ? "/F1" : "/F2";
            streamBuf.write(
                "BT $font 6.8 Tf $cx $lineY Td (${sanitizePdfText(lines[lIdx])}) Tj ET\n");
          }
        }
      }

      currentY -= rowHeight;
    }

    // BOTTOM TOTAL SUMMARY ROW
    if (rowPageIdx == totalRowPages) {
      List<List<String>> footerCellLines = [
        ['Total']
      ];

      for (int d = 0; d < chunkDates.length; d++) {
        String dKey = DateFormat('yyyy-MM-dd').format(chunkDates[d]);
        int dayRun = dailyRunTotals[dKey] ?? 0;
        int dayOn = dailyPowerOnTotals[dKey] ?? 0;
        int dayOff = dailyPowerOffTotals[dKey] ?? 0;
        bool hasAct = dayRun > 0 || dayOn > 0 || dayOff > 0;

        List<String> dLines = [
          dayRun > 0 ? "${formatDur(dayRun)} /" : (hasAct ? "0h 0m /" : "- /"),
          dayOn > 0 ? "${formatDur(dayOn)} /" : (hasAct ? "0h 0m /" : "- /"),
          dayOff > 0 ? formatDur(dayOff) : (hasAct ? "0h 0m" : "-"),
        ];
        footerCellLines.add(dLines);
      }

      bool hasGAct = grandTotalRunSeconds > 0 ||
          grandTotalPowerOnSeconds > 0 ||
          grandTotalPowerOffSeconds > 0;
      List<String> gLines = [
        grandTotalRunSeconds > 0
            ? "${formatDur(grandTotalRunSeconds)} /"
            : (hasGAct ? "0h 0m /" : "- /"),
        grandTotalPowerOnSeconds > 0
            ? "${formatDur(grandTotalPowerOnSeconds)} /"
            : (hasGAct ? "0h 0m /" : "- /"),
        grandTotalPowerOffSeconds > 0
            ? formatDur(grandTotalPowerOffSeconds)
            : (hasGAct ? "0h 0m" : "-"),
      ];
      footerCellLines.add(gLines);

      double footerHeight = 34.0;
      double drawTop = currentY - footerHeight;

      streamBuf.write(
          "0.86 0.98 0.90 rg $startX $drawTop $tableWidth $footerHeight re f\n");
      streamBuf.write(
          "0.70 0.88 0.78 RG 0.8 w $startX $drawTop $tableWidth $footerHeight re S\n");

      for (int c = 0; c < numCols; c++) {
        double cx = getColX(c) + 4;
        List<String> lines = footerCellLines[c];
        if (c == 0) {
          streamBuf.write("0.0 0.35 0.15 rg\n");
          double lineY = currentY - 19;
          streamBuf.write(
              "BT /F1 8.5 Tf $cx $lineY Td (${sanitizePdfText(lines[0])}) Tj ET\n");
        } else {
          for (int lIdx = 0; lIdx < lines.length && lIdx < 3; lIdx++) {
            double lineY = currentY - 10 - (lIdx * 8.5);
            if (lines[lIdx].startsWith("-")) {
              streamBuf.write("0.6 0.65 0.7 rg\n");
            } else {
              streamBuf.write("0.1 0.1 0.1 rg\n");
            }
            streamBuf.write(
                "BT /F1 6.8 Tf $cx $lineY Td (${sanitizePdfText(lines[lIdx])}) Tj ET\n");
          }
        }
      }

      currentY -= footerHeight;
    }

    final bytes = utf8.encode(streamBuf.toString());
    startObj(contentObjId);
    writeString("<< /Length ${bytes.length} >>\nstream\n");
    pdfBytes.addAll(bytes);
    writeString("\nendstream\nendobj\n");
  }

  int xrefOffset = pdfBytes.length;
  writeString("xref\n0 ${offsets.length}\n0000000000 65535 f \n");
  for (int i = 1; i < offsets.length; i++) {
    String offStr = offsets[i].toString().padLeft(10, '0');
    writeString("$offStr 00000 n \n");
  }

  writeString(
      "trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n");

  return Uint8List.fromList(pdfBytes);
}
