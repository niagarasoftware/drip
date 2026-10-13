import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_date_range_picker/flutter_date_range_picker.dart';
import 'package:intl/intl.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:oro_drip_irrigation/Widgets/custom_buttons.dart';
import 'package:oro_drip_irrigation/modules/irrigation_report/view/scrollingTable.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../repository/irrigation_repository.dart';
import 'log_home.dart';
import 'package:excel/excel.dart' hide Border;

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens (same palette as the new ScrollingTable)
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

const double _kBannerHeight = 40;
const double _kHeaderHeight = 48;
const double _kGroupHeight = 42;
const double _kRowHeight = 64;

/// A block of consecutive rows that share the same date.
class _DateGroup {
  final String key;
  final int start;
  final int end;
  const _DateGroup({required this.key, required this.start, required this.end});
  int get count => end - start;
}

/// Pinned (sticky) date header.
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

class StandaloneLog extends StatefulWidget {
  final Map<String, dynamic> userData;
  const StandaloneLog({super.key, required this.userData});

  @override
  State<StandaloneLog> createState() => _StandaloneLogState();
}

class _StandaloneLogState extends State<StandaloneLog> {
  late LinkedScrollControllerGroup _scrollable1;
  late ScrollController _verticalScroll1;
  late ScrollController _verticalScroll2;
  late LinkedScrollControllerGroup _scrollable2;
  late ScrollController _horizontalScroll1;
  late ScrollController _horizontalScroll2;
  List<String> standaloneColumn = ['Program','Method','Start Time','Zone Name','Device Id','Others'];
  String _selectedDate = '';
  DateRange? selectedDateRange;
  DateRange? lastSelectedDateRange;
  List<dynamic> parameters = [
    'Date','ProgramCategory','SequenceData','ScheduledStartTime','S_No','ZoneName','IrrigationMethod','MacAddress'
  ];
  dynamic standaloneData = {
    'fixedColumnData' : [],
    'standaloneColumnData' : []
  };
  List<dynamic> configObject = [];
  int httpError = 0;
  int noOfRowsPerPage = 20;
  int totalPages = 0;
  int selectedPages = 1;
  String _range = '';
  String _rangeCount = '';
  String _dateCount = '';

  @override
  void initState() {
    _scrollable1 = LinkedScrollControllerGroup();
    _verticalScroll1 = _scrollable1.addAndGet();
    _verticalScroll2 = _scrollable1.addAndGet();
    _scrollable2 = LinkedScrollControllerGroup();
    _horizontalScroll1 = _scrollable2.addAndGet();
    _horizontalScroll2 = _scrollable2.addAndGet();
    getUserName();
    getStandaloneData();

    super.initState();
  }
  String _formatNumber(int number) {
    // Add leading zero if the number is less than 10
    return number.toString().padLeft(2, '0');
  }


  void getUserName()async{
    try{
      var body = {
        "userId": widget.userData['customerId'],
        "controllerId": widget.userData['controllerId'],
      };
      var response = await IrrigationRepository().getUserNames(body);
      Map<String, dynamic> configData = jsonDecode(response.body);
      print("jsonData : ${configData}");
      configObject = configData['data']['configObject'];

    }catch(e,stackTrace){
      print('error in name = > ${e.toString()}');
      print('error in name stackTrace= > $stackTrace');
    }
  }

