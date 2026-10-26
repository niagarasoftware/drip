import 'dart:convert';
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
  Map<String, int>? dailyTotalQuantities,
  required int grandTotalSeconds,
  int grandTotalQuantity = 0,
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

  const int recordsPerPage = 18;
  const int datesPerPage = 6;

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

    List<String> headers = ['Program / Sequence'];
    for (var d in chunkDates) {
      headers.add(DateFormat('MM/dd (E)').format(d));
    }
    headers.add('Total');

    int numCols = headers.length;
    double startX = 40.0;
    double tableWidth = 762.0;

    double col0Width = 175.0;
    double otherColWidth = (numCols > 1) ? (tableWidth - col0Width) / (numCols - 1) : tableWidth;

    double getColX(int c) {
      if (c == 0) return startX;
      return startX + col0Width + ((c - 1) * otherColWidth);
    }

    // Header Background
    streamBuf.write("0.90 0.95 0.95 rg 40 508 762 20 re f\n");
    streamBuf.write("0.70 0.80 0.80 RG 0.8 w 40 508 762 20 re S\n");

    streamBuf.write("0.1 0.1 0.1 rg\n");
    for (int c = 0; c < numCols; c++) {
      double cx = getColX(c) + 4;
      String hText = headers[c];
      int maxChars = (c == 0) ? 22 : 14;
      List<String> hLines = _wrapTextLines(hText, maxChars, maxLines: 2);
      if (hLines.length == 1) {
        streamBuf.write("BT /F1 8 Tf $cx 514 Td (${sanitizePdfText(hLines[0])}) Tj ET\n");
      } else {
        streamBuf.write("BT /F1 7.5 Tf $cx 518 Td (${sanitizePdfText(hLines[0])}) Tj ET\n");
        streamBuf.write("BT /F1 7.5 Tf $cx 510 Td (${sanitizePdfText(hLines[1])}) Tj ET\n");
      }
    }

    double currentY = 488.0;

    for (int r = 0; r < chunkRows.length; r++) {
      final row = chunkRows[r];
      String name = (row.progName != null && row.progName.isNotEmpty && row.progName != row.seqName)
          ? "${row.progName} - ${row.seqName}"
          : "${row.seqName ?? '-'}";

      List<String> cell0Lines = _wrapTextLines(name, 22, maxLines: 2);

      List<List<String>> rowCellLines = [cell0Lines];
      int maxRowLines = cell0Lines.length;

      int rowTotalSec = 0;
      int rowTotalQty = 0;

      for (int d = 0; d < chunkDates.length; d++) {
        String dKey = DateFormat('yyyy-MM-dd').format(chunkDates[d]);
        var dayData = row.dayEntries[dKey];
        String cellVal = '- / -';
        if (dayData != null && dayData.hasRun) {
          int sec = (dayData.durationQtySeconds as int? ?? dayData.durationSeconds as int? ?? 0);
          int qtyVal = (dayData.quantityCompleted as int? ?? dayData.quantity?.toInt() ?? 0);
          String durStr = (dayData.durationQtyStr != null && dayData.durationQtyStr.toString().isNotEmpty)
              ? dayData.durationQtyStr.toString()
              : formatDurWithSecs(sec);
          String qtyStr = qtyVal > 0 ? "$qtyVal L" : '-';
          cellVal = "$durStr / $qtyStr";
          rowTotalSec += sec;
          rowTotalQty += qtyVal;
        }
        List<String> dLines = _wrapTextLines(cellVal, 14, maxLines: 2);
        rowCellLines.add(dLines);
        if (dLines.length > maxRowLines) maxRowLines = dLines.length;
      }

      String rDur = formatDurWithSecs(rowTotalSec);
      String rQty = rowTotalQty > 0 ? "$rowTotalQty L" : '-';
      String totalCellVal = "$rDur / $rQty";
      List<String> totLines = _wrapTextLines(totalCellVal, 14, maxLines: 2);
      rowCellLines.add(totLines);
      if (totLines.length > maxRowLines) maxRowLines = totLines.length;

      double rowHeight = 12.0 + (maxRowLines * 9.5);
      double drawTop = currentY - rowHeight + 14;

      if (r % 2 == 1) {
        streamBuf.write("0.97 0.98 0.98 rg $startX $drawTop $tableWidth $rowHeight re f\n");
      }
      streamBuf.write("0.88 0.90 0.90 RG 0.5 w $startX $drawTop $tableWidth $rowHeight re S\n");

      streamBuf.write("0.2 0.2 0.2 rg\n");
      for (int c = 0; c < numCols; c++) {
        double cx = getColX(c) + 4;
        List<String> lines = rowCellLines[c];
        String fontName = (c == numCols - 1) ? "/F1" : "/F2";
        for (int lIdx = 0; lIdx < lines.length; lIdx++) {
          double lineY = currentY + 5 - (lIdx * 9.5);
          streamBuf.write("BT $fontName 7.5 Tf $cx $lineY Td (${sanitizePdfText(lines[lIdx])}) Tj ET\n");
        }
      }

      currentY -= rowHeight;
    }

    // BOTTOM TOTAL SUMMARY ROW
    if (rowPageIdx == totalRowPages) {
      List<List<String>> footerCellLines = [_wrapTextLines('Total', 22, maxLines: 1)];
      int maxFooterLines = 1;

      for (int d = 0; d < chunkDates.length; d++) {
        String dKey = DateFormat('yyyy-MM-dd').format(chunkDates[d]);
        int daySec = dailyTotals[dKey] ?? 0;
        int dayQty = dailyTotalQuantities?[dKey] ?? 0;
        String dayDur = formatDurWithSecs(daySec);
        String dayQtyStr = dayQty > 0 ? "$dayQty L" : '-';
        String dayCellVal = "$dayDur / $dayQtyStr";
        List<String> dLines = _wrapTextLines(dayCellVal, 14, maxLines: 2);
        footerCellLines.add(dLines);
        if (dLines.length > maxFooterLines) maxFooterLines = dLines.length;
      }

      String gDur = formatDurWithSecs(grandTotalSeconds);
      String gQty = grandTotalQuantity > 0 ? "$grandTotalQuantity L" : '-';
      String gCellVal = "$gDur / $gQty";
      List<String> gLines = _wrapTextLines(gCellVal, 14, maxLines: 2);
      footerCellLines.add(gLines);
      if (gLines.length > maxFooterLines) maxFooterLines = gLines.length;

      double footerHeight = 14.0 + (maxFooterLines * 9.5);
      double drawTop = currentY - footerHeight + 14;

      streamBuf.write("0.85 0.92 0.94 rg $startX $drawTop $tableWidth $footerHeight re f\n");
      streamBuf.write("0.60 0.75 0.80 RG 0.8 w $startX $drawTop $tableWidth $footerHeight re S\n");

      streamBuf.write("0.0 0.25 0.35 rg\n");
      for (int c = 0; c < numCols; c++) {
        double cx = getColX(c) + 4;
        List<String> lines = footerCellLines[c];
        for (int lIdx = 0; lIdx < lines.length; lIdx++) {
          double lineY = currentY + 5 - (lIdx * 9.5);
          streamBuf.write("BT /F1 7.5 Tf $cx $lineY Td (${sanitizePdfText(lines[lIdx])}) Tj ET\n");
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

  writeString("trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n");

  return Uint8List.fromList(pdfBytes);
}
