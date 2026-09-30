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
  });

  @override
  State<ScrollingTable> createState() => _ScrollingTableState();
}

class _ScrollingTableState extends State<ScrollingTable> {
  Widget _buildClickableRow(int rowIndex, Widget child) {
    return Tooltip(
      message: 'Tap row to view Sensor Analytics',
      waitDuration: const Duration(milliseconds: 600),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.onSequenceClicked != null && widget.generalColumnData.length > rowIndex) {
            String seqName = '';
            for (int j = 0; j < widget.generalColumn.length; j++) {
              if (['Sequence', 'Valves', 'Valve', 'SequenceData'].contains(widget.generalColumn[j])) {
                if (widget.generalColumnData[rowIndex] != null && j < widget.generalColumnData[rowIndex].length) {
                  seqName = widget.generalColumnData[rowIndex][j]?.toString() ?? '';
                  break;
                }
              }
            }
            if (seqName.isNotEmpty) {
              widget.onSequenceClicked!(seqName);
            } else {
              if (widget.fixedColumnData.length > rowIndex) {
                seqName = widget.fixedColumnData[rowIndex]?.toString() ?? '';
                if (seqName.isNotEmpty) {
                  widget.onSequenceClicked!(seqName);
                }
              }
            }
          }
        },
        child: child,
      ),
    );
  }

  late LinkedScrollControllerGroup _scrollable1;
  late ScrollController _verticalScroll1;
  late ScrollController _verticalScroll2;
  late LinkedScrollControllerGroup _scrollable2;
  late ScrollController _horizontalScroll1;
  late ScrollController _horizontalScroll2;
  @override
  void initState() {
    _scrollable1 = LinkedScrollControllerGroup();
    _verticalScroll1 = _scrollable1.addAndGet();
    _verticalScroll2 = _scrollable1.addAndGet();
    _scrollable2 = LinkedScrollControllerGroup();
    _horizontalScroll1 = _scrollable2.addAndGet();
    _horizontalScroll2 = _scrollable2.addAndGet();
    print("widget.generalColumn : ${widget.generalColumn}");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(20))),
        margin: const EdgeInsets.only(left: 5, right: 5),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            var width = constraints.maxWidth;
            return Row(
              children: [
                Column(
                  children: [
                    //Todo : first column
                    Container(
                      // color: Color(0xffF7F9FA),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                        colors: [
                          Color(0xff1C7C8A),
                          Color(0xff03464F),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )),
                      padding: const EdgeInsets.only(left: 8),
                      width: 100,
                      height: 75,
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.fixedColumn}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller: _verticalScroll1,
                        child: SingleChildScrollView(
                          controller: _verticalScroll1,
                          child: Container(
                            child: Column(
                              children: [
                                ...fixedNestedColumnWidget(),
                                // for(var i = 0;i < widget.fixedColumnData.length;i++)
                                //   Container(
                                //     color: Color(0xffDCF3DD),
                                //     padding: const EdgeInsets.only(left: 8),
                                //     width: 100,
                                //     height:getBoxHeight(widget.filterColumnData, i, widget.generalColumnData),
                                //     alignment: Alignment.center,
                                //     child: Text('${widget.fixedColumnData[i]}',style: TextStyle(color: Colors.black),),
                                //   ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                Column(
                  children: [
                    Container(
                      // color: Color(0xffF7F9FA),
                      color: Color(0xff03464F),
                      width: width - 100,
                      height: 75,
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller: _horizontalScroll1,
                        child: SingleChildScrollView(
                          controller: _horizontalScroll1,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              getColumnDotLine(),
                              if (widget.generalColumn.isNotEmpty)
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Center(
                                      child: Text(
                                        'General',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (var i = 0;
                                            i < widget.generalColumn.length;
                                            i++)
                                          Container(
                                            // color: Color(0xffEAEAEA),
                                            color: Colors.orange.shade200,
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            width: [
                                              'Status',
                                              'Sequence',
                                              'Valves',
                                              'Valve'
                                            ].contains(widget.generalColumn[i])
                                                ? 150
                                                : [
                                                    'Pump CT Average',
                                                    'Pump CT Maximum',
                                                    'Pump CT Minimum',
                                                    'Pressure Average',
                                                    'Pressure Maximum',
                                                    'Pressure Minimum',
                                                    'PressureAverage',
                                                    'PressureMaximum',
                                                    'PressureMinimum',
                                                    'Actual Start Time',
                                                    'Actual End Time',
                                                    'Actual Start Reason',
                                                    'Actual Stop Reason'
                                                  ].contains(
                                                        widget.generalColumn[i])
                                                    ? 200
                                                    : 100,
                                            height: 50,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '${widget.generalColumn[i]}',
                                              style: TextStyle(
                                                  color: Colors.black),
                                              maxLines: 2,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              getColumnDotLine(),
                              if (widget.waterColumn.isNotEmpty)
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Center(
                                      child: Text(
                                        'Water',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (var i = 0;
                                            i < widget.waterColumn.length;
                                            i++)
                                          Container(
                                            color: Colors.orange.shade200,
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            width: 100,
                                            height: 50,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '${widget.waterColumn[i]}',
                                              style: const TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              getColumnDotLine(),
                              if (widget.filterColumn.isNotEmpty)
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Center(
                                      child: Text(
                                        'Filter',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (var i = 0;
                                            i < widget.filterColumn.length;
                                            i++)
                                          Container(
                                            color: Colors.orange.shade200,
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            width: 200,
                                            height: 50,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '${widget.filterColumn[i]}',
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              getColumnDotLine(),
                              if (widget.prePostColumn.isNotEmpty)
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Center(
                                      child: Text(
                                        'Pre Post',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (var i = 0;
                                            i < widget.prePostColumn.length;
                                            i++)
                                          Container(
                                            color: Colors.orange.shade200,
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            width: 100,
                                            height: 50,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '${widget.prePostColumn[i]}',
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              getColumnDotLine(),
                              if (widget.centralEcPhColumn.isNotEmpty)
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Center(
                                      child: Text(
                                        '<C-EC-PH>',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (var i = 0;
                                            i < widget.centralEcPhColumn.length;
                                            i++)
                                          Container(
                                            color: Colors.orange.shade200,
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            width: 100,
                                            height: 50,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '${widget.centralEcPhColumn[i]}',
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              getColumnDotLine(),
                              if (widget.centralChannel1Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.centralChannel1Column,
                                    channelNo: 1,
                                    central: true),
                              getColumnDotLine(),
                              if (widget.centralChannel2Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.centralChannel2Column,
                                    channelNo: 2,
                                    central: true),
                              getColumnDotLine(),
                              if (widget.centralChannel3Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.centralChannel3Column,
                                    channelNo: 3,
                                    central: true),
                              getColumnDotLine(),
                              if (widget.centralChannel4Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.centralChannel4Column,
                                    channelNo: 4,
                                    central: true),
                              getColumnDotLine(),
                              if (widget.centralChannel5Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.centralChannel5Column,
                                    channelNo: 5,
                                    central: true),
                              getColumnDotLine(),
                              if (widget.centralChannel6Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.centralChannel6Column,
                                    channelNo: 6,
                                    central: true),
                              getColumnDotLine(),
                              if (widget.centralChannel7Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.centralChannel7Column,
                                    channelNo: 7,
                                    central: true),
                              getColumnDotLine(),
                              if (widget.centralChannel8Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.centralChannel8Column,
                                    channelNo: 8,
                                    central: true),
                              getColumnDotLine(),
                              if (widget.localEcPhColumn.isNotEmpty)
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Center(
                                      child: Text(
                                        '<L-EC-PH>',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (var i = 0;
                                            i < widget.localEcPhColumn.length;
                                            i++)
                                          Container(
                                            color: Colors.orange.shade200,
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            width: 100,
                                            height: 50,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '${widget.localEcPhColumn[i]}',
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              getColumnDotLine(),
                              if (widget.localChannel1Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.localChannel1Column,
                                    channelNo: 1,
                                    central: false),
                              getColumnDotLine(),
                              if (widget.localChannel2Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.localChannel2Column,
                                    channelNo: 2,
                                    central: false),
                              getColumnDotLine(),
                              if (widget.localChannel3Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.localChannel3Column,
                                    channelNo: 3,
                                    central: false),
                              getColumnDotLine(),
                              if (widget.localChannel4Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.localChannel4Column,
                                    channelNo: 4,
                                    central: false),
                              getColumnDotLine(),
                              if (widget.localChannel5Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.localChannel5Column,
                                    channelNo: 5,
                                    central: false),
                              getColumnDotLine(),
                              if (widget.localChannel6Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.localChannel6Column,
                                    channelNo: 6,
                                    central: false),
                              getColumnDotLine(),
                              if (widget.localChannel7Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.localChannel7Column,
                                    channelNo: 7,
                                    central: false),
                              getColumnDotLine(),
                              if (widget.localChannel8Column.isNotEmpty)
                                getChannelColumnWidget(
                                    columnList: widget.localChannel8Column,
                                    channelNo: 8,
                                    central: false),
                              getColumnDotLine(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        width: width - 100,
                        child: Scrollbar(
                          thumbVisibility: true,
                          controller: _horizontalScroll2,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _horizontalScroll2,
                            child: Scrollbar(
                              thumbVisibility: true,
                              controller: _verticalScroll2,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                controller: _verticalScroll2,
                                child: Row(
                                  children: [
                                    //TODO : GENERAL DATA
                                    Column(
                                      children: [
                                        for (var i = 0;
                                            i < widget.generalColumnData.length;
                                            i++)
                                          _buildClickableRow(
                                              i,
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width: 0,
                                                    height: getBoxHeight(
                                                        widget.filterColumnData,
                                                        i,
                                                        widget
                                                            .generalColumnData),
                                                    child: CustomPaint(
                                                      painter:
                                                          VerticalDotBorder(),
                                                      size: const Size(10, 50),
                                                    ),
                                                  ),
                                                  for (var j = 0;
                                                      j < widget.generalColumnData[i].length &&
                                                          j <
                                                              widget
                                                                  .generalColumn
                                                                  .length;
                                                      j++)
                                                    if (widget.generalColumn[j] ==
                                                        'Status')
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 8),
                                                        width: 150,
                                                        height: getBoxHeight(
                                                            widget
                                                                .filterColumnData,
                                                            i,
                                                            widget
                                                                .generalColumnData),
                                                        decoration:
                                                            BoxDecoration(
                                                          border: seperatingLength(
                                                                  i)
                                                              ? Border(
                                                                  bottom:
                                                                      BorderSide(
                                                                          width:
                                                                              1))
                                                              : null,
                                                        ),
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Container(
                                                            width: 150,
                                                            padding:
                                                                EdgeInsets.all(
                                                                    5),
                                                            decoration:
                                                                BoxDecoration(
                                                                    // color: getStatus(i[j])['color'],
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20)),
                                                            child: Tooltip(
                                                                message:
                                                                    '${getStatus(widget.generalColumnData[i][j])['status']}',
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Flexible(
                                                                      child:
                                                                          Text(
                                                                        '${getStatus(widget.generalColumnData[i][j])['status']}',
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color: getStatus(widget.generalColumnData[i][j])['textColor']),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            4),
                                                                    InkWell(
                                                                      onTap: () {
                                                                        if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                                      },
                                                                      child: const Icon(
                                                                          Icons
                                                                              .analytics_outlined,
                                                                          size:
                                                                              14,
                                                                          color: Colors
                                                                              .blue),
                                                                    ),
                                                                  ],
                                                                ))),
                                                      )
                                                    else if ([
                                                      'Pump CT Average',
                                                      'Pump CT Maximum',
                                                      'Pump CT Minimum',
                                                      'PumpCtAverage',
                                                      'PumpCtMaximum',
                                                      'PumpCtMinimum'
                                                    ].contains(widget
                                                        .generalColumn[j]))
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 4),
                                                        width: 200,
                                                        height: getBoxHeight(
                                                            widget
                                                                .filterColumnData,
                                                            i,
                                                            widget
                                                                .generalColumnData),
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: seperatingLength(
                                                                  i)
                                                              ? const Border(
                                                                  bottom:
                                                                      BorderSide(
                                                                          width:
                                                                              1))
                                                              : null,
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                                child: buildPumpCtCard(
                                                                    '${widget.generalColumnData[i][j] ?? '-'}')),
                                                            const SizedBox(
                                                                width: 4),
                                                            InkWell(
                                                              onTap: () {
                                                                if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                              },
                                                              child: const Icon(
                                                                  Icons
                                                                      .analytics_outlined,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .blue),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    else if ([
                                                      'Pressure Average',
                                                      'Pressure Maximum',
                                                      'Pressure Minimum',
                                                      'PressureAverage',
                                                      'PressureMaximum',
                                                      'PressureMinimum'
                                                    ].contains(widget
                                                        .generalColumn[j]))
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 8),
                                                        width: 200,
                                                        height: getBoxHeight(
                                                            widget
                                                                .filterColumnData,
                                                            i,
                                                            widget
                                                                .generalColumnData),
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: seperatingLength(
                                                                  i)
                                                              ? const Border(
                                                                  bottom:
                                                                      BorderSide(
                                                                          width:
                                                                              1))
                                                              : null,
                                                        ),
                                                        child: Tooltip(
                                                          message:
                                                              '${widget.generalColumnData[i][j] ?? '-'}',
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Flexible(
                                                                child: Text(
                                                                  '${widget.generalColumnData[i][j] ?? '-'}',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              InkWell(
                                                                onTap: () {
                                                                  if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                                },
                                                                child: const Icon(
                                                                    Icons
                                                                        .analytics_outlined,
                                                                    size: 14,
                                                                    color: Colors
                                                                        .blue),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                    else if ([
                                                      'Sequence',
                                                      'Valves',
                                                      'Valve'
                                                    ].contains(widget
                                                        .generalColumn[j]))
                                                      InkWell(
                                                        onTap: () {
                                                          if (widget
                                                                  .onSequenceClicked !=
                                                              null) {
                                                            widget.onSequenceClicked!(
                                                                '${widget.generalColumnData[i][j] ?? ''}');
                                                          }
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8),
                                                          width: 150,
                                                          height: getBoxHeight(
                                                              widget
                                                                  .filterColumnData,
                                                              i,
                                                              widget
                                                                  .generalColumnData),
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          decoration:
                                                              BoxDecoration(
                                                            border: seperatingLength(
                                                                    i)
                                                                ? const Border(
                                                                    bottom: BorderSide(
                                                                        width:
                                                                            1))
                                                                : null,
                                                          ),
                                                          child: Tooltip(
                                                            message:
                                                                'Click to view Sensor Graph',
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Flexible(
                                                                  child: Text(
                                                                    '${widget.generalColumnData[i][j] ?? '-'}',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                    maxLines: 3,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 4),
                                                                InkWell(
                                                                  onTap: () {
                                                                    if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                                  },
                                                                  child: const Icon(
                                                                      Icons
                                                                          .analytics_outlined,
                                                                      size: 14,
                                                                      color: Colors
                                                                          .blue),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    else if ([
                                                      'Actual Start Time',
                                                      'Actual End Time'
                                                    ].contains(widget
                                                        .generalColumn[j]))
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 8),
                                                        width: 200,
                                                        height: getBoxHeight(
                                                            widget
                                                                .filterColumnData,
                                                            i,
                                                            widget
                                                                .generalColumnData),
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: seperatingLength(
                                                                  i)
                                                              ? const Border(
                                                                  bottom:
                                                                      BorderSide(
                                                                          width:
                                                                              1))
                                                              : null,
                                                        ),
                                                        child: Tooltip(
                                                          message:
                                                              '${widget.generalColumnData[i][j] ?? '-'}',
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Flexible(
                                                                child: Text(
                                                                  '${widget.generalColumnData[i][j] ?? '-'}',
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: Color(
                                                                          0xff03464F)),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              InkWell(
                                                                onTap: () {
                                                                  if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                                },
                                                                child: const Icon(
                                                                    Icons
                                                                        .analytics_outlined,
                                                                    size: 14,
                                                                    color: Colors
                                                                        .blue),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                    else if ([
                                                      'Actual Start Reason',
                                                      'Actual Stop Reason'
                                                    ].contains(widget.generalColumn[j]))
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 8),
                                                        width: 200,
                                                        height: getBoxHeight(
                                                            widget
                                                                .filterColumnData,
                                                            i,
                                                            widget
                                                                .generalColumnData),
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: seperatingLength(
                                                                  i)
                                                              ? const Border(
                                                                  bottom:
                                                                      BorderSide(
                                                                          width:
                                                                              1))
                                                              : null,
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                                child: reasonCell(
                                                                    '${widget.generalColumnData[i][j] ?? '-'}',
                                                                    getBoxHeight(
                                                                        widget
                                                                            .filterColumnData,
                                                                        i,
                                                                        widget
                                                                            .generalColumnData))),
                                                            const SizedBox(
                                                                width: 4),
                                                            InkWell(
                                                              onTap: () {
                                                                if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                              },
                                                              child: const Icon(
                                                                  Icons
                                                                      .analytics_outlined,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .blue),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    else if (widget.generalColumn[j] == 'Sequence' || widget.generalColumn[j] == 'SequenceData' || widget.generalColumn[j] == 'Valve' || widget.generalColumn[j] == 'Valves')
                                                      InkWell(
                                                        onTap: () {
                                                          if (widget
                                                                  .onSequenceClicked !=
                                                              null) {
                                                            widget.onSequenceClicked!(
                                                                '${widget.generalColumnData[i][j] ?? ''}');
                                                          }
                                                        },
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            border: seperatingLength(
                                                                    i)
                                                                ? const Border(
                                                                    bottom: BorderSide(
                                                                        width:
                                                                            1))
                                                                : null,
                                                          ),
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8),
                                                          width: 100,
                                                          height: getBoxHeight(
                                                              widget
                                                                  .filterColumnData,
                                                              i,
                                                              widget
                                                                  .generalColumnData),
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          child: Tooltip(
                                                            message:
                                                                'Click to view Sensor Graph',
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Flexible(
                                                                  child: Text(
                                                                    '${widget.generalColumnData[i][j] ?? '-'}',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 4),
                                                                InkWell(
                                                                  onTap: () {
                                                                    if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                                  },
                                                                  child: const Icon(
                                                                      Icons
                                                                          .analytics_outlined,
                                                                      size: 14,
                                                                      color: Colors
                                                                          .blue),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          border: seperatingLength(
                                                                  i)
                                                              ? const Border(
                                                                  bottom:
                                                                      BorderSide(
                                                                          width:
                                                                              1))
                                                              : null,
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 8),
                                                        width: 100,
                                                        height: getBoxHeight(
                                                            widget
                                                                .filterColumnData,
                                                            i,
                                                            widget
                                                                .generalColumnData),
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Tooltip(
                                                          message:
                                                              '${widget.generalColumnData[i][j] ?? '-'}',
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Flexible(
                                                                child: Text(
                                                                  '${widget.generalColumnData[i][j] ?? '-'}',
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              InkWell(
                                                                onTap: () {
                                                                  if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                                },
                                                                child: const Icon(
                                                                    Icons
                                                                        .analytics_outlined,
                                                                    size: 14,
                                                                    color: Colors
                                                                        .blue),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                  SizedBox(
                                                    width: 0,
                                                    height: getBoxHeight(
                                                        widget.filterColumnData,
                                                        i,
                                                        widget
                                                            .generalColumnData),
                                                    child: CustomPaint(
                                                      painter:
                                                          VerticalDotBorder(),
                                                      size: const Size(0, 50),
                                                    ),
                                                  )
                                                ],
                                              ))
                                      ],
                                    ),
                                    //TODO : WATER DATA
                                    Column(
                                      children: [
                                        for (var i = 0;
                                            i < widget.waterColumnData.length;
                                            i++)
                                          _buildClickableRow(
                                              i,
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  for (var j = 0;
                                                      j <
                                                          widget
                                                              .waterColumnData[
                                                                  i]
                                                              .length;
                                                      j++)
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: seperatingLength(
                                                                i)
                                                            ? const Border(
                                                                bottom:
                                                                    BorderSide(
                                                                        width:
                                                                            1))
                                                            : null,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8),
                                                      width: 100,
                                                      height: getBoxHeight(
                                                          widget
                                                              .filterColumnData,
                                                          i,
                                                          widget
                                                              .generalColumnData),
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Tooltip(
                                                        message:
                                                            '${widget.waterColumnData[i][j] ?? '-'}',
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                '${widget.waterColumnData[i][j] ?? '-'}',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            InkWell(
                                                              onTap: () {
                                                                if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                              },
                                                              child: const Icon(
                                                                  Icons
                                                                      .analytics_outlined,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .blue),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  SizedBox(
                                                    width: 0,
                                                    height: getBoxHeight(
                                                        widget.filterColumnData,
                                                        i,
                                                        widget
                                                            .generalColumnData),
                                                    child: CustomPaint(
                                                      painter:
                                                          VerticalDotBorder(),
                                                      size: Size(0, 50),
                                                    ),
                                                  )
                                                ],
                                              ))
                                      ],
                                    ),
                                    //TODO : FILTER DATA
                                    Column(
                                      children: [
                                        for (var i = 0;
                                            i < widget.filterColumnData.length;
                                            i++)
                                          _buildClickableRow(
                                              i,
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  for (var j = 0;
                                                      j <
                                                          widget
                                                              .filterColumnData[
                                                                  i]
                                                              .length;
                                                      j++)
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: seperatingLength(
                                                                i)
                                                            ? Border(
                                                                bottom:
                                                                    BorderSide(
                                                                        width:
                                                                            1))
                                                            : null,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8),
                                                      width: 200,
                                                      height: getBoxHeight(
                                                          widget
                                                              .filterColumnData,
                                                          i,
                                                          widget
                                                              .generalColumnData),
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Tooltip(
                                                        message:
                                                            '${widget.filterColumnData[i][j] ?? '-'}',
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                '${widget.filterColumnData[i][j] ?? '-'}',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            InkWell(
                                                              onTap: () {
                                                                if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                              },
                                                              child: const Icon(
                                                                  Icons
                                                                      .analytics_outlined,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .blue),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  SizedBox(
                                                    width: 0,
                                                    height: getBoxHeight(
                                                        widget.filterColumnData,
                                                        i,
                                                        widget
                                                            .generalColumnData),
                                                    child: CustomPaint(
                                                      painter:
                                                          VerticalDotBorder(),
                                                      size: const Size(0, 50),
                                                    ),
                                                  )
                                                ],
                                              ))
                                      ],
                                    ),
                                    //TODO : PRE POST DATA
                                    Column(
                                      children: [
                                        for (var i = 0;
                                            i < widget.prePostColumnData.length;
                                            i++)
                                          _buildClickableRow(
                                              i,
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  for (var j = 0;
                                                      j <
                                                          widget
                                                              .prePostColumnData[
                                                                  i]
                                                              .length;
                                                      j++)
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: seperatingLength(
                                                                i)
                                                            ? const Border(
                                                                bottom:
                                                                    BorderSide(
                                                                        width:
                                                                            1))
                                                            : null,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8),
                                                      width: 100,
                                                      height: getBoxHeight(
                                                          widget
                                                              .filterColumnData,
                                                          i,
                                                          widget
                                                              .generalColumnData),
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Tooltip(
                                                        message:
                                                            '${widget.prePostColumnData[i][j] ?? '-'}',
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                '${widget.prePostColumnData[i][j] ?? '-'}',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            InkWell(
                                                              onTap: () {
                                                                if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                              },
                                                              child: const Icon(
                                                                  Icons
                                                                      .analytics_outlined,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .blue),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  SizedBox(
                                                    width: 0,
                                                    height: getBoxHeight(
                                                        widget.filterColumnData,
                                                        i,
                                                        widget
                                                            .generalColumnData),
                                                    child: CustomPaint(
                                                      painter:
                                                          VerticalDotBorder(),
                                                      size: Size(0, 50),
                                                    ),
                                                  )
                                                ],
                                              ))
                                      ],
                                    ),
                                    //TODO : CENTRAL ECPH DATA
                                    Column(
                                      children: [
                                        for (var i = 0;
                                            i <
                                                widget.centralEcPhColumnData
                                                    .length;
                                            i++)
                                          _buildClickableRow(
                                              i,
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  for (var j = 0;
                                                      j <
                                                          widget
                                                              .centralEcPhColumnData[
                                                                  i]
                                                              .length;
                                                      j++)
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: seperatingLength(
                                                                i)
                                                            ? Border(
                                                                bottom:
                                                                    BorderSide(
                                                                        width:
                                                                            1))
                                                            : null,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8),
                                                      width: 100,
                                                      height: getBoxHeight(
                                                          widget
                                                              .filterColumnData,
                                                          i,
                                                          widget
                                                              .generalColumnData),
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Tooltip(
                                                        message:
                                                            '${widget.centralEcPhColumnData[i][j] ?? '-'}',
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                '${widget.centralEcPhColumnData[i][j] ?? '-'}',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            InkWell(
                                                              onTap: () {
                                                                if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                              },
                                                              child: const Icon(
                                                                  Icons
                                                                      .analytics_outlined,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .blue),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  SizedBox(
                                                    width: 0,
                                                    height: getBoxHeight(
                                                        widget.filterColumnData,
                                                        i,
                                                        widget
                                                            .generalColumnData),
                                                    child: CustomPaint(
                                                      painter:
                                                          VerticalDotBorder(),
                                                      size: Size(0, 50),
                                                    ),
                                                  )
                                                ],
                                              ))
                                      ],
                                    ),
                                    //TODO : CENTRAL CHANNEL
                                    if (widget.centralChannel1Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.centralChannel1ColumnData),
                                    if (widget.centralChannel2Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.centralChannel2ColumnData),
                                    if (widget.centralChannel3Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.centralChannel3ColumnData),
                                    if (widget.centralChannel4Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.centralChannel4ColumnData),
                                    if (widget.centralChannel5Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.centralChannel5ColumnData),
                                    if (widget.centralChannel6Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.centralChannel6ColumnData),
                                    if (widget.centralChannel7Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.centralChannel7ColumnData),
                                    if (widget.centralChannel8Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.centralChannel8ColumnData),
                                    //TODO : LOCAL ECPH DATA
                                    Column(
                                      children: [
                                        for (var i = 0;
                                            i <
                                                widget
                                                    .localEcPhColumnData.length;
                                            i++)
                                          _buildClickableRow(
                                              i,
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  for (var j = 0;
                                                      j <
                                                          widget
                                                              .localEcPhColumnData[
                                                                  i]
                                                              .length;
                                                      j++)
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: seperatingLength(
                                                                i)
                                                            ? Border(
                                                                bottom:
                                                                    BorderSide(
                                                                        width:
                                                                            1))
                                                            : null,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8),
                                                      width: 100,
                                                      height: getBoxHeight(
                                                          widget
                                                              .filterColumnData,
                                                          i,
                                                          widget
                                                              .generalColumnData),
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Tooltip(
                                                        message:
                                                            '${widget.localEcPhColumnData[i][j] ?? '-'}',
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                '${widget.localEcPhColumnData[i][j] ?? '-'}',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            InkWell(
                                                              onTap: () {
                                                                if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                              },
                                                              child: const Icon(
                                                                  Icons
                                                                      .analytics_outlined,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .blue),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  SizedBox(
                                                    width: 0,
                                                    height: getBoxHeight(
                                                        widget.filterColumnData,
                                                        i,
                                                        widget
                                                            .generalColumnData),
                                                    child: CustomPaint(
                                                      painter:
                                                          VerticalDotBorder(),
                                                      size: Size(0, 50),
                                                    ),
                                                  )
                                                ],
                                              ))
                                      ],
                                    ),
                                    //TODO : LOCAL CHANNEL
                                    if (widget.localChannel1Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.localChannel1ColumnData),
                                    if (widget.localChannel2Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.localChannel2ColumnData),
                                    if (widget.localChannel3Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.localChannel3ColumnData),
                                    if (widget.localChannel4Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.localChannel4ColumnData),
                                    if (widget.localChannel5Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.localChannel5ColumnData),
                                    if (widget.localChannel6Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.localChannel6ColumnData),
                                    if (widget.localChannel7Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.localChannel7ColumnData),
                                    if (widget.localChannel8Column.isNotEmpty)
                                      getChannnelColumnDataWidget(
                                          columnDataList:
                                              widget.localChannel8ColumnData),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool seperatingLength(index) {
    bool val = false;
    if ((widget.fixedColumnData.length - 1) == index) {
      val = true;
    } else if (widget.fixedColumnData[index] !=
        widget.fixedColumnData[index + 1]) {
      val = true;
    }
    return val;
  }

  List<Widget> fixedNestedColumnWidget() {
    dynamic data = [];
    for (var i = 0; i < widget.fixedColumnData.length; i++) {
      var isFind = false;
      finding:
      for (var item in data) {
        if (item['name'] == widget.fixedColumnData[i]) {
          item['count'] += 1;
          item['height'] += getBoxHeight(
              widget.filterColumnData, i, widget.generalColumnData);
          isFind = true;
          break finding;
        }
      }
      if (!isFind) {
        var element = [];
        data.add({
          'name': widget.fixedColumnData[i],
          'count': 1,
          'height': getBoxHeight(
              widget.filterColumnData, i, widget.generalColumnData),
          // if(element.containsKey('totalTime'))
          //   'totalTime' : element['totalTime'],
        });
      }
    }
    print("widget.generalColumnData : ${widget.generalColumnData}");
    for (var d in data) {
      print(d);
      var element = widget.graphData.firstWhere(
        (element) => element['name'] == d['name'],
        orElse: () => {},
      );
      if (element.containsKey('totalTime')) {
        d['totalTime'] = element['totalTime'];
      }
    }
    List<Widget> myWidget = [];
    for (var d in data) {
      myWidget.add(Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 1)),
          color: Color(0xffDCF3DD),
        ),
        // padding: const EdgeInsets.only(left: 8),
        width: 100,
        height: d['height'],
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${d['name']}',
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
            if (d.containsKey('totalTime'))
              Text(
                '${d['totalTime']} H:M:S',
                style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
          ],
        ),
      ));
    }
    return myWidget;
  }

  Widget getChannnelColumnDataWidget({required List<dynamic> columnDataList}) {
    return Column(
      children: [
        for (var i = 0; i < columnDataList.length; i++)
          _buildClickableRow(
              i,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = 0; j < columnDataList[i].length; j++)
                    Container(
                      decoration: BoxDecoration(
                        border: seperatingLength(i)
                            ? Border(bottom: BorderSide(width: 1))
                            : null,
                      ),
                      padding: const EdgeInsets.only(left: 8),
                      width: 100,
                      height: getBoxHeight(
                          widget.filterColumnData, i, widget.generalColumnData),
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message: '${columnDataList[i][j] ?? '-'}',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '${columnDataList[i][j] ?? '-'}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                              },
                              child: const Icon(Icons.analytics_outlined,
                                  size: 14, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 0,
                    height: getBoxHeight(
                        widget.filterColumnData, i, widget.generalColumnData),
                    child: CustomPaint(
                      painter: VerticalDotBorder(),
                      size: Size(0, 50),
                    ),
                  )
                ],
              ))
      ],
    );
  }

  Widget getChannelColumnWidget(
      {required List<dynamic> columnList,
      required int channelNo,
      required bool central}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Center(
          child: Text(
            '<${central ? 'C' : 'L'}-CH$channelNo>',
            style: TextStyle(color: Colors.white),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columnList.length; i++)
              if (columnList[i] != 'Name')
                Container(
                  // color: Color(0xffEAEAEA),
                  color: Colors.orange.shade200,
                  padding: const EdgeInsets.only(left: 8),
                  width: 100,
                  height: 50,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${columnList[i]}',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

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
/// separated by '\n') as a compact, color-coded, icon-led list so the
/// start/stop reason is easy to scan at a glance instead of a wall of
/// plain black text.
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(reasonIcon(line), size: 13, color: reasonColor(line)),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: Text(
                      line,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: reasonColor(line)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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

  return (50 + ((maxLines - 1) * 15)).toDouble();
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

// Widget buildPumpCtCard(String rawValue) {
//   List<String>? values = parsePumpCtData(rawValue);
//   if (values == null) {
//     return const Center(
//       child: Text(
//         '-',
//         style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black54),
//       ),
//     );
//   }
//
//   final rVal = values[0];
//   final yVal = values[1];
//   final bVal = values[2];
//
//   return Tooltip(
//     message: 'Red: $rVal | Yellow: $yVal | Blue: $bVal',
//     child: Card(
//       elevation: 1,
//       margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//         side: BorderSide(color: Colors.grey.shade300, width: 0.8),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             _buildCtPhaseItem(
//               label: 'R',
//               value: rVal,
//               color: const Color(0xFFE53935), // Red
//               bgColor: const Color(0xFFFFEBEE),
//               borderColor: const Color(0xFFFFCDD2),
//             ),
//             _buildCtPhaseItem(
//               label: 'Y',
//               value: yVal,
//               color: const Color(0xFFF57F17), // Yellow/Amber
//               bgColor: const Color(0xFFFFFDE7),
//               borderColor: const Color(0xFFFFF9C4),
//             ),
//             _buildCtPhaseItem(
//               label: 'B',
//               value: bVal,
//               color: const Color(0xFF1E88E5), // Blue
//               bgColor: const Color(0xFFE3F2FD),
//               borderColor: const Color(0xFFBBDEFB),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }
//
// Widget _buildCtPhaseItem({
//   required String label,
//   required String value,
//   required Color color,
//   required Color bgColor,
//   required Color borderColor,
// }) {
//   return Container(
//     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//     decoration: BoxDecoration(
//       color: bgColor,
//       borderRadius: BorderRadius.circular(5),
//       border: Border.all(color: borderColor, width: 0.8),
//     ),
//     child: Row(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Container(
//           width: 14,
//           height: 14,
//           decoration: BoxDecoration(
//             color: color,
//             shape: BoxShape.circle,
//           ),
//           alignment: Alignment.center,
//           child: Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 8.5,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         const SizedBox(width: 3),
//         Text(
//           value,
//           style: TextStyle(
//             color: color,
//             fontSize: 11,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     ),
//   );
// }
