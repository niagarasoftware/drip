import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../model/fertigation_card_model.dart';

class FertigationTableView extends StatefulWidget {
  final List<FertigationCardModel> cards;

  const FertigationTableView({
    super.key,
    required this.cards,
  });

  @override
  State<FertigationTableView> createState() =>
      _FertigationTableViewState();
}

class _FertigationTableViewState extends State<FertigationTableView> {
  // =========================================================
  // CONTROLLERS AND CONSTANTS
  // =========================================================

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const double _horizontalStep = 300.0;
  static const double _verticalStep = 180.0;
  static const double _rowHeight = 60.0;
  static const double _headingHeight = 48.0;

  static const Color _primaryColor = Color(0xFF006573);
  static const Color _lightColor = Color(0xFFEDF4F4);

  bool _isAtTop = true;
  bool _isAtBottom = false;
  int _currentRow = 1;

  int get _totalRows => widget.cards.length;

  // =========================================================
  // LIFECYCLE
  // =========================================================

  @override
  void initState() {
    super.initState();

    _verticalController.addListener(_checkVerticalPosition);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkVerticalPosition();
    });
  }

  @override
  void didUpdateWidget(covariant FertigationTableView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.cards.length != widget.cards.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkVerticalPosition();
      });
    }
  }

  void _checkVerticalPosition() {
    if (!mounted || !_verticalController.hasClients) return;

    final position = _verticalController.position;

    if (!position.hasContentDimensions) return;

    final bool atTop =
        position.pixels <= position.minScrollExtent + 2;

    final bool atBottom =
        position.pixels >= position.maxScrollExtent - 2;

    final int currentRow = _totalRows == 0
        ? 0
        : atBottom
        ? _totalRows
        : (position.pixels / _rowHeight).floor() + 1;

    final int safeRow =
    currentRow.clamp(0, _totalRows).toInt();

    if (_isAtTop != atTop ||
        _isAtBottom != atBottom ||
        _currentRow != safeRow) {
      setState(() {
        _isAtTop = atTop;
        _isAtBottom = atBottom;
        _currentRow = safeRow;
      });
    }
  }

  @override
  void dispose() {
    _verticalController.removeListener(_checkVerticalPosition);

    _horizontalController.dispose();
    _verticalController.dispose();

    super.dispose();
  }

  // =========================================================
  // HORIZONTAL SCROLL
  // =========================================================

  void _scrollHorizontal(double offset) {
    if (!_horizontalController.hasClients) return;

    final position = _horizontalController.position;

    if (!position.hasContentDimensions) return;

    final double target = offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    ).toDouble();

    _horizontalController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _scrollFirst() {
    _scrollHorizontal(0);
  }

  void _scrollLeft() {
    if (!_horizontalController.hasClients) return;

    _scrollHorizontal(
      _horizontalController.offset - _horizontalStep,
    );
  }

  void _scrollRight() {
    if (!_horizontalController.hasClients) return;

    _scrollHorizontal(
      _horizontalController.offset + _horizontalStep,
    );
  }

  void _scrollLast() {
    if (!_horizontalController.hasClients) return;

    _scrollHorizontal(
      _horizontalController.position.maxScrollExtent,
    );
  }

  // =========================================================
  // VERTICAL SCROLL
  // =========================================================

  void _scrollVertical(double offset) {
    if (!_verticalController.hasClients) return;

    final position = _verticalController.position;

    if (!position.hasContentDimensions) return;

    final double target = offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    ).toDouble();

    _verticalController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _scrollTop() {
    _scrollVertical(0);
  }

  void _scrollUp() {
    if (!_verticalController.hasClients) return;

    _scrollVertical(
      _verticalController.offset - _verticalStep,
    );
  }

  void _scrollDown() {
    if (!_verticalController.hasClients) return;

    _scrollVertical(
      _verticalController.offset + _verticalStep,
    );
  }

  void _scrollBottom() {
    if (!_verticalController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_verticalController.hasClients) return;
      final position = _verticalController.position;
      if (position.hasContentDimensions) {
        _verticalController.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });

    // Also scroll parent vertical scrollable to reveal table bottom in normal mode
    ScrollableState? parentScrollable = Scrollable.maybeOf(context);
    if (parentScrollable != null) {
      final parentPosition = parentScrollable.position;
      parentPosition.animateTo(
        (parentPosition.pixels + 350).clamp(parentPosition.minScrollExtent, parentPosition.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // =========================================================
  // NAVIGATION BUTTON
  // =========================================================

  Widget _scrollButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: enabled ? onPressed : null,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFD5E4E4),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 20,
                color: enabled
                    ? _primaryColor
                    : Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // HORIZONTAL BUTTONS
  // =========================================================

  Widget _buildHorizontalButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _scrollButton(
          icon: Icons.keyboard_double_arrow_left,
          tooltip: 'First Column',
          onPressed: _scrollFirst,
        ),
        _scrollButton(
          icon: Icons.chevron_left,
          tooltip: 'Scroll Left',
          onPressed: _scrollLeft,
        ),
        _scrollButton(
          icon: Icons.chevron_right,
          tooltip: 'Scroll Right',
          onPressed: _scrollRight,
        ),
        _scrollButton(
          icon: Icons.keyboard_double_arrow_right,
          tooltip: 'Last Column',
          onPressed: _scrollLast,
        ),
      ],
    );
  }

  // =========================================================
  // VERTICAL BUTTONS
  // =========================================================

  Widget _buildVerticalButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _scrollButton(
          icon: Icons.keyboard_double_arrow_up,
          tooltip: 'First Row',
          onPressed: _scrollTop,
          enabled: !_isAtTop,
        ),
        _scrollButton(
          icon: Icons.keyboard_arrow_up,
          tooltip: 'Scroll Up',
          onPressed: _scrollUp,
          enabled: !_isAtTop,
        ),
        _scrollButton(
          icon: Icons.keyboard_arrow_down,
          tooltip: 'Scroll Down',
          onPressed: _scrollDown,
          enabled: !_isAtBottom,
        ),
        _scrollButton(
          icon: Icons.keyboard_double_arrow_down,
          tooltip: 'Last Row',
          onPressed: _scrollBottom,
          enabled: !_isAtBottom,
        ),
      ],
    );
  }

  // =========================================================
  // ROW POSITION INDICATOR
  // =========================================================

  Widget _buildRowIndicator() {
    final bool allVisible =
        _isAtTop && _isAtBottom && _totalRows > 0;

    final String statusText;

    if (_totalRows == 0) {
      statusText = 'No Records';
    } else if (allVisible) {
      statusText = 'All Rows Visible';
    } else if (_isAtBottom) {
      statusText = 'Last Row Reached';
    } else if (_isAtTop) {
      statusText = 'First Row';
    } else {
      statusText = 'Scrolling';
    }

    final Color statusColor = _isAtBottom
        ? const Color(0xFF16803C)
        : _primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _isAtBottom
            ? const Color(0xFFE8F7EC)
            : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: _isAtBottom
              ? const Color(0xFFB8E3C4)
              : const Color(0xFFD5E4E4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isAtBottom
                ? Icons.check_circle
                : Icons.format_list_numbered,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            'Row $_currentRow of $_totalRows',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FIXED NAVIGATION BAR
  // =========================================================

  Widget _buildNavigationBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: _lightColor,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFD5E4E4),
          ),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Fertigation Report',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildHorizontalButtons(),
          _buildVerticalButtons(),
          _buildRowIndicator(),
        ],
      ),
    );
  }

  // =========================================================
  // COLUMN HELPER
  // =========================================================

  DataColumn2 _column(
      String title, {
        ColumnSize size = ColumnSize.S,
        double? fixedWidth,
      }) {
    return DataColumn2(
      label: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: _primaryColor,
          fontSize: 11,
        ),
      ),
      size: size,
      fixedWidth: fixedWidth,
    );
  }

  // =========================================================
  // CELL HELPER
  // =========================================================

  DataCell _textCell(
      String value, {
        double fontSize = 11,
        double? height,
      }) {
    return DataCell(
      Text(
        value,
        style: TextStyle(
          fontSize: fontSize,
          height: height,
        ),
      ),
    );
  }

  bool _hasValidValue(String value) {
    final text = value.trim();

    return text.isNotEmpty &&
        text != '—' &&
        text != '-' &&
        text != '0' &&
        text != '0m' &&
        text != '00:00:00';
  }

  // =========================================================
  // MAIN BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;

    if (cards.isEmpty) {
      return const Center(
        child: Text(
          'No Fertigation Records Found',
          style: TextStyle(
            color: Color(0xFF637D7A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // =====================================================
    // OPTIONAL COLUMN VISIBILITY
    // =====================================================

    final bool showPre =
    cards.any((c) => _hasValidValue(c.preTimeQty));

    final bool showPost =
    cards.any((c) => _hasValidValue(c.postTimeQty));

    final bool showCentralEc = cards.any(
          (c) =>
      (c.centralEcSet != '—' && c.centralEcSet.isNotEmpty) ||
          (c.centralEcMin != '—' && c.centralEcMin.isNotEmpty) ||
          (c.centralEcMax != '—' && c.centralEcMax.isNotEmpty) ||
          (c.centralEcAvg != '—' && c.centralEcAvg.isNotEmpty),
    );

    final bool showCentralPh = cards.any(
          (c) =>
      (c.centralPhSet != '—' && c.centralPhSet.isNotEmpty) ||
          (c.centralPhMin != '—' && c.centralPhMin.isNotEmpty) ||
          (c.centralPhMax != '—' && c.centralPhMax.isNotEmpty) ||
          (c.centralPhAvg != '—' && c.centralPhAvg.isNotEmpty),
    );

    final bool showLocalEc = cards.any(
          (c) =>
      (c.localEcSet != '—' && c.localEcSet.isNotEmpty) ||
          (c.localEcMin != '—' && c.localEcMin.isNotEmpty) ||
          (c.localEcMax != '—' && c.localEcMax.isNotEmpty) ||
          (c.localEcAvg != '—' && c.localEcAvg.isNotEmpty),
    );

    final bool showLocalPh = cards.any(
          (c) =>
      (c.localPhSet != '—' && c.localPhSet.isNotEmpty) ||
          (c.localPhMin != '—' && c.localPhMin.isNotEmpty) ||
          (c.localPhMax != '—' && c.localPhMax.isNotEmpty) ||
          (c.localPhAvg != '—' && c.localPhAvg.isNotEmpty),
    );

    // =====================================================
    // ACTIVE CENTRAL / LOCAL CHANNELS
    // =====================================================

    final Set<int> activeCentralChannels = {};
    final Set<int> activeLocalChannels = {};

    for (final card in cards) {
      for (final channel in card.centralChannels) {
        if (channel.planned != '—' || channel.actual != '—') {
          final int? number = int.tryParse(
            channel.name.replaceAll(RegExp(r'[^0-9]'), ''),
          );

          if (number != null) {
            activeCentralChannels.add(number);
          }
        }
      }

      for (final channel in card.localChannels) {
        if (channel.planned != '—' || channel.actual != '—') {
          final int? number = int.tryParse(
            channel.name.replaceAll(RegExp(r'[^0-9]'), ''),
          );

          if (number != null) {
            activeLocalChannels.add(number);
          }
        }
      }
    }

    List<int> sortedCentral = activeCentralChannels.toList()..sort();
    List<int> sortedLocal = activeLocalChannels.toList()..sort();

    if (sortedCentral.isEmpty && sortedLocal.isEmpty) {
      sortedCentral = [1, 2, 3, 4];
    }

    // =====================================================
    // TABLE COLUMNS
    // =====================================================

    final List<DataColumn2> columns = [
      _column('Sr.No', fixedWidth: 50),
      _column('Date'),
      _column('Program', size: ColumnSize.M),
      _column('Sequence', size: ColumnSize.M),
      _column('Line'),
      _column('Status'),
      _column('Water Planned'),
      _column('Water Actual'),
    ];

    if (showPre) columns.add(_column('PRE'));
    if (showPost) columns.add(_column('POST'));

    if (showCentralEc) columns.add(_column('Central EC'));
    if (showCentralPh) columns.add(_column('Central pH'));

    if (showLocalEc) columns.add(_column('Local EC'));
    if (showLocalPh) columns.add(_column('Local pH'));

    for (final number in sortedCentral) {
      columns.add(_column('C-CH$number'));
    }

    for (final number in sortedLocal) {
      columns.add(_column('L-CH$number'));
    }

    columns.addAll([
      _column('Start Time'),
      _column('Stop Time'),
    ]);

    // =====================================================
    // TABLE DIMENSIONS
    // =====================================================

    final double minTableWidth = math.max(
      1000.0 +
          (sortedCentral.length +
              sortedLocal.length +
              (showPre ? 1 : 0) +
              (showPost ? 1 : 0) +
              (showCentralEc ? 1 : 0) +
              (showCentralPh ? 1 : 0) +
              (showLocalEc ? 1 : 0) +
              (showLocalPh ? 1 : 0)) *
              80.0,
      columns.length * 85.0,
    );

    final double screenHeight = MediaQuery.of(context).size.height;
    final double responsiveHeight = (screenHeight * 0.55).clamp(300.0, 750.0);
    final double tableHeight = math.min(
      (cards.length * _rowHeight + _headingHeight + 24.0),
      responsiveHeight,
    );

    // =====================================================
    // TABLE ROWS
    // =====================================================

    final List<DataRow2> rows = cards.asMap().entries.map((entry) {
      final int index = entry.key;
      final card = entry.value;

      final List<DataCell> cells = [
        _textCell('${index + 1}'),
        _textCell(card.date),
        _textCell(card.programName),
        _textCell(card.sequenceName),
        _textCell(card.lineName),

        // STATUS
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: card.statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              card.status,
              style: TextStyle(
                color: card.statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),

        _textCell(card.waterPlanned),
        _textCell(card.waterActual),
      ];

      // PRE
      if (showPre) {
        final String preValue = _hasValidValue(card.preTimeQty)
            ? '${card.preMethod}: ${card.preTimeQty}'
            : '—';

        cells.add(_textCell(preValue, fontSize: 10));
      }

      // POST
      if (showPost) {
        final String postValue = _hasValidValue(card.postTimeQty)
            ? '${card.preMethod}: ${card.postTimeQty}'
            : '—';

        cells.add(_textCell(postValue, fontSize: 10));
      }

      // CENTRAL EC
      if (showCentralEc) {
        cells.add(
          _textCell(
            _formatEcPh(
              card.centralEcSet,
              card.centralEcMin,
              card.centralEcMax,
              card.centralEcAvg,
            ),
            fontSize: 10,
            height: 1.2,
          ),
        );
      }

      // CENTRAL PH
      if (showCentralPh) {
        cells.add(
          _textCell(
            _formatEcPh(
              card.centralPhSet,
              card.centralPhMin,
              card.centralPhMax,
              card.centralPhAvg,
            ),
            fontSize: 10,
            height: 1.2,
          ),
        );
      }

      // LOCAL EC
      if (showLocalEc) {
        cells.add(
          _textCell(
            _formatEcPh(
              card.localEcSet,
              card.localEcMin,
              card.localEcMax,
              card.localEcAvg,
            ),
            fontSize: 10,
            height: 1.2,
          ),
        );
      }

      // LOCAL PH
      if (showLocalPh) {
        cells.add(
          _textCell(
            _formatEcPh(
              card.localPhSet,
              card.localPhMin,
              card.localPhMax,
              card.localPhAvg,
            ),
            fontSize: 10,
            height: 1.2,
          ),
        );
      }

      // CENTRAL CHANNELS
      for (final number in sortedCentral) {
        final found = card.centralChannels.firstWhere(
              (c) =>
          c.name.replaceAll(RegExp(r'[^0-9]'), '') ==
              number.toString(),
          orElse: () => FertigationChannelModel(
            name: 'C-CH$number',
            planned: '—',
            actual: '—',
            isCentral: true,
          ),
        );

        final bool hasData = card.centralChannels.any(
              (c) =>
          c.name.replaceAll(RegExp(r'[^0-9]'), '') ==
              number.toString() &&
              ((c.planned != '—' && c.planned != '0') ||
                  (c.actual != '—' && c.actual != '0')),
        );

        final String value = hasData
            ? 'P:${found.planned}\nA:${found.actual}'
            : '—';

        cells.add(
          _textCell(
            value,
            fontSize: 10,
            height: 1.2,
          ),
        );
      }

      // LOCAL CHANNELS
      for (final number in sortedLocal) {
        final found = card.localChannels.firstWhere(
              (c) =>
          c.name.replaceAll(RegExp(r'[^0-9]'), '') ==
              number.toString(),
          orElse: () => FertigationChannelModel(
            name: 'L-CH$number',
            planned: '—',
            actual: '—',
            isCentral: false,
          ),
        );

        final bool hasData = card.localChannels.any(
              (c) =>
          c.name.replaceAll(RegExp(r'[^0-9]'), '') ==
              number.toString() &&
              ((c.planned != '—' && c.planned != '0') ||
                  (c.actual != '—' && c.actual != '0')),
        );

        final String value = hasData
            ? 'P:${found.planned}\nA:${found.actual}'
            : '—';

        cells.add(
          _textCell(
            value,
            fontSize: 10,
            height: 1.2,
          ),
        );
      }

      // START / STOP TIME
      cells.addAll([
        _textCell(card.startTime),
        _textCell(card.stopTime),
      ]);

      return DataRow2(cells: cells);
    }).toList();

    // =====================================================
    // MAIN UI
    // =====================================================

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE7EEEE),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIXED NAVIGATION BAR
            _buildNavigationBar(),

            // SCROLLABLE TABLE
            SizedBox(
              height: tableHeight,
              child: DataTable2(
                fixedLeftColumns: 2,
                horizontalScrollController: _horizontalController,
                scrollController: _verticalController,

                columnSpacing: 10,
                horizontalMargin: 12,
                minWidth: minTableWidth,

                headingRowColor: WidgetStateProperty.all(
                  _lightColor,
                ),
                headingRowHeight: _headingHeight,
                dataRowHeight: _rowHeight,

                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 0.8,
                ),

                columns: columns,
                rows: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EC / PH FORMAT
  // =========================================================

  static String _formatEcPh(
      String set,
      String min,
      String max,
      String avg,
      ) {
    final List<String> line1 = [];
    final List<String> line2 = [];

    if (set != '—' &&
        set.isNotEmpty &&
        set != '0' &&
        set != '0.0') {
      line1.add('S:$set');
    }

    if (min != '—' && min.isNotEmpty) {
      line1.add('Min:$min');
    }

    if (max != '—' && max.isNotEmpty) {
      line2.add('Max:$max');
    }

    if (avg != '—' && avg.isNotEmpty) {
      line2.add('Avg:$avg');
    }

    if (line1.isEmpty && line2.isEmpty) {
      return '—';
    }

    final List<String> lines = [];

    if (line1.isNotEmpty) {
      lines.add(line1.join(' '));
    }

    if (line2.isNotEmpty) {
      lines.add(line2.join(' '));
    }

    return lines.join('\n');
  }
}