  void getStandaloneData()async{
    print('data request to the server.............');
    setState(() {
      standaloneData['fixedColumnData'] = [];
      standaloneData['standaloneColumnData'] = [];
    });
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy').format(now);
    _selectedDate = _selectedDate == '' ? '$formattedDate - $formattedDate' : _selectedDate;
    String dateString1 = _selectedDate.split(' - ')[0];
    String dateString2 = _selectedDate.split(' - ')[1];

    List<String> parts1 = dateString1.split('/');
    List<String> parts2 = dateString2.split('/');

    // Create DateTime objects
    DateTime date1 = DateTime(int.parse(parts1[2]), int.parse(parts1[1]), int.parse(parts1[0]));
    DateTime date2 = DateTime(int.parse(parts2[2]), int.parse(parts2[1]), int.parse(parts2[0]));

    // Format DateTime objects into desired format
    String formattedDate1 = "${date1.year}-${_formatNumber(date1.month)}-${_formatNumber(date1.day)}";
    String formattedDate2 = "${date2.year}-${_formatNumber(date2.month)}-${_formatNumber(date2.day)}";
    try{
      String? startMonth = selectedDateRange?.start.month.toString();
      print('startMonth : $startMonth');

      String? startday = selectedDateRange?.start.day.toString();
      String? endMonth = selectedDateRange?.end.month.toString();
      String? endday = selectedDateRange?.end.day.toString();
      var body = {
        "userId": widget.userData['customerId'],
        "controllerId": widget.userData['controllerId'],
        "logType" : "Standalone",
        "fromDate" : formattedDate1,
        "toDate" : formattedDate2,
        "parameters" : parameters,
      };
      var response = await IrrigationRepository().getLogDateWise(body);
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      // standaloneData = jsonData['data'];
      setState(() {
        print('jsonData : $jsonData');
        var standaloneDataFromHttp = jsonData['data']['log'];
        for(var date = 0;date < standaloneDataFromHttp.length;date++){
          for(var schedule = 0;schedule < standaloneDataFromHttp[date]['standalone']['Date'].length;schedule++){
            standaloneData['fixedColumnData'].add(standaloneDataFromHttp[date]['standalone']['Date'][schedule]);
            var list = [];
            list.add(standaloneDataFromHttp[date]['standalone']['ProgramCategory'][schedule]);
            var method = standaloneDataFromHttp[date]['standalone']['IrrigationMethod'][schedule];
            list.add(method == 1 ? 'Time' : method == 2 ? 'Flow' : 'TimeLess');
            list.add(standaloneDataFromHttp[date]['standalone']['ScheduledStartTime'][schedule]);
            list.add(standaloneDataFromHttp[date]['standalone']['ZoneName'][schedule]);
            list.add(standaloneDataFromHttp[date]['standalone']['MacAddress'][schedule]);
            var valveName = '';
            for(var valve in standaloneDataFromHttp[date]['standalone']['SequenceData'][schedule].split('_')){
              valveName += valveName.isNotEmpty ? '__' : '';
              var objectData = configObject.firstWhere(
                    (element) => element['sNo'].toString() == valve,
                orElse: () => null,
              );
              valveName += '${objectData != null ? objectData['name'] : valve}';
            }
            list.add(valveName);
            standaloneData['standaloneColumnData'].add(list);
          }
        }
      });
      setState(() {
        httpError = 0;
      });
      setState(() {
        totalPages = (standaloneData['fixedColumnData'].length ~/ noOfRowsPerPage);
        if ((totalPages * noOfRowsPerPage) < standaloneData['fixedColumnData'].length) {
          totalPages += 1;
        }
        selectedPages = 1;
      });
    }catch(e,stackTrace){
      setState(() {
        httpError = 1;
      });
      print('error in log = > ${e.toString()}');
      print('error in log stackTrace= > $stackTrace');
    }
  }

  // ───────────────────────────── UI ─────────────────────────────

  /// Width of each standalone column (index follows [standaloneColumn]).
  double _colWidth(int j) {
    switch (j) {
      case 0:
        return 140; // Program
      case 1:
        return 120; // Method
      case 2:
        return 140; // Start Time
      case 3:
        return 160; // Zone Name
      case 4:
        return 180; // Device Id
      default:
        return 500; // Others
    }
  }

  double get _contentWidth {
    double w = 0;
    for (var j = 0; j < standaloneColumn.length; j++) {
      w += _colWidth(j);
    }
    return w;
  }

