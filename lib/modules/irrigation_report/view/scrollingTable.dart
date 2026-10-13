import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:oro_drip_irrigation/modules/irrigation_report/view/widgets/pump_ct_card.dart';
import '../model/data_parsing_and_sorting_model.dart';
import 'reason_lookup.dart';

class ScrollingTable extends StatefulWidget {
  final String fixedColumn;
  final List<dynamic> fixedColumnData;
  final List<dynamic> generalColumn;
  final List<dynamic> generalColumnData;
  final List<dynamic> waterColumn;
  final List<dynamic> waterColumnData;
  final List<dynamic> filterColumn;
  final List<dynamic> filterColumnData;
  final List<dynamic> prePostColumn;
  final List<dynamic> prePostColumnData;
  final List<dynamic> centralEcPhColumn;
  final List<dynamic> centralEcPhColumnData;
  final List<dynamic> centralChannel1Column;
  final List<dynamic> centralChannel1ColumnData;
  final List<dynamic> centralChannel2Column;
  final List<dynamic> centralChannel2ColumnData;
  final List<dynamic> centralChannel3Column;
  final List<dynamic> centralChannel3ColumnData;
  final List<dynamic> centralChannel4Column;
  final List<dynamic> centralChannel4ColumnData;
  final List<dynamic> centralChannel5Column;
  final List<dynamic> centralChannel5ColumnData;
  final List<dynamic> centralChannel6Column;
  final List<dynamic> centralChannel6ColumnData;
  final List<dynamic> centralChannel7Column;
  final List<dynamic> centralChannel7ColumnData;
  final List<dynamic> centralChannel8Column;
  final List<dynamic> centralChannel8ColumnData;
  final List<dynamic> localEcPhColumn;
  final List<dynamic> localEcPhColumnData;
  final List<dynamic> localChannel1Column;
  final List<dynamic> localChannel1ColumnData;
  final List<dynamic> localChannel2Column;
  final List<dynamic> localChannel2ColumnData;
  final List<dynamic> localChannel3Column;
  final List<dynamic> localChannel3ColumnData;
  final List<dynamic> localChannel4Column;
  final List<dynamic> localChannel4ColumnData;
  final List<dynamic> localChannel5Column;
  final List<dynamic> localChannel5ColumnData;
  final List<dynamic> localChannel6Column;
  final List<dynamic> localChannel6ColumnData;
  final List<dynamic> localChannel7Column;
  final List<dynamic> localChannel7ColumnData;
  final List<dynamic> localChannel8Column;
  final List<dynamic> localChannel8ColumnData;
  final List<dynamic> graphData;
  final void Function(String sequenceName)? onSequenceClicked;

  /// Optional pill tabs shown above the table (Date / Program / Line / ...).
  /// The tab bar is only drawn when [onGroupChanged] is provided; the selected
  /// tab is the one that matches [fixedColumn].
  final List<String> groupOptions;
  final ValueChanged<String>? onGroupChanged;

  ScrollingTable({
    super.key,
    required this.fixedColumn,
    required this.fixedColumnData,
    required this.generalColumn,
    required this.generalColumnData,
    required this.waterColumn,
    required this.waterColumnData,
    required this.filterColumn,
    required this.filterColumnData,
    required this.prePostColumn,
    required this.prePostColumnData,
    required this.centralEcPhColumn,
    required this.centralEcPhColumnData,
    required this.centralChannel1Column,
    required this.centralChannel1ColumnData,
    required this.centralChannel2Column,
    required this.centralChannel2ColumnData,
    required this.centralChannel3Column,
    required this.centralChannel3ColumnData,
    required this.centralChannel4Column,
    required this.centralChannel4ColumnData,
    required this.centralChannel5Column,
    required this.centralChannel5ColumnData,
    required this.centralChannel6Column,
    required this.centralChannel6ColumnData,
    required this.centralChannel7Column,
    required this.centralChannel7ColumnData,
    required this.centralChannel8Column,
    required this.centralChannel8ColumnData,
    required this.localEcPhColumn,
    required this.localEcPhColumnData,
    required this.localChannel1Column,
    required this.localChannel1ColumnData,
    required this.localChannel2Column,
    required this.localChannel2ColumnData,
    required this.localChannel3Column,
    required this.localChannel3ColumnData,
    required this.localChannel4Column,
    required this.localChannel4ColumnData,
    required this.localChannel5Column,
    required this.localChannel5ColumnData,
    required this.localChannel6Column,
    required this.localChannel6ColumnData,
    required this.localChannel7Column,
    required this.localChannel7ColumnData,
    required this.localChannel8Column,
    required this.localChannel8ColumnData,
    required this.graphData,
    this.onSequenceClicked,
    this.groupOptions = const ['Date', 'Program', 'Line', 'Valve', 'Status'],
    this.onGroupChanged,
  });

