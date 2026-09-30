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

  // 1. PDF Header
  writeString("%PDF-1.4\n%\xFF\xFF\xFF\xFF\n");

  int totalRecords = records.length;
  int recordsPerPage = 25;
  int numPages =
      (totalRecords == 0) ? 1 : (totalRecords / recordsPerPage).ceil();

  // Standard Objects:
  // Obj 1: Catalog
  // Obj 2: Pages
  // Obj 3: Font Bold (Helvetica-Bold)
  // Obj 4: Font Regular (Helvetica)
  // Obj 5: Font Mono (Courier)
  // Page objects: 6 + i*2
  // Content objects: 6 + i*2 + 1

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
  writeString(
      "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n");

  startObj(5);
  writeString("<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>\nendobj\n");

  String sanitizePdfText(String txt) {
    return txt
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  // Generate Pages
  for (int p = 0; p < numPages; p++) {
    int pageObjId = 6 + p * 2;
    int contentObjId = 6 + p * 2 + 1;

    // Page Obj
    startObj(pageObjId);
    writeString(
        "<< /Type /Page /Parent 2 0 R /MediaBox [ 0 0 842 595 ] /Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R >> >> /Contents $contentObjId 0 R >>\nendobj\n");

    // Stream Content
    StringBuffer streamBuf = StringBuffer();

    // Document Title
    streamBuf.write("0.12 0.23 0.37 rg\n");
    streamBuf.write(
        "BT /F1 15 Tf 40 555 Td (${sanitizePdfText("ZONE LOG REPORT - $fileName")}) Tj ET\n");
    streamBuf.write("0.4 0.4 0.4 rg\n");
    streamBuf.write(
        "BT /F2 9 Tf 40 538 Td (${sanitizePdfText("Generated on: $nowStr")}) Tj ET\n");

    // Table Header Background
    streamBuf.write("0.90 0.93 0.96 rg 40 508 762 22 re f\n");
    streamBuf.write("0.75 0.80 0.85 RG 0.8 w 40 508 762 22 re S\n");

    // Table Headers
    final headers = [
      {'title': 'Date', 'x': 45, 'max': 12},
      {'title': 'Program Name', 'x': 115, 'max': 14},
      {'title': 'Sequence Name', 'x': 200, 'max': 14},
      {'title': 'HeadUnit', 'x': 285, 'max': 10},
      {'title': 'Pump', 'x': 345, 'max': 8},
      {'title': 'Start', 'x': 395, 'max': 10},
      {'title': 'End', 'x': 455, 'max': 10},
      {'title': 'Duration', 'x': 515, 'max': 10},
      {'title': 'Start Reason', 'x': 575, 'max': 16},
      {'title': 'End Reason', 'x': 685, 'max': 18},
    ];

    streamBuf.write("0.1 0.1 0.1 rg\n");
    for (var h in headers) {
      String titleTxt = sanitizePdfText(h['title'] as String);
      int xPos = h['x'] as int;
      streamBuf.write("BT /F1 9 Tf $xPos 515 Td ($titleTxt) Tj ET\n");
    }

    // Rows
    int startIdx = p * recordsPerPage;
    int endIdx = (startIdx + recordsPerPage < totalRecords)
        ? startIdx + recordsPerPage
        : totalRecords;

    double currentY = 488;
    for (int r = startIdx; r < endIdx; r++) {
      var rec = records[r];
      bool isEven = (r % 2 == 0);
      if (isEven) {
        streamBuf.write("0.97 0.98 0.99 rg 40 ${currentY - 4} 762 17 re f\n");
      }
      streamBuf
          .write("0.88 0.90 0.92 RG 0.5 w 40 ${currentY - 4} 762 17 re S\n");

      streamBuf.write("0.15 0.15 0.15 rg\n");

      List<String> rowValues = [
        rec.dateStr,
        rec.programTitle,
        rec.sequenceTitle,
        rec.headUnit,
        rec.pump,
        rec.startTime,
        rec.endTime,
        rec.duration,
        rec.startReason,
        rec.endReason,
      ];

      for (int c = 0; c < headers.length; c++) {
        int xPos = headers[c]['x'] as int;
        int maxL = headers[c]['max'] as int;
        String val = rowValues[c];
        if (val.length > maxL) {
          val = "${val.substring(0, maxL - 1)}..";
        }
        String safeVal = sanitizePdfText(val);
        streamBuf.write("BT /F2 8 Tf $xPos $currentY Td ($safeVal) Tj ET\n");
      }

      currentY -= 17;
    }

    // Footer
    streamBuf.write("0.5 0.5 0.5 rg\n");
    streamBuf.write(
        "BT /F2 8 Tf 40 20 Td (${sanitizePdfText("Page ${p + 1} of $numPages")}) Tj ET\n");
    // streamBuf.write("BT /F2 8 Tf 680 20 Td (${sanitizePdfText("Drip Irrigation System")}) Tj ET\n");

    List<int> streamBytes = utf8.encode(streamBuf.toString());

    startObj(contentObjId);
    writeString("<< /Length ${streamBytes.length} >>\nstream\n");
    pdfBytes.addAll(streamBytes);
    writeString("\nendstream\nendobj\n");
  }

  // Cross-reference table (xref)
  int xrefOffset = pdfBytes.length;
  int totalObjects = 6 + numPages * 2;

  writeString("xref\n0 $totalObjects\n0000000000 65535 f \n");
  for (int i = 1; i < totalObjects; i++) {
    int off = offsets[i];
    String offStr = off.toString().padLeft(10, '0');
    writeString("$offStr 00000 n \n");
  }

  // Trailer
  writeString(
      "trailer\n<< /Size $totalObjects /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n");

  return Uint8List.fromList(pdfBytes);
}