  /// Consecutive rows with the same date.
  List<_DateGroup> _buildGroups(List<dynamic> dates) {
    final groups = <_DateGroup>[];
    var i = 0;
    while (i < dates.length) {
      final key = '${dates[i]}';
      var end = i;
      while (end < dates.length && '${dates[end]}' == key) {
        end++;
      }
      groups.add(_DateGroup(key: key, start: i, end: end));
      i = end;
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 600;
    final pad = compact ? 8.0 : 12.0;
    final pageDates = filterDataByPages(data: standaloneData['fixedColumnData']);
    final pageRows = filterDataByPages(data: standaloneData['standaloneColumnData']);
    final groups = _buildGroups(pageDates);

    return Material(
      color: _kPageBg,
      child: Container(
        color: _kPageBg,
        padding: EdgeInsets.fromLTRB(pad, 10, pad, pad),
        child: Column(
          children: [
            Expanded(child: _buildMainCard(groups, pageRows, compact)),
            const SizedBox(height: 10),
            _buildFooter(compact),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── main card ───────────────────────────

  Widget _buildMainCard(List<_DateGroup> groups, List<dynamic> pageRows, bool compact) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // banner + column header (follows horizontal scroll)
          LayoutBuilder(
            builder: (context, c) {
              final w = _contentWidth > c.maxWidth ? _contentWidth : c.maxWidth;
              return SizedBox(
                width: c.maxWidth,
                height: _kBannerHeight + _kHeaderHeight,
                child: SingleChildScrollView(
                  controller: _horizontalScroll1,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: _buildHeader(w),
                ),
              );
            },
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                if (httpError == 1) {
                  return _messageState(Icons.error_outline, 'Unable to load the log. Please try again.');
                }
                if (pageRows.isEmpty) {
                  return _messageState(Icons.inbox_outlined, 'No standalone log found for the selected date.');
                }
                final w = _contentWidth > c.maxWidth ? _contentWidth : c.maxWidth;
                return Scrollbar(
                  controller: _horizontalScroll2,
                  thumbVisibility: !compact,
                  child: SingleChildScrollView(
                    controller: _horizontalScroll2,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: w,
                      child: CustomScrollView(
                        controller: _verticalScroll2,
                        slivers: [
                          for (final g in groups)
                            SliverMainAxisGroup(
                              slivers: [
                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: _GroupHeaderDelegate(
                                    height: _kGroupHeight,
                                    child: _groupHeader(g),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      for (var i = g.start; i < g.end; i++)
                                        _dataRow(pageRows[i]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
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

  Widget _messageState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: _kMutedText),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: _kHeaderText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double width) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            height: _kBannerHeight,
            color: _kBannerBg,
            alignment: Alignment.centerLeft,
            child: AnimatedBuilder(
              animation: _horizontalScroll1,
              builder: (context, _) {
                final off = _horizontalScroll1.hasClients ? _horizontalScroll1.offset : 0.0;
                final maxDx = width > 140 ? width - 140 : 0.0;
                final dx = off.clamp(0.0, maxDx).toDouble();
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      'Standalone',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kTeal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: _kHeaderHeight,
            color: _kHeaderBg,
            child: Row(
              children: [
                for (var j = 0; j < standaloneColumn.length; j++)
                  Container(
                    width: _colWidth(j),
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      standaloneColumn[j],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kHeaderText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Date header – the text follows the horizontal scroll so it always stays
  /// visible at the left edge.
  Widget _groupHeader(_DateGroup g) {
    return Container(
      color: _kGroupBg,
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _horizontalScroll2,
        builder: (context, _) {
          final dx = _horizontalScroll2.hasClients ? _horizontalScroll2.offset : 0.0;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    g.key,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kTeal,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Text(
                    '${g.count} ${g.count == 1 ? 'schedule' : 'schedules'}',
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12.5, color: _kHeaderText),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dataRow(dynamic row) {
    final List cells = row is List ? row : const [];
    return Container(
      height: _kRowHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kLine)),
      ),
      child: Row(
        children: [
          for (var j = 0; j < cells.length; j++)
            Container(
              width: _colWidth(j),
              padding: const EdgeInsets.only(left: 16, right: 8),
              alignment: Alignment.centerLeft,
              child: j == 1 ? _methodChip(cells[j]) : _textValue(cells[j], bold: j == 0),
            ),
        ],
      ),
    );
  }

  bool _isBlank(String text) {
    final t = text.trim();
    return t.isEmpty || t == '-';
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
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: _kBodyText,
        ),
      ),
    );
  }

  Widget _methodChip(dynamic raw) {
    final label = raw == null ? '' : '$raw';
    if (_isBlank(label)) return _textValue(raw);

    Color bg;
    Color fg;
    Color dot;
    switch (label) {
      case 'Time':
        bg = const Color(0xffDDEBF7);
        fg = const Color(0xff1565C0);
        dot = const Color(0xff1E88E5);
        break;
      case 'Flow':
        bg = const Color(0xffDDF3E4);
        fg = const Color(0xff1E7A3C);
        dot = const Color(0xff2E9E4F);
        break;
      default:
        bg = const Color(0xffE4EBEF);
        fg = const Color(0xff3D4E56);
        dot = const Color(0xff55666E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
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
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── footer ───────────────────────────

  Widget _pagerButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: _kBannerBg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 20, color: _kTeal),
        ),
      ),
    );
  }

  Widget _buildFooter(bool compact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffDCE5E7)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        spacing: 12,
        children: [
          // pagination
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pagerButton(Icons.keyboard_double_arrow_left, (){
                setState(() {
                  if(selectedPages != 1){
                    selectedPages -= 1  ;
                  }
                });
              }),
              if(standaloneData['fixedColumnData'] != null)
                Container(
                  constraints: const BoxConstraints(minWidth: 110),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '${
                        (selectedPages * noOfRowsPerPage) - 20} - ${((selectedPages * noOfRowsPerPage) < standaloneData['fixedColumnData'].length
                        ?  (selectedPages * noOfRowsPerPage)
                        : standaloneData['fixedColumnData'].length)} / ${standaloneData['fixedColumnData'].length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kBodyText,
                    ),
                  ),
                ),
              _pagerButton(Icons.keyboard_double_arrow_right, (){
                setState(() {
                  if(selectedPages != totalPages){
                    selectedPages += 1;
                  }
                });
              }),
            ],
          ),
          // date + download
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kTeal,
                  side: const BorderSide(color: _kSectionLine),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: const Text('Select Date'),
                onPressed: (){
                  showDialog(context: context, builder: (context){
                    return AlertDialog(
                      title: Text('Date Picker'),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter stateSetter) {
                          return SizedBox(
                            width: 200,
                            height: 250,
                            child:SfDateRangePicker(
                              onSelectionChanged:  _onSelectionChanged,
                              selectionMode: DateRangePickerSelectionMode.range,
                              initialSelectedRange: PickerDateRange(
                                  DateTime.now(),
                                  DateTime.now()
                              ),
                            ),
                          );
                        },
                      ),
                      actions: [
                        CustomMaterialButton(
                          title: 'Cancel',
                          outlined: true,
                        ),
                        CustomMaterialButton(
                          onPressed: (){
                            Navigator.pop(context);
                            getDialog(context);
                            getStandaloneData();
                            if(mounted){
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    );

                  });
                },
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download'),
                onPressed: (){
                  showDialog(
                      context: context,
                      builder: (context){
                        var fileName = 'file';
                        return AlertDialog(
                          title: Text('Give Name For Your File'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                initialValue: fileName,
                                onChanged: (value){
                                  fileName = value;
                                },
                                decoration: InputDecoration(
                                    border: OutlineInputBorder()
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: (){
                                  generateExcelForStandAlone(standaloneData,fileName);
                                  Navigator.pop(context);
                                },
                                child: Text('Click to download')
                            )
                          ],
                        );
                      }
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> generateExcelForStandAlone(Map<String, dynamic> data, String name) async {
    // Create a new workbook
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Logs'];
// final sheet = workbook.worksheets[0];
    // sheet.name = 'Logs';

    // Create header row
    List<String> headerRow = [
      'Date',
      ...standaloneColumn
    ];
    sheetObject.appendRow([for(var i in headerRow) TextCellValue(i)]);

    for (var i = 0; i < data['fixedColumnData'].length; i++) {
      List<String> eachRow = [data['fixedColumnData'][i]];
      List<String> columnDataKeys = [
        'standaloneColumnData',
      ];

      for (var columnData in columnDataKeys) {
        if (data[columnData][0] != null) {
          for (var j = 0; j < data[columnData][i].length; j++) {
            eachRow.add('${data[columnData][i][j]}');
          }
        }
      }

      for (int j = 0; j < eachRow.length; j++) {
        sheetObject.appendRow([for(var cell in eachRow) TextCellValue(cell)]);
      }
    }

    // Save the file
    var fileBytes = excel.encode();
    if (fileBytes != null) {
      try {
        String downloadsDirectoryPath = "/storage/emulated/0/Download";
        String filePath = "$downloadsDirectoryPath/$name.xlsx";
        File file = File(filePath);
        await file.create(recursive: true);
        await file.writeAsBytes(fileBytes);
        // Check if file exists
        if (await file.exists()) {
          showDialog(context: context, builder: (context){
            return AlertDialog(
              title: Text('$name Download Successfully at'),
              content: Text('$filePath'),
              actions: [
                TextButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    child: Text('Ok')
                )
              ],
            );
          });
          print("Excel file saved successfully at $filePath");
        } else {
          showDialog(context: context, builder: (context){
            return AlertDialog(
              title: Text('$name Download failed..'),
              actions: [
                TextButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    child: Text('Ok')
                )
              ],
            );
          });
          log("Failed to save the Excel file.");
        }
      } catch (e) {
        log("Error saving the Excel file: $e");
      }
    } else {
      log("Error encoding the Excel file.");
    }
  }

  List<dynamic> filterDataByPages({required data}){
    List<dynamic> slicingList = [];
    int from = (selectedPages * noOfRowsPerPage) - 20;
    int to = (selectedPages * noOfRowsPerPage);
    if(data.length < to){
      to = data.length;
    }
    for(var i = from;i < to;i++){
      slicingList.add(data[i]);
    }
    return slicingList;
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      if (args.value is PickerDateRange) {
        _selectedDate  = '${DateFormat('dd/MM/yyyy').format(args.value.startDate)} -'
            ' ${DateFormat('dd/MM/yyyy').format(args.value.endDate ?? args.value.startDate)}';

      } else if (args.value is DateTime) {
        _selectedDate = args.value.toString();
      } else if (args.value is List<DateTime>) {
        _dateCount = args.value.length.toString();
      } else {
        _rangeCount = args.value.length.toString();
      }
      print("range: ${_range},rangecount:${_rangeCount},Select date:${_selectedDate}");
    });
  }
}