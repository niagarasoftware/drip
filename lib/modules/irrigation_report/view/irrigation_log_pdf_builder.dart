import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'reason_lookup.dart';

class _PdfColumnGroup {
  final String columnKey;
  final String dataKey;
  final String Function(String label)? labelBuilder;
  final String Function(String label, dynamic value)? cellTransform;

  _PdfColumnGroup(this.columnKey, this.dataKey, {this.labelBuilder, this.cellTransform});
}

// ---- Layout helpers (compact layout) ----
const double _fsBody = 6.5;
const double _tableW = 762.0;
const double _firstColW = 58.0;
const int _maxDataColsPerPage = 14;
const double _summaryBandH = 24.0;
// Table-la kaatta vendaam nu nenaikkura general columns (summary mattum varum)
const _hiddenColumns = {'Status'};

double _otherColW(int numCols) =>
    numCols <= 1 ? _tableW : (_tableW - _firstColW) / (numCols - 1);
double _colW(int c, int numCols) => c == 0 ? _firstColW : _otherColW(numCols);
double _colX(int c, int numCols) =>
    c == 0 ? 40.0 : 40.0 + _firstColW + (c - 1) * _otherColW(numCols);
int _maxChars(int c, int numCols, double fs) =>
    ((_colW(c, numCols) - 6) / (fs * 0.52)).floor().clamp(6, 40);

const _reasonCodeColumns = {
  'Start Stop Reason',
  'Pause Resume Reason',
  'Actual Start Reason',
  'Actual Stop Reason'
};
const _statusColumns = {'Status'};

String _pdfCellTransform(String label, dynamic value) {
  if (value == null || value == '' || value == 'null') return '-';
  if (_reasonCodeColumns.contains(label)) {
    return programStartStopReason(code: value);
  }
  if (_statusColumns.contains(label)) {
    final statusMap = getStatus(value);
    return statusMap['status']?.toString() ?? '$value';
  }
  return '$value';
}

List<_PdfColumnGroup> _buildPdfColumnGroups() {
  return [
    _PdfColumnGroup('generalColumn', 'generalColumnData', cellTransform: _pdfCellTransform),
    _PdfColumnGroup('waterColumn', 'waterColumnData', labelBuilder: (l) => 'Water $l'),
    _PdfColumnGroup('centralFilterColumn', 'centralFilterColumnData', labelBuilder: (l) => 'Central Filter $l'),
    _PdfColumnGroup('localFilterColumn', 'localFilterColumnData', labelBuilder: (l) => 'Local Filter $l'),
    _PdfColumnGroup('filterColumn', 'filterColumnData'),
    _PdfColumnGroup('prePostColumn', 'prePostColumnData'),
    _PdfColumnGroup('centralEcPhColumn', 'centralEcPhColumnData'),
    for (var ch = 1; ch <= 8; ch++)
      _PdfColumnGroup(
        'centralChannel${ch}Column',
        'centralChannel${ch}ColumnData',
        labelBuilder: (l) => 'Central CH$ch - $l',
      ),
    _PdfColumnGroup('localEcPhColumn', 'localEcPhColumnData'),
    for (var ch = 1; ch <= 8; ch++)
      _PdfColumnGroup(
        'localChannel${ch}Column',
        'localChannel${ch}ColumnData',
        labelBuilder: (l) => 'Local CH$ch - $l',
      ),
  ];
}

bool _groupHasData(Map<String, dynamic> data, _PdfColumnGroup group) {
  final labels = data[group.columnKey];
  final columnData = data[group.dataKey];
  return labels != null &&
      labels is List &&
      labels.isNotEmpty &&
      columnData != null &&
      columnData is List &&
      columnData.isNotEmpty;
}

