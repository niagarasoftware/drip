import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

Uint8List generateIrrigationLogPdfBytes(dynamic dataInput, String fileName) {
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
        .replaceAll('\n', ' ')
        .replaceAll('\r', '')
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  // Flatten sheets
  final Map<String, Map<String, dynamic>> sheets = {};
  if (dataInput is Map<String, Map<String, dynamic>>) {
    sheets.addAll(dataInput);
  } else if (dataInput is Map<String, dynamic>) {
    bool isMultiSheet = dataInput.isNotEmpty && dataInput.values.every((v) => v is Map);
    if (isMultiSheet) {
      dataInput.forEach((k, v) {
        sheets[k] = Map<String, dynamic>.from(v as Map);
      });
    } else {
      sheets['Report'] = dataInput;
    }
  }

  // 1. PDF Header
  writeString("%PDF-1.4\n%\xFF\xFF\xFF\xFF\n");

  List<Map<String, dynamic>> allPages = [];
  const int recordsPerPage = 22;
  const int dataColsPerPage = 7; // Max data columns per horizontal chunk

  sheets.forEach((sheetName, sheetData) {
    String fixedColName = sheetData['fixedColumn']?.toString() ?? 'Date';
    List fixedCols = sheetData['fixedColumnData'] as List? ?? [];

    List<String> headers = [fixedColName];
    List<List> colsDataSources = [];

    void addSection(String keyCol, String keyData) {
      List cols = sheetData[keyCol] as List? ?? [];
      List dataList = sheetData[keyData] as List? ?? [];
      for (int i = 0; i < cols.length; i++) {
        headers.add(cols[i].toString());
        if (i < dataList.length) {
          colsDataSources.add(dataList[i] as List? ?? []);
        } else {
          colsDataSources.add([]);
        }
      }
    }

    addSection('generalColumn', 'generalColumnData');
    addSection('waterColumn', 'waterColumnData');
    addSection('filterColumn', 'filterColumnData');
    addSection('prePostColumn', 'prePostColumnData');
    addSection('centralEcPhColumn', 'centralEcPhColumnData');
    addSection('localEcPhColumn', 'localEcPhColumnData');

    List<List<String>> rows = [];
    for (int r = 0; r < fixedCols.length; r++) {
      List<String> row = ['${fixedCols[r] ?? '-'}'];
      for (var colData in colsDataSources) {
        if (r < colData.length) {
          row.add('${colData[r] ?? '-'}');
        } else {
          row.add('-');
        }
      }
      rows.add(row);
    }

    if (rows.isEmpty) {
      rows.add(List.filled(headers.length, '-'));
    }

    // Number of data columns (excluding Fixed Col 0)
    int totalDataCols = headers.length - 1;
    if (totalDataCols < 1) totalDataCols = 1;

    int colChunks = (totalDataCols / dataColsPerPage).ceil();
    if (colChunks < 1) colChunks = 1;

    for (int cc = 0; cc < colChunks; cc++) {
      int colStart = 1 + (cc * dataColsPerPage);
      int colEnd = colStart + dataColsPerPage;
      if (colEnd > headers.length) colEnd = headers.length;

      // Extract chunk headers: Fixed Col 0 + data cols
      List<String> chunkHeaders = [headers[0]];
      List<int> chunkColIndices = [0];
      for (int c = colStart; c < colEnd; c++) {
        chunkHeaders.add(headers[c]);
        chunkColIndices.add(c);
      }

      int totalSheetPages = (rows.length / recordsPerPage).ceil();
      if (totalSheetPages == 0) totalSheetPages = 1;

      for (int p = 0; p < totalSheetPages; p++) {
        int startIdx = p * recordsPerPage;
        int endIdx = (startIdx + recordsPerPage < rows.length) ? startIdx + recordsPerPage : rows.length;

        List<List<String>> pageRows = [];
        for (int r = startIdx; r < endIdx; r++) {
          List<String> fullRow = rows[r];
          List<String> chunkRow = [];
          for (int idx in chunkColIndices) {
            chunkRow.add(idx < fullRow.length ? fullRow[idx] : '-');
          }
          pageRows.add(chunkRow);
        }

        allPages.add({
          'sheetName': sheetName,
          'headers': chunkHeaders,
          'rows': pageRows,
          'pageIndex': p + 1,
          'totalPages': totalSheetPages,
          'colChunk': cc + 1,
          'totalColChunks': colChunks,
        });
      }
    }
  });

  if (allPages.isEmpty) {
    allPages.add({
      'sheetName': 'Report',
      'headers': ['Log'],
      'rows': [
        ['No records available']
      ],
      'pageIndex': 1,
      'totalPages': 1,
      'colChunk': 1,
      'totalColChunks': 1,
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
    final String sheetName = pageData['sheetName'];
    final List<String> headers = List<String>.from(pageData['headers']);
    final List<List<String>> rows = List<List<String>>.from(pageData['rows']);
    final int colChunk = pageData['colChunk'] ?? 1;
    final int totalColChunks = pageData['totalColChunks'] ?? 1;

    StringBuffer streamBuf = StringBuffer();

    // Title Header
    streamBuf.write("0.00 0.40 0.45 rg\n");
    String subtitle = totalColChunks > 1 ? " (Cols $colChunk/$totalColChunks)" : "";
    streamBuf.write("BT /F1 14 Tf 40 555 Td (${sanitizePdfText("$fileName - $sheetName$subtitle")}) Tj ET\n");
    streamBuf.write("0.4 0.4 0.4 rg\n");
    streamBuf.write("BT /F2 9 Tf 40 540 Td (${sanitizePdfText("Generated on: $nowStr  |  Page ${p + 1} of $numPages")}) Tj ET\n");

    int numCols = headers.length > 0 ? headers.length : 1;

    double startX = 40.0;
    double tableWidth = 762.0;
    double colWidth = tableWidth / numCols;

    // Header Background
    streamBuf.write("0.90 0.95 0.95 rg 40 508 762 20 re f\n");
    streamBuf.write("0.70 0.80 0.80 RG 0.8 w 40 508 762 20 re S\n");

    // Header Labels
    streamBuf.write("0.1 0.1 0.1 rg\n");
    for (int c = 0; c < numCols; c++) {
      double cx = startX + (c * colWidth) + 4;
      String hText = headers[c];
      if (hText.length > 14) hText = hText.substring(0, 12) + "..";
      streamBuf.write("BT /F1 8 Tf $cx 514 Td (${sanitizePdfText(hText)}) Tj ET\n");
    }

    // Rows
    double startY = 488.0;
    double rowHeight = 18.0;

    for (int r = 0; r < rows.length; r++) {
      double currentY = startY - (r * rowHeight);

      if (r % 2 == 1) {
        streamBuf.write("0.97 0.98 0.98 rg $startX $currentY $tableWidth $rowHeight re f\n");
      }
      streamBuf.write("0.88 0.90 0.90 RG 0.5 w $startX $currentY $tableWidth $rowHeight re S\n");

      final row = rows[r];
      streamBuf.write("0.2 0.2 0.2 rg\n");
      for (int c = 0; c < numCols; c++) {
        double cx = startX + (c * colWidth) + 4;
        String valText = c < row.length ? row[c] : '-';
        if (valText.length > 16) valText = valText.substring(0, 14) + "..";
        streamBuf.write("BT /F2 8 Tf $cx ${currentY + 5} Td (${sanitizePdfText(valText)}) Tj ET\n");
      }
    }

    final bytes = utf8.encode(streamBuf.toString());
    startObj(contentObjId);
    writeString("<< /Length ${bytes.length} >>\nstream\n");
    pdfBytes.addAll(bytes);
    writeString("\nendstream\nendobj\n");
  }

  // Cross-reference table
  int xrefOffset = pdfBytes.length;
  writeString("xref\n0 ${offsets.length}\n0000000000 65535 f \n");
  for (int i = 1; i < offsets.length; i++) {
    String offStr = offsets[i].toString().padLeft(10, '0');
    writeString("$offStr 00000 n \n");
  }

  writeString("trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n");

  return Uint8List.fromList(pdfBytes);
}