  @override
  State<ScrollingTable> createState() => _ScrollingTableState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens (taken from the reference screenshot)
// ─────────────────────────────────────────────────────────────────────────────
const Color _kPageBg = Color(0xffEEF4F4);
const Color _kBannerBg = Color(0xffE2EFF0);
const Color _kGroupBg = Color(0xffD9ECEF);
const Color _kHeaderBg = Color(0xffF4F8F9);
const Color _kTeal = Color(0xff0B5D6B);
const Color _kHeaderText = Color(0xff5F6F76);
const Color _kBodyText = Color(0xff1F2D33);
const Color _kMutedText = Color(0xff9AA8AE);
const Color _kSectionLine = Color(0xffC5D8DC);
const Color _kLine = Color(0xffE6ECEE);

const double _kPinnedWidth = 170;
const double _kSensorWidth = 170;
const double _kBannerHeight = 40;
const double _kHeaderHeight = 48;
const double _kGroupHeight = 42;

const BoxDecoration _kRowDecoration = BoxDecoration(
  border: Border(bottom: BorderSide(color: _kLine)),
);

/// One horizontal block of columns (General, Water, Filter, ...).
class _Section {
  final String title;
  final List<dynamic> columns;
  final List<dynamic> data;
  final double colWidth;
  final double width; // contentWidth + divider
  final double left; // x position of the section inside the scroll content
  final bool divider; // thin line on the left edge (all but the first section)
  final bool isGeneral;

  const _Section({
    required this.title,
    required this.columns,
    required this.data,
    required this.colWidth,
    required this.width,
    required this.left,
    required this.divider,
    this.isGeneral = false,
  });
}

/// A date (or other group) block of consecutive rows.
class _GroupInfo {
  final String? key; // null = no grouping (plain rows)
  final int count;
  final dynamic totalTime;
  final int start;
  final int end;

  const _GroupInfo(
      {required this.key,
        required this.count,
        required this.totalTime,
        required this.start,
        required this.end});

  String get summary => totalTime == null ? '' : '$totalTime H:M:S total';
}

/// Pinned (sticky) group header – the sliver machinery makes the current
/// header stay on top and lets the next one push it out (and back).
class _GroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _GroupHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: height, child: child);

  @override
  bool shouldRebuild(covariant _GroupHeaderDelegate oldDelegate) => true;
}

class _StatusStyle {
  final Color bg;
  final Color fg;
  final Color dot;
  const _StatusStyle(this.bg, this.fg, this.dot);
}

class _ScrollingTableState extends State<ScrollingTable> {
  late LinkedScrollControllerGroup _scrollable1;
  late ScrollController _verticalScroll1;
  late ScrollController _verticalScroll2;
  late ScrollController _verticalScroll3;
  late LinkedScrollControllerGroup _scrollable2;
  late ScrollController _horizontalScroll1;
  late ScrollController _horizontalScroll2;
  bool _compact = false; // phone-sized screen

  static const List<String> _pumpCtColumns = [
    'Pump CT Average',
    'Pump CT Maximum',
    'Pump CT Minimum',
    'PumpCtAverage',
    'PumpCtMaximum',
    'PumpCtMinimum',
  ];
  static const List<String> _pressureColumns = [
    'Pressure Average',
    'Pressure Maximum',
    'Pressure Minimum',
    'PressureAverage',
    'PressureMaximum',
    'PressureMinimum',
  ];
  static const List<String> _timeColumns = [
    'Actual Start Time',
    'Actual End Time',
  ];
  static const List<String> _reasonColumns = [
    'Actual Start Reason',
    'Actual Stop Reason',
  ];

  /// Header labels shown in the screenshot.
  static const Map<String, String> _labels = {
    'Actual Start Time': 'Start time',
    'Actual End Time': 'End time',
    'Actual Start Reason': 'Start reason',
    'Actual Stop Reason': 'Stop reason',
  };