List<String> wrapTextLines(String text, int maxCharsPerLine, {int maxLines = 3}) {
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

int? _parseSeconds(String val) {
  final clean = val.trim();
  if (clean.isEmpty || clean == '-') return null;

  final colonParts = clean.split(':');
  if (colonParts.length == 3) {
    final h = int.tryParse(colonParts[0]);
    final m = int.tryParse(colonParts[1]);
    final s = int.tryParse(colonParts[2]);
    if (h != null && m != null && s != null) {
      return h * 3600 + m * 60 + s;
    }
  } else if (colonParts.length == 2) {
    final h = int.tryParse(colonParts[0]);
    final m = int.tryParse(colonParts[1]);
    if (h != null && m != null) {
      return h * 3600 + m * 60;
    }
  }

  final hMatch = RegExp(r'(\d+)\s*h', caseSensitive: false).firstMatch(clean);
  final mMatch = RegExp(r'(\d+)\s*m', caseSensitive: false).firstMatch(clean);
  final sMatch = RegExp(r'(\d+)\s*s', caseSensitive: false).firstMatch(clean);

  if (hMatch != null || mMatch != null || sMatch != null) {
    int total = 0;
    if (hMatch != null) total += (int.tryParse(hMatch.group(1)!) ?? 0) * 3600;
    if (mMatch != null) total += (int.tryParse(mMatch.group(1)!) ?? 0) * 60;
    if (sMatch != null) total += (int.tryParse(sMatch.group(1)!) ?? 0);
    return total;
  }

  return null;
}

double? _parseQuantity(String val) {
  final clean = val.trim();
  if (clean.isEmpty || clean == '-') return null;

  final numMatch = RegExp(r'([\d\.]+)\s*(L|litres|liter|liters)?', caseSensitive: false).firstMatch(clean);
  if (numMatch != null) {
    return double.tryParse(numMatch.group(1)!);
  }
  return null;
}

String _formatDurationTotal(int totalSecs) {
  if (totalSecs <= 0) return "0h 0m";
  int h = totalSecs ~/ 3600;
  int m = (totalSecs % 3600) ~/ 60;
  int s = totalSecs % 60;
  if (s > 0) return "${h}h ${m}m ${s}s";
  return "${h}h ${m}m";
}

String _computeColumnSummary(List<List<String>> rows, int c) {
  if (rows.isEmpty) return '-';
  if (c == 0) return 'Total (${rows.length})';

  int totalSecs = 0;
  bool hasSecs = false;
  double totalQty = 0.0;
  bool hasQty = false;
  bool hasLitresUnit = false;

  for (final r in rows) {
    if (c >= r.length) continue;
    final cell = r[c].trim();
    if (cell.isEmpty || cell == '-') continue;

    if (cell.contains('/')) {
      final parts = cell.split('/');
      final secs = _parseSeconds(parts[0]);
      if (secs != null) {
        totalSecs += secs;
        hasSecs = true;
      }
      final qty = _parseQuantity(parts[1]);
      if (qty != null) {
        totalQty += qty;
        hasQty = true;
        if (parts[1].toUpperCase().contains('L')) hasLitresUnit = true;
      }
    } else {
      final secs = _parseSeconds(cell);
      if (secs != null) {
        totalSecs += secs;
        hasSecs = true;
      } else {
        final qty = _parseQuantity(cell);
        if (qty != null) {
          totalQty += qty;
          hasQty = true;
          if (cell.toUpperCase().contains('L')) hasLitresUnit = true;
        }
      }
    }
  }

  if (hasSecs && hasQty) {
    String qtyStr = totalQty == totalQty.roundToDouble() ? '${totalQty.toInt()}' : totalQty.toStringAsFixed(1);
    String unit = hasLitresUnit ? ' L' : '';
    return '${_formatDurationTotal(totalSecs)} / $qtyStr$unit';
  } else if (hasSecs) {
    return _formatDurationTotal(totalSecs);
  } else if (hasQty) {
    String qtyStr = totalQty == totalQty.roundToDouble() ? '${totalQty.toInt()}' : totalQty.toStringAsFixed(1);
    String unit = hasLitresUnit ? ' L' : '';
    return '$qtyStr$unit';
  }

  return '-';
}

Uint8List generateIrrigationLogPdfBytes(dynamic dataInput, String fileName, {String? reportSheet}) {
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

  // Orey oru report mattum: reportSheet kudutha adhu, illana first sheet
  if (sheets.length > 1) {
    final keepKey = (reportSheet != null && sheets.containsKey(reportSheet)) ? reportSheet : sheets.keys.first;
    final keepData = sheets[keepKey]!;
    sheets.clear();
    sheets[keepKey] = keepData;
  }

  // 1. PDF Header
  writeString("%PDF-1.4\n%\xFF\xFF\xFF\xFF\n");

  List<Map<String, dynamic>> allPages = [];

  sheets.forEach((sheetName, sheetData) {
    String fixedColName = sheetData['fixedColumn']?.toString() ?? 'Date';
    List fixedCols = sheetData['fixedColumnData'] as List? ?? [];

    final groups = _buildPdfColumnGroups();
    final activeGroups = groups.where((g) => _groupHasData(sheetData, g)).toList();

    List<String> headers = [fixedColName];
    Map<_PdfColumnGroup, int> columnCounts = {};
    final List<int> groupSizes = [];

    for (var group in activeGroups) {
      final labels = sheetData[group.columnKey] as List;
      columnCounts[group] = labels.length;
      groupSizes.add(labels.length);
      for (var j = 0; j < labels.length; j++) {
        final label = '${labels[j]}';
        headers.add(group.labelBuilder != null ? group.labelBuilder!(label) : label);
      }
    }

    if (activeGroups.isEmpty && sheetData.containsKey('generalColumn') && sheetData.containsKey('generalColumnData')) {
      final labels = sheetData['generalColumn'] as List? ?? [];
      final genGroup = _PdfColumnGroup('generalColumn', 'generalColumnData', cellTransform: _pdfCellTransform);
      activeGroups.add(genGroup);
      columnCounts[genGroup] = labels.length;
      groupSizes.add(labels.length);
      for (var label in labels) {
        headers.add('$label');
      }
    }

    List<List<String>> rows = [];
    for (int r = 0; r < fixedCols.length; r++) {
      List<String> row = ['${fixedCols[r] ?? '-'}'];
      for (var group in activeGroups) {
        final labels = sheetData[group.columnKey] as List? ?? [];
        final groupData = sheetData[group.dataKey] as List? ?? [];
        final expectedCount = columnCounts[group] ?? labels.length;

        List rowValues = (r < groupData.length && groupData[r] is List) ? groupData[r] as List : [];
        for (int j = 0; j < expectedCount; j++) {
          final raw = j < rowValues.length ? rowValues[j] : null;
          if (raw == null || raw == '' || raw == 'null') {
            row.add('-');
          } else if (group.cellTransform != null) {
            final label = j < labels.length ? '${labels[j]}' : '';
            row.add(group.cellTransform!(label, raw));
          } else {
            row.add('$raw');
          }
        }
      }
      rows.add(row);
    }

    if (rows.isEmpty) {
      rows.add(List.filled(headers.isNotEmpty ? headers.length : 1, '-'));
    }

    // Status summary (first page-ku mattum) + status column table-la irundhu remove
    final Map<String, int> statusCounts = {};
    if (activeGroups.isNotEmpty &&
        activeGroups.first.columnKey == 'generalColumn' &&
        groupSizes.isNotEmpty) {
      final int genSize = groupSizes[0];
      final List<int> hideIdx = [];
      for (int i = 1; i <= genSize && i < headers.length; i++) {
        if (_hiddenColumns.contains(headers[i])) hideIdx.add(i);
      }
      for (final i in hideIdx) {
        if (headers[i] != 'Status') continue;
        for (final r in rows) {
          if (i >= r.length) continue;
          final v = r[i].trim();
          if (v.isEmpty || v == '-') continue;
          statusCounts[v] = (statusCounts[v] ?? 0) + 1;
        }
      }
      for (final i in hideIdx.reversed) {
        headers.removeAt(i);
        for (final r in rows) {
          if (i < r.length) r.removeAt(i);
        }
        groupSizes[0]--;
      }
    }

    // Group-aware column packing
    final List<List<int>> chunks = [];
    List<int> cur = [];
    int colPtr = 1;
    for (final size in groupSizes) {
      final idxs = List.generate(size, (i) => colPtr + i);
      colPtr += size;
      // group poga edam illana next page-ku
      if (cur.isNotEmpty && cur.length + size > _maxDataColsPerPage) {
        chunks.add(cur);
        cur = [];
      }
      for (final i in idxs) {
        if (cur.length >= _maxDataColsPerPage) {
          chunks.add(cur);
          cur = [];
        }
        cur.add(i);
      }
    }
    if (cur.isNotEmpty) chunks.add(cur);
    if (chunks.isEmpty) chunks.add([]);
    final int colChunks = chunks.length;

    for (int cc = 0; cc < colChunks; cc++) {
      final List<int> chunkColIndices = [0, ...chunks[cc]];
      final List<String> chunkHeaders = chunkColIndices.map((i) => headers[i]).toList();
      final int chunkNumCols = chunkColIndices.length;

      List<String> chunkSummaryRow = [
        for (final i in chunkColIndices) _computeColumnSummary(rows, i)
      ];

      List<List<List<String>>> chunkPageRows = [];
      List<List<String>> currentPage = [];
      double pageAvailableY = 425.0; // summary row-ku space vittu
      // First page-la status summary band-ku space kammi
      double firstPageAvailableY =
      (cc == 0 && statusCounts.isNotEmpty) ? pageAvailableY - _summaryBandH : pageAvailableY;
      double currentY = firstPageAvailableY;

      for (int r = 0; r < rows.length; r++) {
        List<String> fullRow = rows[r];
        List<String> chunkRow = [];
        int maxLinesInRow = 1;

        for (int i = 0; i < chunkNumCols; i++) {
          int idx = chunkColIndices[i];
          String val = idx < fullRow.length ? fullRow[idx] : '-';
          chunkRow.add(val);
          final lines = wrapTextLines(val, _maxChars(i, chunkNumCols, _fsBody));
          if (lines.length > maxLinesInRow) maxLinesInRow = lines.length;
        }

        double rowHeight = 4.0 + (maxLinesInRow * 7.5);

        if (currentPage.isNotEmpty && (currentY - rowHeight < 0)) {
          chunkPageRows.add(currentPage);
          currentPage = [];
          currentY = pageAvailableY;
        }
        currentPage.add(chunkRow);
        currentY -= rowHeight;
      }
      if (currentPage.isNotEmpty) chunkPageRows.add(currentPage);

      int totalSheetPages = chunkPageRows.length;
      for (int p = 0; p < totalSheetPages; p++) {
        allPages.add({
          'sheetName': sheetName,
          'headers': chunkHeaders,
          'rows': chunkPageRows[p],
          'summaryRow': chunkSummaryRow,
          'isLastPage': (p == totalSheetPages - 1),
          'pageIndex': p + 1,
          'totalPages': totalSheetPages,
          'colChunk': cc + 1,
          'statusSummary': (cc == 0 && p == 0 && statusCounts.isNotEmpty) ? statusCounts : null,
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
      'summaryRow': <String>[],
      'isLastPage': true,
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
    final List<String> summaryRow = pageData['summaryRow'] != null ? List<String>.from(pageData['summaryRow']) : [];
    final bool isLastPage = pageData['isLastPage'] ?? false;
    final int colChunk = pageData['colChunk'] ?? 1;
    final int totalColChunks = pageData['totalColChunks'] ?? 1;

    StringBuffer streamBuf = StringBuffer();

    // Title Header
    streamBuf.write("0.00 0.40 0.45 rg\n");
    String subtitle = totalColChunks > 1 ? " (Cols $colChunk/$totalColChunks)" : "";
    streamBuf.write("BT /F1 14 Tf 40 555 Td (${sanitizePdfText("$fileName$subtitle")}) Tj ET\n");
    streamBuf.write("0.4 0.4 0.4 rg\n");
    streamBuf.write("BT /F2 9 Tf 40 540 Td (${sanitizePdfText("Generated on: $nowStr  |  Page ${p + 1} of $numPages")}) Tj ET\n");

    int numCols = headers.isNotEmpty ? headers.length : 1;
    const double startX = 40.0;
    const double tableWidth = _tableW;

    // Header background (3 lines varaikkum)
    streamBuf.write("0.90 0.95 0.95 rg 40 500 762 28 re f\n");
    streamBuf.write("0.70 0.80 0.80 RG 0.8 w 40 500 762 28 re S\n");

    streamBuf.write("0.1 0.1 0.1 rg\n");
    for (int c = 0; c < numCols; c++) {
      double cx = _colX(c, numCols) + 3;
      final hLines = wrapTextLines(headers[c], _maxChars(c, numCols, _fsBody), maxLines: 3);
      for (int l = 0; l < hLines.length; l++) {
        double ly = 521.0 - (l * 7.5);
        streamBuf.write("BT /F1 $_fsBody Tf $cx $ly Td (${sanitizePdfText(hLines[l])}) Tj ET\n");
      }
    }

    double currentY = 498.0;

    // Status summary band (first page only)
    final Map<String, int>? statusSummary =
    pageData['statusSummary'] != null ? Map<String, int>.from(pageData['statusSummary']) : null;
    if (statusSummary != null && statusSummary.isNotEmpty) {
      final text = 'Status Summary:  ' + statusSummary.entries.map((e) => '${e.key}: ${e.value}').join('   |   ');
      streamBuf.write("0.85 0.92 0.94 rg $startX 474 $tableWidth 20 re f\n");
      streamBuf.write("0.60 0.75 0.80 RG 0.8 w $startX 474 $tableWidth 20 re S\n");
      streamBuf.write("0.00 0.25 0.35 rg\n");
      final sLine = wrapTextLines(text, 190, maxLines: 1).first;
      streamBuf.write("BT /F1 7.5 Tf ${startX + 4} 481 Td (${sanitizePdfText(sLine)}) Tj ET\n");
      currentY -= _summaryBandH;
    }

    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];
      int maxLinesInRow = 1;
      List<List<String>> cellLinesList = [];

      for (int c = 0; c < numCols; c++) {
        String valText = c < row.length ? row[c] : '-';
        final lines = wrapTextLines(valText, _maxChars(c, numCols, _fsBody));
        cellLinesList.add(lines);
        if (lines.length > maxLinesInRow) maxLinesInRow = lines.length;
      }

      double rowHeight = 4.0 + (maxLinesInRow * 7.5);
      double drawTopY = currentY - rowHeight;

      if (r % 2 == 1) {
        streamBuf.write("0.97 0.98 0.98 rg $startX $drawTopY $tableWidth $rowHeight re f\n");
      }
      streamBuf.write("0.88 0.90 0.90 RG 0.5 w $startX $drawTopY $tableWidth $rowHeight re S\n");

      streamBuf.write("0.2 0.2 0.2 rg\n");
      for (int c = 0; c < numCols; c++) {
        double cx = _colX(c, numCols) + 3;
        final lines = cellLinesList[c];
        for (int li = 0; li < lines.length; li++) {
          double lineY = currentY - 8.0 - (li * 7.5);
          streamBuf.write("BT /F2 $_fsBody Tf $cx $lineY Td (${sanitizePdfText(lines[li])}) Tj ET\n");
        }
      }
      currentY -= rowHeight;
    }

    // SUMMARY ROW
    if (isLastPage && summaryRow.isNotEmpty) {
      int maxSummaryLines = 1;
      List<List<String>> summaryCellLines = [];
      for (int c = 0; c < numCols; c++) {
        String sumText = c < summaryRow.length ? summaryRow[c] : '-';
        final lines = wrapTextLines(sumText, _maxChars(c, numCols, _fsBody), maxLines: 2);
        summaryCellLines.add(lines);
        if (lines.length > maxSummaryLines) maxSummaryLines = lines.length;
      }

      double footerHeight = 5.0 + (maxSummaryLines * 7.5);
      double drawTopY = currentY - footerHeight;

      streamBuf.write("0.85 0.92 0.94 rg $startX $drawTopY $tableWidth $footerHeight re f\n");
      streamBuf.write("0.60 0.75 0.80 RG 0.8 w $startX $drawTopY $tableWidth $footerHeight re S\n");

      streamBuf.write("0.00 0.25 0.35 rg\n");
      for (int c = 0; c < numCols; c++) {
        double cx = _colX(c, numCols) + 3;
        final lines = summaryCellLines[c];
        for (int li = 0; li < lines.length; li++) {
          double lineY = currentY - 8.0 - (li * 7.5);
          streamBuf.write("BT /F1 $_fsBody Tf $cx $lineY Td (${sanitizePdfText(lines[li])}) Tj ET\n");
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