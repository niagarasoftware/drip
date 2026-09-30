import 'package:excel/excel.dart';
import 'reason_lookup.dart';

/// One row/column "group" in the export, e.g. General, Water, Filter, each
/// Central/Local channel, etc. Building the header AND the data rows from
/// this SAME list is what guarantees they can never drift out of sync
/// (that mismatch was the earlier bug where values showed under the wrong
/// headers).
class _ColumnGroup {
  final String columnKey; // e.g. 'generalColumn'
  final String dataKey; // e.g. 'generalColumnData'
  final String Function(String label)? labelBuilder; // optional prefix e.g. "Water X"
  final String Function(String label, dynamic value)? cellTransform; // optional per-cell value translation

  _ColumnGroup(this.columnKey, this.dataKey, {this.labelBuilder, this.cellTransform});
}

/// Columns whose raw value is a numeric code that needs translating to its
/// display string before being written to the sheet. Kept as a single
/// lookup so scrollingTable.dart (on-screen) and this file (export) can
/// never disagree about which columns need translating.
const _reasonCodeColumns = {'Start Stop Reason', 'Pause Resume Reason'};
const _successColumn = 'Status';

String _generalCellTransform(String label, dynamic value) {
  if (_reasonCodeColumns.contains(label)) {
    return programStartStopReason(code: value);
  }
  if (_successColumn == label) {
    return getStatus(value)['status'];
  }
  return '$value';
}

List<_ColumnGroup> _buildColumnGroups() {
  return [
    _ColumnGroup('generalColumn', 'generalColumnData',
        cellTransform: _generalCellTransform),
    _ColumnGroup('waterColumn', 'waterColumnData',
        labelBuilder: (l) => 'Water $l'),
    _ColumnGroup('filterColumn', 'filterColumnData'),
    _ColumnGroup('prePostColumn', 'prePostColumnData'),
    _ColumnGroup('centralEcPhColumn', 'centralEcPhColumnData'),
    for (var ch = 1; ch <= 8; ch++)
      _ColumnGroup(
        'centralChannel${ch}Column',
        'centralChannel${ch}ColumnData',
        labelBuilder: (l) => 'Central CH$ch - $l',
      ),
    _ColumnGroup('localEcPhColumn', 'localEcPhColumnData'),
    for (var ch = 1; ch <= 8; ch++)
      _ColumnGroup(
        'localChannel${ch}Column',
        'localChannel${ch}ColumnData',
        labelBuilder: (l) => 'Local CH$ch - $l',
      ),
  ];
}

/// True only when this group actually has at least one visible header label
/// AND at least one column of data.
///
/// Checking the labels here (not just the data) matters: some data-prep
/// paths (see getChannelData() in data_parsing_and_sorting_model.dart) can
/// emit placeholder values like ['-', '-', '-'] for a channel even when
/// none of that channel's columns are toggled "show". If we only looked at
/// the data list, a group like that would be treated as active with zero
/// header labels, and indexing labels[0] would throw a RangeError.
bool _groupHasData(Map<String, dynamic> data, _ColumnGroup group) {
  final labels = data[group.columnKey];
  final columnData = data[group.dataKey];
  return labels != null &&
      labels is List &&
      labels.isNotEmpty &&
      columnData != null &&
      columnData is List &&
      columnData.isNotEmpty &&
      columnData[0] != null &&
      (columnData[0] as List).isNotEmpty;
}

/// Builds the populated "Logs" sheet from [data].
/// Shared by both the mobile (dart:io) and web (dart:html) export paths so
/// they can never produce different output from one another.
///
/// Note: freeze panes are intentionally NOT implemented here. Every
/// maintained fork of `excel` that supports freeze panes (excel_community,
/// excel_plus) requires xml ^7.0.1, which conflicts with xml ^6.x required
/// by several other plugins already in this project (flutter_local_notifications,
/// upgrader, ...). The plain `excel` package (xml >=5.0.0 <7.0.0) has no
/// freeze-pane API. Header row and identifier column will still scroll
/// normally in any spreadsheet app - they just won't stay pinned in place.
Excel buildLogsExcel(Map<String, dynamic> data) {
  final excel = Excel.createExcel();
  final sheetObject = excel['Logs'];

  final groups = _buildColumnGroups();
  final activeGroups = groups.where((g) => _groupHasData(data, g)).toList();

  // The label list is the source of truth for how many columns a group has
  // - it reflects which of that group's parameters are actually toggled
  // "show". Data rows are forced to this same width below (padded with ''
  // if short, truncated if long) so header and data columns can never
  // drift apart, no matter what an upstream data-prep bug hands us.
  final columnCounts = {
    for (var group in activeGroups) group: (data[group.columnKey] as List).length,
  };

  // ---- Header row ----
  List<String> headerRow = ['${data['fixedColumn']}'];
  for (var group in activeGroups) {
    final labels = data[group.columnKey] as List;
    for (var j = 0; j < columnCounts[group]!; j++) {
      final label = '${labels[j]}';
      headerRow.add(group.labelBuilder != null ? group.labelBuilder!(label) : label);
    }
  }
  sheetObject.appendRow([for (var i in headerRow) TextCellValue(i)]);

  // ---- Data rows ----
  // Any value that is missing (row shorter than expected) or explicitly
  // null is rendered as '-' rather than an empty string or the literal
  // text "null". This is checked BEFORE cellTransform runs, since
  // _generalCellTransform's fallback branch does '$value' and would
  // otherwise print "null" as text (and reason/status lookups may not
  // null-check their input).
  final fixedColumnData = data['fixedColumnData'] as List;
  for (var i = 0; i < fixedColumnData.length; i++) {
    List<String> eachRow = ['${fixedColumnData[i] ?? '-'}'];
    for (var group in activeGroups) {
      final labels = data[group.columnKey] as List;
      final rowValues = data[group.dataKey][i] as List;
      final expectedCount = columnCounts[group]!;
      for (var j = 0; j < expectedCount; j++) {
        final raw = j < rowValues.length ? rowValues[j] : null;
        eachRow.add(raw == null
            ? '-'
            : (group.cellTransform != null
            ? group.cellTransform!('${labels[j]}', raw)
            : '$raw'));
      }
    }
    sheetObject.appendRow([for (var cell in eachRow) TextCellValue(cell)]);
  }

  return excel;
}