  @override
  void initState() {
    super.initState();
    _scrollable1 = LinkedScrollControllerGroup();
    _verticalScroll1 = _scrollable1.addAndGet();
    _verticalScroll2 = _scrollable1.addAndGet();
    _verticalScroll3 = _scrollable1.addAndGet();
    _scrollable2 = LinkedScrollControllerGroup();
    _horizontalScroll1 = _scrollable2.addAndGet();
    _horizontalScroll2 = _scrollable2.addAndGet();
  }

  @override
  void dispose() {
    _verticalScroll1.dispose();
    _verticalScroll2.dispose();
    _verticalScroll3.dispose();
    _horizontalScroll1.dispose();
    _horizontalScroll2.dispose();
    super.dispose();
  }

  // ───────────────────────────── build ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    _compact = MediaQuery.of(context).size.width < 600;
    final groups = _buildGroups();
    final sections = _buildSections();
    final pad = _compact ? 8.0 : 12.0;

    return Expanded(
      child: Container(
        color: _kPageBg,
        padding: EdgeInsets.fromLTRB(pad, 10, pad, pad),
        child: Column(
          children: [
            if (widget.onGroupChanged != null) _buildGroupTabs(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildMainCard(groups, sections)),
                  SizedBox(width: _compact ? 8 : 14),
                  _buildSensorCard(groups),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────── tabs ─────────────────────────────

  Widget _buildGroupTabs() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xffDCE5E7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (final opt in widget.groupOptions) _buildTab(opt)],
        ),
      ),
    );
  }

  Widget _buildTab(String option) {
    final selected = option.toLowerCase() == widget.fixedColumn.toLowerCase();
    return Material(
      color: selected ? _kTeal : Colors.transparent,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => widget.onGroupChanged?.call(option),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          child: Text(
            option,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : const Color(0xff4F5F66),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────── main (left) card ───────────────────────

  Widget _buildMainCard(List<_GroupInfo> groups, List<_Section> sections) {
    final contentWidth = sections.fold<double>(0, (a, s) => a + s.width);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          SizedBox(
            height: _kBannerHeight + _kHeaderHeight,
            child: SingleChildScrollView(
              controller: _horizontalScroll1,
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final s in sections) _sectionHeader(s)],
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = contentWidth > c.maxWidth ? contentWidth : c.maxWidth;
                return Scrollbar(
                  controller: _horizontalScroll2,
                  thumbVisibility: !_compact,
                  child: SingleChildScrollView(
                    controller: _horizontalScroll2,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: w,
                      child: CustomScrollView(
                        controller: _verticalScroll2,
                        slivers: _groupSlivers(
                          groups,
                          _mainGroupHeader,
                              (a, b) => _mainRows(sections, a, b),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// One sliver group per date: pinned header + that date's rows.
  List<Widget> _groupSlivers(
      List<_GroupInfo> groups,
      Widget Function(_GroupInfo g) header,
      Widget Function(int start, int end) body,
      ) {
    return [
      for (final g in groups)
        if (g.key == null)
          SliverToBoxAdapter(child: body(g.start, g.end))
        else
          SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _GroupHeaderDelegate(
                  height: _kGroupHeight,
                  child: header(g),
                ),
              ),
              SliverToBoxAdapter(child: body(g.start, g.end)),
            ],
          ),
    ];
  }

  Widget _mainRows(List<_Section> sections, int a, int b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in sections)
          SizedBox(
            width: s.width,
            child: Column(
              children: [for (var i = a; i < b; i++) _sectionEntry(s, i)],
            ),
          ),
      ],
    );
  }

  /// Date header of the main table. The text follows the horizontal scroll so
  /// it is always visible at the left edge.
  Widget _mainGroupHeader(_GroupInfo g) {
    return Container(
      color: _kGroupBg,
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _horizontalScroll2,
        builder: (context, _) {
          final dx =
          _horizontalScroll2.hasClients ? _horizontalScroll2.offset : 0.0;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    g.key ?? '',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kTeal,
                    ),
                  ),
                  if (g.summary.isNotEmpty) ...[
                    const SizedBox(width: 18),
                    Text(
                      g.summary,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _kHeaderText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sensorGroupHeader(_GroupInfo g) {
    return Container(
      color: _kGroupBg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: _compact
          ? null
          : Text(
        g.key ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _kTeal,
        ),
      ),
    );
  }

  /// Section name that stays visible (at the left of the visible part of its
  /// section) while the table is scrolled sideways.
  Widget _bannerTitle(_Section s) {
    return AnimatedBuilder(
      animation: _horizontalScroll1,
      builder: (context, _) {
        final off =
        _horizontalScroll1.hasClients ? _horizontalScroll1.offset : 0.0;
        final maxDx = s.width > 140 ? s.width - 140 : 0.0;
        final dx = (off - s.left).clamp(0.0, maxDx).toDouble();
        return Align(
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                s.title,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kTeal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(_Section s) {
    final visibleColumns = s.isGeneral
        ? widget.generalColumn
        : s.columns.where((c) => c != 'Name').toList();
    final Border? divider =
    s.divider ? const Border(left: BorderSide(color: _kSectionLine)) : null;
    return SizedBox(
      width: s.width,
      child: Column(
        children: [
          Container(
            height: _kBannerHeight,
            decoration: BoxDecoration(color: _kBannerBg, border: divider),
            child: _bannerTitle(s),
          ),
          Container(
            height: _kHeaderHeight,
            decoration: BoxDecoration(color: _kHeaderBg, border: divider),
            child: Row(
              children: [
                for (final c in visibleColumns)
                  Container(
                    width: s.isGeneral ? _generalWidth('$c') : s.colWidth,
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _labelFor('$c'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kHeaderText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── rows ─────────────────────────

  BoxDecoration _rowDecorationFor(_Section s) => BoxDecoration(
    border: Border(
      left: s.divider
          ? const BorderSide(color: _kSectionLine)
          : BorderSide.none,
      bottom: const BorderSide(color: _kLine),
    ),
  );

  Widget _sectionEntry(_Section s, int i) {
    final h = _rowHeight(i);

    if (s.isGeneral) {
      return Container(
        width: s.width,
        height: h,
        decoration: _rowDecorationFor(s),
        child: Row(
          children: [
            for (var j = 0; j < widget.generalColumn.length; j++)
              _generalCell(i, j, h),
          ],
        ),
      );
    }

    final List rowData = (i < s.data.length && s.data[i] is List)
        ? s.data[i] as List
        : const [];
    final visibleCount = s.columns.where((c) => c != 'Name').length;
    return Container(
      width: s.width,
      height: h,
      decoration: _rowDecorationFor(s),
      child: Row(
        children: [
          for (var j = 0; j < rowData.length && j < visibleCount; j++)
            Container(
              width: s.colWidth,
              padding: const EdgeInsets.only(left: 16, right: 8),
              alignment: Alignment.centerLeft,
              child: _textValue(rowData[j]),
            ),
        ],
      ),
    );
  }

  /// A single cell of the General section (or the pinned first column).
  /// Display only – nothing in here is tappable.
  Widget _generalCell(int i, int j, double h, {bool pinned = false}) {
    final name = '${widget.generalColumn[j]}';
    final row = widget.generalColumnData[i];
    final dynamic value = (row is List && j < row.length) ? row[j] : null;
    final double width = pinned ? _kPinnedWidth : _generalWidth(name);

    Widget child;
    Alignment alignment = Alignment.centerLeft;
    EdgeInsets padding = EdgeInsets.only(left: pinned ? 18 : 16, right: 8);

    if (name == 'Status') {
      child = _statusChip(value);
    } else if (_pumpCtColumns.contains(name)) {
      alignment = Alignment.center;
      padding = const EdgeInsets.symmetric(horizontal: 4);
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [Flexible(child: buildPumpCtCard('${value ?? '-'}'))],
      );
    } else if (name == 'Valve' || name == 'Valves') {
      child = _valveCell(value);
    } else if (_reasonColumns.contains(name)) {
      child = reasonCell('${value ?? '-'}', h);
    } else {
      child = _textValue(value, bold: pinned);
    }

    return Container(
      width: width,
      height: h,
      padding: padding,
      alignment: alignment,
      child: child,
    );
  }

  /// Valve column: up to 3 valves are listed; with more, the first 3 are shown
  /// followed by a tappable "..." that opens a hint listing every valve.
  Widget _valveCell(dynamic value) {
    final text = value == null ? '' : '$value';
    if (_isBlank(text)) return _textValue(value);

    final valves = text
        .split(RegExp(r'[,\n]'))
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (valves.length <= 3) return _textValue(value);

    return Row(
      children: [
        Flexible(
          child: Text(
            valves.take(3).join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, color: _kBodyText),
          ),
        ),
        const SizedBox(width: 4),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: valves.join('\n'),
            triggerMode: TooltipTriggerMode.tap,
            showDuration: const Duration(seconds: 5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kSectionLine),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kBodyText,
              height: 1.5,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _kBannerBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kTeal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textValue(dynamic value, {bool bold = false}) {
    final text = value == null ? '' : '$value';
    if (_isBlank(text)) {
      return const Text(
        '–',
        style: TextStyle(fontSize: 13.5, color: _kMutedText),
      );
    }
    return Tooltip(
      message: text,
      child: Text(
        text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: _kBodyText,
        ),
      ),
    );
  }

  Widget _statusChip(dynamic raw) {
    final label = '${getStatus(raw)['status']}';
    final style = _statusStyle(label);

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: style.dot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: style.fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(String label) {
    final l = label.toLowerCase();
    if (l.contains('pend') || l.contains('wait') || l.contains('pause')) {
      return const _StatusStyle(
          Color(0xffFDEFCF), Color(0xff8A5A00), Color(0xffD98A00));
    }
    if (l.contains('run') || l.contains('progress') || l.contains('active')) {
      return const _StatusStyle(
          Color(0xffDDF3E4), Color(0xff1E7A3C), Color(0xff2E9E4F));
    }
    if (l.contains('stop') ||
        l.contains('skip') ||
        l.contains('fail') ||
        l.contains('error') ||
        l.contains('abort')) {
      return const _StatusStyle(
          Color(0xffFDE3E1), Color(0xffB3261E), Color(0xffD93025));
    }
    // Completed / anything else
    return const _StatusStyle(
        Color(0xffE4EBEF), Color(0xff3D4E56), Color(0xff55666E));
  }

  // ───────────────────── sensor report (right card) ─────────────────────

  Widget _buildSensorCard(List<_GroupInfo> groups) {
    return Container(
      width: _compact ? 60 : _kSensorWidth,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240B5D6B),
            blurRadius: 14,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(height: _kBannerHeight, color: _kBannerBg),
          Container(
            height: _kHeaderHeight,
            color: _kHeaderBg,
            alignment: Alignment.center,
            child: _compact
                ? const Icon(Icons.bar_chart_rounded,
                size: 20, color: _kHeaderText)
                : const Text(
              'Sensor report',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kHeaderText,
              ),
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _verticalScroll3,
              thumbVisibility: !_compact,
              child: CustomScrollView(
                controller: _verticalScroll3,
                slivers: _groupSlivers(
                  groups,
                  _sensorGroupHeader,
                      (a, b) => Column(
                    children: [for (var i = a; i < b; i++) _sensorRow(i)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensorRow(int i) {
    final h = _rowHeight(i);
    return Container(
      height: h,
      alignment: Alignment.center,
      decoration: _kRowDecoration,
      child: _compact
      // phone: icon only
          ? SizedBox(
        width: 40,
        height: 40,
        child: ElevatedButton(
          onPressed: () => _openSensors(i),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kTeal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: const Icon(Icons.bar_chart_rounded, size: 20),
        ),
      )
          : ElevatedButton.icon(
        onPressed: () => _openSensors(i),
        icon: const Icon(Icons.bar_chart_rounded, size: 18),
        label: const Text('Sensors'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle:
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Only the "Sensors" button calls this – table cells / rows are not tappable.
  void _openSensors(int rowIndex) {
    if (widget.onSequenceClicked == null ||
        widget.generalColumnData.length <= rowIndex) {
      return;
    }
    String seqName = '';
    final row = widget.generalColumnData[rowIndex];
    for (int j = 0; j < widget.generalColumn.length; j++) {
      if (['Sequence', 'Valves', 'Valve', 'SequenceData']
          .contains(widget.generalColumn[j])) {
        if (row != null && j < row.length) {
          seqName = row[j]?.toString() ?? '';
          break;
        }
      }
    }
    if (seqName.isEmpty && widget.fixedColumnData.length > rowIndex) {
      seqName = widget.fixedColumnData[rowIndex]?.toString() ?? '';
    }
    if (seqName.isNotEmpty) {
      widget.onSequenceClicked!(seqName);
    }
  }

  // ───────────────────────── data helpers ─────────────────────────

  double _rowHeight(int i) =>
      getBoxHeight(widget.filterColumnData, i, widget.generalColumnData);

  String _labelFor(String name) => _labels[name] ?? name;

  double _generalWidth(String name) {
    if (name == 'Status') return 160;
    if (name == 'Line') return 170;
    if (name == 'Sequence' || name == 'SequenceData' || name == 'Valves') {
      return 160;
    }
    if (name == 'Valve') return 150;
    if (_timeColumns.contains(name)) return 130;
    if (_reasonColumns.contains(name) ||
        _pumpCtColumns.contains(name) ||
        _pressureColumns.contains(name)) {
      return 200;
    }
    return 130;
  }

  String _groupKey(int i) =>
      i < widget.fixedColumnData.length ? '${widget.fixedColumnData[i]}' : '';

  dynamic _totalTimeFor(String key) {
    for (final item in widget.graphData) {
      if (item is Map && '${item['name']}' == key && item['totalTime'] != null) {
        return item['totalTime'];
      }
    }
    return null;
  }

  /// Consecutive rows with the same group value (e.g. the same date).
  List<_GroupInfo> _buildGroups() {
    final n = widget.generalColumnData.length;
    if (n == 0) return const [];
    if (widget.fixedColumnData.isEmpty) {
      return [
        _GroupInfo(key: null, count: n, totalTime: null, start: 0, end: n)
      ];
    }
    final groups = <_GroupInfo>[];
    var i = 0;
    while (i < n) {
      final key = _groupKey(i);
      var end = i;
      while (end < n && _groupKey(end) == key) {
        end++;
      }
      groups.add(_GroupInfo(
        key: key,
        count: end - i,
        totalTime: _totalTimeFor(key),
        start: i,
        end: end,
      ));
      i = end;
    }
    return groups;
  }

  List<_Section> _buildSections() {
    final sections = <_Section>[];
    double left = 0;

    void add(String title, List<dynamic> columns, List<dynamic> data,
        double colWidth,
        {bool isGeneral = false}) {
      if (columns.isEmpty) return;
      double content = 0;
      if (isGeneral) {
        for (final c in columns) {
          content += _generalWidth('$c');
        }
      } else {
        content = columns.where((c) => c != 'Name').length * colWidth;
      }
      final divider = sections.isNotEmpty;
      final width = content + (divider ? 1 : 0);
      sections.add(_Section(
        title: title,
        columns: columns,
        data: data,
        colWidth: colWidth,
        width: width,
        left: left,
        divider: divider,
        isGeneral: isGeneral,
      ));
      left += width;
    }

    add('General', widget.generalColumn, widget.generalColumnData, 0,
        isGeneral: true);
    add('Water', widget.waterColumn, widget.waterColumnData, 100);
    add('Filter', widget.filterColumn, widget.filterColumnData, 200);
    add('Pre Post', widget.prePostColumn, widget.prePostColumnData, 100);

    add('<C-EC-PH>', widget.centralEcPhColumn, widget.centralEcPhColumnData,
        100);
    final centralChannels = [
      [widget.centralChannel1Column, widget.centralChannel1ColumnData],
      [widget.centralChannel2Column, widget.centralChannel2ColumnData],
      [widget.centralChannel3Column, widget.centralChannel3ColumnData],
      [widget.centralChannel4Column, widget.centralChannel4ColumnData],
      [widget.centralChannel5Column, widget.centralChannel5ColumnData],
      [widget.centralChannel6Column, widget.centralChannel6ColumnData],
      [widget.centralChannel7Column, widget.centralChannel7ColumnData],
      [widget.centralChannel8Column, widget.centralChannel8ColumnData],
    ];
    for (var n = 0; n < centralChannels.length; n++) {
      add('<C-CH${n + 1}>', centralChannels[n][0], centralChannels[n][1], 100);
    }

    add('<L-EC-PH>', widget.localEcPhColumn, widget.localEcPhColumnData, 100);
    final localChannels = [
      [widget.localChannel1Column, widget.localChannel1ColumnData],
      [widget.localChannel2Column, widget.localChannel2ColumnData],
      [widget.localChannel3Column, widget.localChannel3ColumnData],
      [widget.localChannel4Column, widget.localChannel4ColumnData],
      [widget.localChannel5Column, widget.localChannel5ColumnData],
      [widget.localChannel6Column, widget.localChannel6ColumnData],
      [widget.localChannel7Column, widget.localChannel7ColumnData],
      [widget.localChannel8Column, widget.localChannel8ColumnData],
    ];
    for (var n = 0; n < localChannels.length; n++) {
      add('<L-CH${n + 1}>', localChannels[n][0], localChannels[n][1], 100);
    }

    return sections;
  }
}

bool _isBlank(String text) {
  final t = text.trim();
  return t.isEmpty || t == '-';
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers (kept public – other files may use them)
// ─────────────────────────────────────────────────────────────────────────────

const int _kBoxHeightCharsPerLine = 20;

int _estimatedLinesFor(String text) {
  int lines = 0;
  for (var segment in text.split('\n')) {
    if (segment.isEmpty) {
      lines += 1;
    } else if (segment.contains(', ')) {
      // Wrapping text (e.g. "13.001, 13.002, 13.003" in the Valves/Sequence
      // columns) - estimate how many lines it needs instead of clipping.
      lines += (segment.length / _kBoxHeightCharsPerLine).ceil().clamp(1, 3);
    } else {
      lines += 1;
    }
  }
  return lines;
}

Color reasonColor(String reason) {
  final r = reason.trim().toLowerCase();
  if (r.isEmpty || r == '-') return Colors.black45;
  if (r.contains('stopped')) return const Color(0xffC62828);
  if (r.contains('skipped')) return const Color(0xffD84315);
  if (r.contains('paused')) return const Color(0xffEF6C00);
  if (r.contains('completed')) return const Color(0xff2E7D32);
  if (r.contains('resumed')) return const Color(0xff00838F);
  if (r.contains('started')) return const Color(0xff1565C0);
  return const Color(0xff424242);
}

IconData reasonIcon(String reason) {
  final r = reason.trim().toLowerCase();
  if (r.isEmpty || r == '-') return Icons.remove;
  if (r.contains('stopped')) return Icons.stop_circle_outlined;
  if (r.contains('skipped')) return Icons.skip_next_rounded;
  if (r.contains('paused')) return Icons.pause_circle_outline;
  if (r.contains('completed')) return Icons.check_circle_outline;
  if (r.contains('resumed')) return Icons.play_circle_outline;
  if (r.contains('started')) return Icons.play_arrow_rounded;
  return Icons.fiber_manual_record;
}

/// Renders a multi-line reason string (one reason per irrigation cycle,
/// separated by '\n') as plain text lines, matching the reference design
/// ("Schedule", "Timer ended", "Manual stop", ...).
Widget reasonCell(String raw, double height) {
  final lines = raw.split('\n');
  return SizedBox(
    height: height,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Tooltip(
              message: line,
              child: _isBlank(line)
                  ? const Text(
                '–',
                style: TextStyle(fontSize: 13.5, color: _kMutedText),
              )
                  : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: reasonColor(line),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

double getBoxHeight(dynamic filterColumnData, int i,
    [dynamic generalColumnData]) {
  int maxLines = 1;

  if (generalColumnData != null &&
      i < generalColumnData.length &&
      generalColumnData[i] is List) {
    for (var item in generalColumnData[i]) {
      if (item != null) {
        int lines = _estimatedLinesFor(item.toString());
        if (lines > maxLines) maxLines = lines;
      }
    }
  }

  if (filterColumnData != null &&
      i < filterColumnData.length &&
      filterColumnData[i] is List &&
      filterColumnData[i].isNotEmpty) {
    for (var item in filterColumnData[i]) {
      if (item != null) {
        int lines = _estimatedLinesFor(item.toString());
        if (lines > maxLines) maxLines = lines;
      }
    }
  }

  return (64 + ((maxLines - 1) * 17)).toDouble();
}

Widget getColumnDotLine() {
  return SizedBox(
    width: 0,
    height: 50,
    child: CustomPaint(
      painter: VerticalDotBorder(),
      size: Size(0, 50),
    ),
  );
}

class VerticalDotBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint border = Paint();
    border.color = Colors.black;
    border.strokeWidth = 0.5;
    final double dashWidth = 5;
    final double dashSpace = 5;
    double currentY = 0;

    while (currentY < size.height) {
      canvas.drawLine(
          Offset(0, currentY), Offset(0, currentY + dashWidth), border);
      currentY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}