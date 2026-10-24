import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

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
  int recordsPerPage = 25;
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
      {'title': 'Date', 'x': 45},
      {'title': 'Program Name', 'x': 115},
      {'title': 'Sequence Name', 'x': 200},
      {'title': 'HeadUnit', 'x': 285},
      {'title': 'Pump', 'x': 345},
      {'title': 'Start', 'x': 395},
      {'title': 'End', 'x': 455},
      {'title': 'Duration', 'x': 515},
      {'title': 'Start Reason', 'x': 575},
      {'title': 'End Reason', 'x': 685},
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
      if (r % 2 == 1) {
        streamBuf.write("0.96 0.97 0.98 rg 40 ${yPos - 2} 762 18 re f\n");
      }
      streamBuf.write("0.85 0.88 0.90 RG 0.4 w 40 ${yPos - 2} 762 18 re S\n");

      streamBuf.write("0.2 0.2 0.2 rg\n");
      streamBuf.write("BT /F2 8 Tf 45 $yPos Td (${sanitizePdfText(rec.dateStr ?? '-')}) Tj ET\n");
      streamBuf.write("BT /F2 8 Tf 115 $yPos Td (${sanitizePdfText(rec.programTitle ?? '-')}) Tj ET\n");
      streamBuf.write("BT /F2 8 Tf 200 $yPos Td (${sanitizePdfText(rec.sequenceTitle ?? '-')}) Tj ET\n");
      streamBuf.write("BT /F2 8 Tf 285 $yPos Td (${sanitizePdfText(rec.headUnit ?? '-')}) Tj ET\n");
      streamBuf.write("BT /F2 8 Tf 345 $yPos Td (${sanitizePdfText(rec.pump ?? '-')}) Tj ET\n");
      streamBuf.write("BT /F2 8 Tf 395 $yPos Td (${sanitizePdfText(rec.startTime ?? '-')}) Tj ET\n");
      streamBuf.write("BT /F2 8 Tf 455 $yPos Td (${sanitizePdfText(rec.endTime ?? '-')}) Tj ET\n");
      streamBuf.write("BT /F2 8 Tf 515 $yPos Td (${sanitizePdfText(rec.duration ?? '-')}) Tj ET\n");
      streamBuf.write("BT /F2 8 Tf 575 $yPos Td (${sanitizePdfText(rec.startReason ?? '-')}) Tj ET\n");
      streamBuf.write("BT /F2 8 Tf 685 $yPos Td (${sanitizePdfText(rec.endReason ?? '-')}) Tj ET\n");

      yPos -= 18;
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

  String formatDur(int totalSecs) {
    if (totalSecs <= 0) return "0h 0m";
    int h = totalSecs ~/ 3600;
    int m = (totalSecs % 3600) ~/ 60;
    return "${h}h ${m}m";
  }

  const int recordsPerPage = 22;
  const int datesPerPage = 6; // Max dates per horizontal page chunk

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

    StringBuffer streamBuf = StringBuffer();

    streamBuf.write("0.00 0.40 0.45 rg\n");
    String chunkTitle = totalDateChunks > 1 ? " (Dates Part $dateChunkIdx/$totalDateChunks)" : "";
    streamBuf.write("BT /F1 14 Tf 40 555 Td (${sanitizePdfText("$fileName$chunkTitle")}) Tj ET\n");
    streamBuf.write("0.4 0.4 0.4 rg\n");
    streamBuf.write("BT /F2 9 Tf 40 540 Td (${sanitizePdfText("Generated on: $nowStr  |  Page ${p + 1} of $numPages")}) Tj ET\n");

    List<String> headers = ['Program / Sequence'];
    for (var d in chunkDates) {
      headers.add(DateFormat('MM/dd').format(d));
    }
    headers.add('Total');

    int numCols = headers.length;
    double startX = 40.0;
    double tableWidth = 762.0;
    double colWidth = tableWidth / numCols;

    streamBuf.write("0.90 0.95 0.95 rg 40 508 762 20 re f\n");
    streamBuf.write("0.70 0.80 0.80 RG 0.8 w 40 508 762 20 re S\n");

    streamBuf.write("0.1 0.1 0.1 rg\n");
    for (int c = 0; c < numCols; c++) {
      double cx = startX + (c * colWidth) + 4;
      String hText = headers[c];
      if (hText.length > 14) hText = hText.substring(0, 12) + "..";
      streamBuf.write("BT /F1 8 Tf $cx 514 Td (${sanitizePdfText(hText)}) Tj ET\n");
    }

    double startY = 488.0;
    double rowHeight = 18.0;

    for (int r = 0; r < chunkRows.length; r++) {
      double currentY = startY - (r * rowHeight);

      if (r % 2 == 1) {
        streamBuf.write("0.97 0.98 0.98 rg $startX $currentY $tableWidth $rowHeight re f\n");
      }
      streamBuf.write("0.88 0.90 0.90 RG 0.5 w $startX $currentY $tableWidth $rowHeight re S\n");

      final row = chunkRows[r];
      String name = (row.progName != null && row.progName.isNotEmpty && row.progName != row.seqName)
          ? "${row.progName} - ${row.seqName}"
          : "${row.seqName ?? '-'}";

      streamBuf.write("0.2 0.2 0.2 rg\n");
      if (name.length > 18) name = name.substring(0, 16) + "..";
      streamBuf.write("BT /F2 8 Tf ${startX + 4} ${currentY + 5} Td (${sanitizePdfText(name)}) Tj ET\n");

      int rowChunkTotalSec = 0;
      for (int d = 0; d < chunkDates.length; d++) {
        String dKey = DateFormat('yyyy-MM-dd').format(chunkDates[d]);
        var dayData = row.dayEntries[dKey];
        String cellVal = '-';
        if (dayData != null && dayData.hasRun) {
          int sec = (dayData.durationQtySeconds as int? ?? dayData.durationSeconds as int? ?? 0);
          cellVal = formatDur(sec);
          rowChunkTotalSec += sec;
        }
        double cx = startX + ((d + 1) * colWidth) + 4;
        streamBuf.write("BT /F2 8 Tf $cx ${currentY + 5} Td (${sanitizePdfText(cellVal)}) Tj ET\n");
      }

      double totX = startX + ((numCols - 1) * colWidth) + 4;
      streamBuf.write("BT /F1 8 Tf $totX ${currentY + 5} Td (${sanitizePdfText(formatDur(rowChunkTotalSec))}) Tj ET\n");
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
