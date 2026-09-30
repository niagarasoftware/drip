import 'package:data_table_2/data_table_2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:oro_drip_irrigation/Screens/planning/weather/weather_report_model.dart';
import 'package:oro_drip_irrigation/Screens/planning/weather/weather_report_sensor_modelGsm.dart';

import '../../../repository/repository.dart';
import '../../../services/http_service.dart';

enum ReportType {
  today,
  weekly,
  monthly,
}

class SensorDailyReport {
  final String date;

  // Kept internally only for average calculation.
  // Not shown in weekly/monthly UI.
  final double totalValue;

  final double minValue;
  final double maxValue;
  final double averageValue;
  final int validHours;

  const SensorDailyReport({
    required this.date,
    required this.totalValue,
    required this.minValue,
    required this.maxValue,
    required this.averageValue,
    required this.validHours,
  });
}

class SensorHourlyReportPage extends StatefulWidget {
  final String deviceSrNo;
  final String sensorSrNo;
  final String sensorName;
  final String userId;
  final String unit;
  final String controllerId;

  const SensorHourlyReportPage({
    super.key,
    required this.deviceSrNo,
    required this.sensorSrNo,
    required this.sensorName,
    required this.userId,
    required this.controllerId,
    required this.unit,
  });

  @override
  State<SensorHourlyReportPage> createState() =>
      _SensorHourlyReportPageState();
}

class _SensorHourlyReportPageState
    extends State<SensorHourlyReportPage> {
  final Repository repository = Repository(HttpService());

  ReportType selectedReportType = ReportType.today;

  DateTime selectedDate = DateTime.now();

  bool isLoading = false;
  bool isGraphView = true;

  List<SensorHourReportGsm> hourlyReport = [];
  List<SensorDailyReport> dailyReport = [];

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  // ============================================================
  // MAIN FETCH
  // ============================================================

  Future<void> fetchReport() async {
    switch (selectedReportType) {
      case ReportType.today:
        await fetchTodayReport();
        break;

      case ReportType.weekly:
        await fetchWeeklyReport();
        break;

      case ReportType.monthly:
        await fetchMonthlyReport();
        break;
    }
  }

  // ============================================================
  // TODAY REPORT
  // ============================================================

  Future<void> fetchTodayReport() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      hourlyReport = [];
      dailyReport = [];
    });

    try {
      final String date =
      DateFormat('yyyy-MM-dd').format(selectedDate);

      final response = await repository.getweatherReport({
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "fromDate": date,
        "toDate": date,
      });

      final WeatherReportModel model =
      weatherReportModelFromJson(
        response.body,
      );

      final List<SensorHourReportGsm> temp = [];

      for (final datum in model.data) {
        final Map<String, String> hours =
        _getHours(datum);

        for (final entry in hours.entries) {
          final String hour = entry.key;
          final String raw = entry.value;

          if (!_canUseHour(
            date: datum.date,
            hour: hour,
          )) {
            continue;
          }

          final SensorHourReportGsm? parsed =
          parseSensorHourData(
            raw: raw,
            hour: hour,
            deviceSrNo: widget.deviceSrNo,
            targetSensor: widget.sensorSrNo,
          );

          if (parsed != null) {
            temp.add(parsed);
          }
        }
      }

      temp.sort((a, b) {
        final int aHour =
            int.tryParse(
              a.hour.split(':').first,
            ) ??
                0;

        final int bHour =
            int.tryParse(
              b.hour.split(':').first,
            ) ??
                0;

        return aHour.compareTo(bHour);
      });

      if (!mounted) return;

      setState(() {
        hourlyReport = temp;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'Today report error: $e',
      );
      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _showError(
          'Unable to load today report',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // WEEKLY REPORT
  // LAST 7 DAYS INCLUDING SELECTED DATE
  // ============================================================

  Future<void> fetchWeeklyReport() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      hourlyReport = [];
      dailyReport = [];
    });

    try {
      DateTime endDate =
      _dateOnly(selectedDate);

      final DateTime today =
      _dateOnly(DateTime.now());

      // Never request future date.
      if (endDate.isAfter(today)) {
        endDate = today;
      }

      // Last 7 days including selected date.
      final DateTime startDate =
      endDate.subtract(
        const Duration(days: 6),
      );

      final String fromDate =
      DateFormat('yyyy-MM-dd').format(
        startDate,
      );

      final String toDate =
      DateFormat('yyyy-MM-dd').format(
        endDate,
      );

      debugPrint(
        'Weekly report: $fromDate -> $toDate',
      );

      final response =
      await repository.getweatherReport({
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "fromDate": fromDate,
        "toDate": toDate,
      });

      final WeatherReportModel model =
      weatherReportModelFromJson(
        response.body,
      );

      final List<SensorDailyReport> result =
      calculateDailyReport(
        model,
      );

      if (!mounted) return;

      setState(() {
        dailyReport = result;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'Weekly report error: $e',
      );
      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _showError(
          'Unable to load weekly report',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // MONTHLY REPORT
  // ============================================================
  Future<void> fetchMonthlyReport() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      hourlyReport = [];
      dailyReport = [];
    });

    try {
      DateTime endDate = _dateOnly(selectedDate);

      final DateTime today =
      _dateOnly(DateTime.now());

      // Do not allow future end date.
      if (endDate.isAfter(today)) {
        endDate = today;
      }

      // Last 30 days including selected date.
      //
      // Example:
      // selectedDate = 28-09-2026
      //
      // fromDate = 30-08-2026
      // toDate   = 28-09-2026
      final DateTime startDate =
      endDate.subtract(
        const Duration(days: 29),
      );

      final String fromDate =
      DateFormat('yyyy-MM-dd').format(
        startDate,
      );

      final String toDate =
      DateFormat('yyyy-MM-dd').format(
        endDate,
      );

      debugPrint(
        'Last 30 Days report: $fromDate -> $toDate',
      );

      final response =
      await repository.getweatherReport({
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "fromDate": fromDate,
        "toDate": toDate,
      });

      final WeatherReportModel model =
      weatherReportModelFromJson(
        response.body,
      );

      final List<SensorDailyReport> result =
      calculateDailyReport(
        model,
      );

      if (!mounted) return;

      setState(() {
        dailyReport = result;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'Last 30 Days report error: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _showError(
          'Unable to load last 30 days report',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  // Future<void> fetchMonthlyReport() async {
  //   if (!mounted) return;
  //
  //   setState(() {
  //     isLoading = true;
  //     hourlyReport = [];
  //     dailyReport = [];
  //   });
  //
  //   try {
  //     final DateTime firstDay = DateTime(
  //       selectedDate.year,
  //       selectedDate.month,
  //       1,
  //     );
  //
  //     DateTime lastDay = DateTime(
  //       selectedDate.year,
  //       selectedDate.month + 1,
  //       0,
  //     );
  //
  //     final DateTime today =
  //     _dateOnly(DateTime.now());
  //
  //     // Current month -> stop at today.
  //     if (firstDay.year == today.year &&
  //         firstDay.month == today.month) {
  //       lastDay = today;
  //     }
  //
  //     final String fromDate =
  //     DateFormat('yyyy-MM-dd').format(
  //       firstDay,
  //     );
  //
  //     final String toDate =
  //     DateFormat('yyyy-MM-dd').format(
  //       lastDay,
  //     );
  //
  //     debugPrint(
  //       'Monthly report: $fromDate -> $toDate',
  //     );
  //
  //     final response =
  //     await repository.getweatherReport({
  //       "userId": widget.userId,
  //       "controllerId": widget.controllerId,
  //       "fromDate": fromDate,
  //       "toDate": toDate,
  //     });
  //
  //     final WeatherReportModel model =
  //     weatherReportModelFromJson(
  //       response.body,
  //     );
  //
  //     final List<SensorDailyReport> result =
  //     calculateDailyReport(
  //       model,
  //     );
  //
  //     if (!mounted) return;
  //
  //     setState(() {
  //       dailyReport = result;
  //     });
  //   } catch (e, stackTrace) {
  //     debugPrint(
  //       'Monthly report error: $e',
  //     );
  //     debugPrint(
  //       '$stackTrace',
  //     );
  //
  //     if (mounted) {
  //       _showError(
  //         'Unable to load monthly report',
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         isLoading = false;
  //       });
  //     }
  //   }
  // }

  // ============================================================
  // DAILY CALCULATION
  // ============================================================

  List<SensorDailyReport> calculateDailyReport(
      WeatherReportModel model,
      ) {
    final List<SensorDailyReport> result = [];

    for (final datum in model.data) {
      final Map<String, String> hours =
      _getHours(datum);

      final List<double> validValues = [];

      for (final entry in hours.entries) {
        final String hour = entry.key;
        final String raw = entry.value;

        // Today -> do not include future hours.
        if (!_canUseHour(
          date: datum.date,
          hour: hour,
        )) {
          continue;
        }

        // Empty API hour is not valid.
        if (raw.trim().isEmpty) {
          continue;
        }

        final SensorHourReportGsm? parsed =
        parseSensorHourData(
          raw: raw,
          hour: hour,
          deviceSrNo: widget.deviceSrNo,
          targetSensor: widget.sensorSrNo,
        );

        if (parsed == null) {
          continue;
        }

        if (parsed.value.trim().isEmpty ||
            parsed.value == 'NA') {
          continue;
        }

        final double? value =
        double.tryParse(
          parsed.value,
        );

        if (value == null) {
          continue;
        }

        validValues.add(value);
      }

      // No valid hour.
      if (validValues.isEmpty) {
        result.add(
          SensorDailyReport(
            date: datum.date,
            totalValue: 0,
            minValue: 0,
            maxValue: 0,
            averageValue: 0,
            validHours: 0,
          ),
        );

        continue;
      }

      // ========================================================
      // TOTAL - INTERNAL ONLY
      // ========================================================

      double total = 0;

      for (final value in validValues) {
        total += value;
      }

      // ========================================================
      // VALID HOURS
      // ========================================================

      final int validHours =
          validValues.length;

      // ========================================================
      // AVERAGE
      //
      // 24 valid hours -> total / 24
      // 17 valid hours -> total / 17
      // ========================================================

      final double averageValue =
      validHours > 0
          ? total / validHours
          : 0;

      // ========================================================
      // MIN
      // ========================================================

      final double minValue =
      validValues.reduce(
            (a, b) => a < b ? a : b,
      );

      // ========================================================
      // MAX
      // ========================================================

      final double maxValue =
      validValues.reduce(
            (a, b) => a > b ? a : b,
      );

      result.add(
        SensorDailyReport(
          date: datum.date,
          totalValue: total,
          minValue: minValue,
          maxValue: maxValue,
          averageValue: averageValue,
          validHours: validHours,
        ),
      );
    }

    result.sort(
          (a, b) => a.date.compareTo(b.date),
    );

    return result;
  }

  // ============================================================
  // ALL HOURS
  // ============================================================

  Map<String, String> _getHours(
      Datum datum,
      ) {
    return {
      "00:00": datum.the0000,
      "01:00": datum.the0100,
      "02:00": datum.the0200,
      "03:00": datum.the0300,
      "04:00": datum.the0400,
      "05:00": datum.the0500,
      "06:00": datum.the0600,
      "07:00": datum.the0700,
      "08:00": datum.the0800,
      "09:00": datum.the0900,
      "10:00": datum.the1000,
      "11:00": datum.the1100,
      "12:00": datum.the1200,
      "13:00": datum.the1300,
      "14:00": datum.the1400,
      "15:00": datum.the1500,
      "16:00": datum.the1600,
      "17:00": datum.the1700,
      "18:00": datum.the1800,
      "19:00": datum.the1900,
      "20:00": datum.the2000,
      "21:00": datum.the2100,
      "22:00": datum.the2200,
      "23:00": datum.the2300,
    };
  }

  // ============================================================
  // HOUR VALIDATION
  // ============================================================

  bool _canUseHour({
    required String date,
    required String hour,
  }) {
    final DateTime now = DateTime.now();

    DateTime reportDate;

    try {
      reportDate =
          DateFormat(
            'yyyy-MM-dd',
          ).parse(
            date,
          );
    } catch (_) {
      return true;
    }

    final DateTime today =
    _dateOnly(now);

    final DateTime currentDate =
    _dateOnly(reportDate);

    // Previous date -> all available hours allowed.
    if (currentDate.isBefore(today)) {
      return true;
    }

    // Future date -> reject.
    if (currentDate.isAfter(today)) {
      return false;
    }

    // Today -> only current hour and earlier.
    final int reportHour =
        int.tryParse(
          hour.split(':').first,
        ) ??
            0;

    return reportHour <= now.hour;
  }

  DateTime _dateOnly(
      DateTime date,
      ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  // ============================================================
  // CHANGE REPORT TYPE
  // ============================================================

  Future<void> changeReportType(
      ReportType type,
      ) async {
    if (selectedReportType == type) {
      return;
    }

    setState(() {
      selectedReportType = type;
    });

    await fetchReport();
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> selectDate() async {
    final DateTime? picked =
    await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDate = picked;
    });

    await fetchReport();
  }

  // ============================================================
  // HEADER DATE
  // ============================================================

  String _getHeaderDate() {
    switch (selectedReportType) {
      case ReportType.today:
        return DateFormat(
          'dd MMM yyyy',
        ).format(
          selectedDate,
        );

      case ReportType.weekly:
        DateTime endDate =
        _dateOnly(selectedDate);

        final DateTime today =
        _dateOnly(DateTime.now());

        if (endDate.isAfter(today)) {
          endDate = today;
        }

        final DateTime startDate =
        endDate.subtract(
          const Duration(days: 6),
        );

        return '${DateFormat('dd MMM').format(startDate)}'
            ' - '
            '${DateFormat('dd MMM yyyy').format(endDate)}';

      case ReportType.monthly:
        DateTime endDate =
        _dateOnly(selectedDate);

        final DateTime today =
        _dateOnly(DateTime.now());

        if (endDate.isAfter(today)) {
          endDate = today;
        }

        final DateTime startDate =
        endDate.subtract(
          const Duration(days: 29),
        );

        return '${DateFormat('dd MMM').format(startDate)}'
            ' - '
            '${DateFormat('dd MMM yyyy').format(endDate)}';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.sensorName} Report',
            ),
            Text(
              _getHeaderDate(),
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: isGraphView
                ? 'Table View'
                : 'Graph View',
            icon: Icon(
              isGraphView
                  ? Icons.table_chart
                  : Icons.show_chart,
            ),
            onPressed: () {
              setState(() {
                isGraphView =
                !isGraphView;
              });
            },
          ),

          IconButton(
            icon: const Icon(
              Icons.calendar_today,
            ),
            onPressed: selectDate,
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          _buildReportSelector(),

          _buildDateCard(),

          Expanded(
            child: isLoading
                ? const Center(
              child:
              CircularProgressIndicator(),
            )
                : isGraphView
                ? _buildGraph()
                : selectedReportType ==
                ReportType.today
                ? _buildHourlyTable()
                : _buildDailyTable(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TODAY / WEEKLY / MONTHLY BUTTONS
  // ============================================================

  Widget _buildReportSelector() {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        4,
      ),
      child: Row(
        children: [
          Expanded(
            child: _reportButton(
              'Today',
              ReportType.today,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _reportButton(
              'Weekly',
              ReportType.weekly,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _reportButton(
              'Monthly',
              ReportType.monthly,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportButton(
      String title,
      ReportType type,
      ) {
    final bool selected =
        selectedReportType == type;

    return ElevatedButton(
      onPressed: () {
        changeReportType(type);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selected
            ? Colors.teal
            : Colors.grey.shade100,
        foregroundColor: selected
            ? Colors.white
            : Colors.black87,
        elevation: selected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(8),
          side: BorderSide(
            color: selected
                ? Colors.teal
                : Colors.grey.shade300,
          ),
        ),
      ),
      child: Text(title),
    );
  }

  // ============================================================
  // DATE CARD
  // ============================================================

  Widget _buildDateCard() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: InkWell(
        onTap: selectDate,
        borderRadius:
        BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(8),
            border: Border.all(
              color:
              Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month,
                size: 20,
                color: Colors.teal,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  _getHeaderDate(),
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),

              const Icon(
                Icons.arrow_drop_down,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GRAPH
  // ============================================================

  Widget _buildGraph() {
    if (selectedReportType ==
        ReportType.today) {
      return _buildTodayLineGraph();
    }

    return _buildDailyLineGraph();
  }

  // ============================================================
  // TODAY LINE GRAPH
  // ============================================================

  Widget _buildTodayLineGraph() {
    final List<SensorHourReportGsm> valid =
    hourlyReport.where(
          (item) {
        if (item.value == 'NA' ||
            item.value.trim().isEmpty) {
          return false;
        }

        return double.tryParse(
          item.value,
        ) !=
            null;
      },
    ).toList();

    valid.sort((a, b) {
      final int aHour =
          int.tryParse(
            a.hour.split(':').first,
          ) ??
              0;

      final int bHour =
          int.tryParse(
            b.hour.split(':').first,
          ) ??
              0;

      return aHour.compareTo(bHour);
    });

    final List<FlSpot> spots = [];

    for (final item in valid) {
      final int hour =
          int.tryParse(
            item.hour.split(':').first,
          ) ??
              0;

      final double? value =
      double.tryParse(
        item.value,
      );

      if (value == null) {
        continue;
      }

      spots.add(
        FlSpot(
          hour.toDouble(),
          value,
        ),
      );
    }

    if (spots.isEmpty) {
      return const Center(
        child: Text(
          'No graph data available',
        ),
      );
    }

    final List<double> values =
    spots.map(
          (spot) => spot.y,
    ).toList();

    final double actualMin =
    values.reduce(
          (a, b) => a < b ? a : b,
    );

    final double actualMax =
    values.reduce(
          (a, b) => a > b ? a : b,
    );

    final Map<String, double> limits =
    _calculateYLimits(
      actualMin,
      actualMax,
    );

    double maxX = 23;

    if (DateUtils.isSameDay(
      selectedDate,
      DateTime.now(),
    )) {
      maxX =
          DateTime.now().hour.toDouble();
    }

    return _graphCard(
      title: widget.sensorName,
      subTitle: DateFormat(
        'dd MMM yyyy',
      ).format(
        selectedDate,
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: limits['min']!,
          maxY: limits['max']!,

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),

          borderData:
          _graphBorder(),

          titlesData:
          FlTitlesData(
            rightTitles:
            const AxisTitles(
              sideTitles:
              SideTitles(
                showTitles: false,
              ),
            ),

            topTitles:
            const AxisTitles(
              sideTitles:
              SideTitles(
                showTitles: false,
              ),
            ),

            leftTitles:
            AxisTitles(
              axisNameWidget:
              Text(
                widget.unit,
              ),

              sideTitles:
              SideTitles(
                showTitles: true,
                reservedSize: 50,

                getTitlesWidget:
                    (
                    value,
                    meta,
                    ) {
                  return Text(
                    value.toStringAsFixed(
                      1,
                    ),
                    style:
                    const TextStyle(
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),

            bottomTitles:
            AxisTitles(
              axisNameWidget:
              const Text(
                'Hour',
              ),

              sideTitles:
              SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: 1,

                getTitlesWidget:
                    (
                    value,
                    meta,
                    ) {
                  if (value !=
                      value.toInt()) {
                    return const SizedBox
                        .shrink();
                  }

                  final int hour =
                  value.toInt();

                  if (hour < 0 ||
                      hour > maxX) {
                    return const SizedBox
                        .shrink();
                  }

                  if (hour % 3 != 0 &&
                      hour !=
                          maxX.toInt()) {
                    return const SizedBox
                        .shrink();
                  }

                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      top: 8,
                    ),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style:
                      const TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          lineTouchData:
          LineTouchData(
            touchTooltipData:
            LineTouchTooltipData(
              getTooltipItems:
                  (
                  touchedSpots,
                  ) {
                return touchedSpots
                    .map(
                      (spot) {
                    final String hour =
                    spot.x
                        .toInt()
                        .toString()
                        .padLeft(
                      2,
                      '0',
                    );

                    return LineTooltipItem(
                      '$hour:00\n'
                          '${spot.y.toStringAsFixed(2)} ${widget.unit}',
                      const TextStyle(
                        color:
                        Colors.white,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    );
                  },
                ).toList();
              },
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: Colors.teal,
              isStrokeCapRound: true,

              dotData: FlDotData(
                show: true,
                getDotPainter:
                    (
                    spot,
                    percent,
                    barData,
                    index,
                    ) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.teal,
                    strokeWidth: 2,
                    strokeColor:
                    Colors.white,
                  );
                },
              ),

              belowBarData:
              BarAreaData(
                show: true,
                gradient:
                LinearGradient(
                  colors: [
                    Colors.teal
                        .withOpacity(
                      0.25,
                    ),
                    Colors.teal
                        .withOpacity(
                      0.02,
                    ),
                  ],
                  begin:
                  Alignment.topCenter,
                  end:
                  Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WEEKLY / MONTHLY LINE GRAPH
  // ============================================================

  Widget _buildDailyLineGraph() {
    if (dailyReport.isEmpty) {
      return const Center(
        child: Text(
          'No graph data available',
        ),
      );
    }

    final List<SensorDailyReport> sorted =
    List<SensorDailyReport>.from(
      dailyReport,
    );

    sorted.sort(
          (a, b) =>
          a.date.compareTo(b.date),
    );

    final List<FlSpot> spots = [];

    for (int i = 0;
    i < sorted.length;
    i++) {
      final SensorDailyReport item =
      sorted[i];

      if (item.validHours == 0) {
        continue;
      }

      spots.add(
        FlSpot(
          i.toDouble(),
          item.averageValue,
        ),
      );
    }

    if (spots.isEmpty) {
      return const Center(
        child: Text(
          'No valid sensor data',
        ),
      );
    }

    final List<double> values =
    spots.map(
          (spot) => spot.y,
    ).toList();

    final double actualMin =
    values.reduce(
          (a, b) => a < b ? a : b,
    );

    final double actualMax =
    values.reduce(
          (a, b) => a > b ? a : b,
    );

    final Map<String, double> limits =
    _calculateYLimits(
      actualMin,
      actualMax,
    );

    final bool weekly =
        selectedReportType ==
            ReportType.weekly;

    return _graphCard(
      title: widget.sensorName,

      subTitle: weekly
          ? 'Weekly Average Trend'
          : 'Monthly Average Trend',

      child: LineChart(
        LineChartData(
          minX: 0,
          maxX:
          (sorted.length - 1)
              .toDouble(),

          minY: limits['min']!,
          maxY: limits['max']!,

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),

          borderData:
          _graphBorder(),

          titlesData:
          FlTitlesData(
            rightTitles:
            const AxisTitles(
              sideTitles:
              SideTitles(
                showTitles: false,
              ),
            ),

            topTitles:
            const AxisTitles(
              sideTitles:
              SideTitles(
                showTitles: false,
              ),
            ),

            leftTitles:
            AxisTitles(
              axisNameWidget:
              Text(
                widget.unit,
              ),

              sideTitles:
              SideTitles(
                showTitles: true,
                reservedSize: 50,

                getTitlesWidget:
                    (
                    value,
                    meta,
                    ) {
                  return Text(
                    value.toStringAsFixed(
                      1,
                    ),
                    style:
                    const TextStyle(
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),

            bottomTitles:
            AxisTitles(
              axisNameWidget:
              const Text(
                'Date',
              ),

              sideTitles:
              SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: 1,

                getTitlesWidget:
                    (
                    value,
                    meta,
                    ) {
                  if (value !=
                      value.toInt()) {
                    return const SizedBox
                        .shrink();
                  }

                  final int index =
                  value.toInt();

                  if (index < 0 ||
                      index >=
                          sorted.length) {
                    return const SizedBox
                        .shrink();
                  }

                  // Weekly -> show every date.
                  //
                  // Monthly -> show every 5th date
                  // + last date.
                  if (!weekly &&
                      index % 5 != 0 &&
                      index !=
                          sorted.length -
                              1) {
                    return const SizedBox
                        .shrink();
                  }

                  String label =
                      sorted[index].date;

                  try {
                    final DateTime date =
                    DateFormat(
                      'yyyy-MM-dd',
                    ).parse(
                      sorted[index].date,
                    );

                    label =
                        DateFormat(
                          'dd MMM',
                        ).format(
                          date,
                        );
                  } catch (_) {}

                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      top: 8,
                    ),
                    child: Text(
                      label,
                      style:
                      const TextStyle(
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          lineTouchData:
          LineTouchData(
            enabled: true,

            touchTooltipData:
            LineTouchTooltipData(
              getTooltipItems:
                  (
                  touchedSpots,
                  ) {
                return touchedSpots
                    .map(
                      (spot) {
                    final int index =
                    spot.x.round();

                    if (index < 0 ||
                        index >=
                            sorted.length) {
                      return null;
                    }

                    final SensorDailyReport
                    item =
                    sorted[index];

                    // TOTAL REMOVED
                    return LineTooltipItem(
                      '${_formatDate(item.date)}\n'
                          'Avg: ${item.averageValue.toStringAsFixed(2)} ${widget.unit}\n'
                          'Min: ${item.minValue.toStringAsFixed(2)} ${widget.unit}\n'
                          'Max: ${item.maxValue.toStringAsFixed(2)} ${widget.unit}',
                      const TextStyle(
                        color:
                        Colors.white,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    );
                  },
                ).toList();
              },
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.teal,
              barWidth: 3,
              isStrokeCapRound: true,

              dotData: FlDotData(
                show: true,

                getDotPainter:
                    (
                    spot,
                    percent,
                    barData,
                    index,
                    ) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.teal,
                    strokeWidth: 2,
                    strokeColor:
                    Colors.white,
                  );
                },
              ),

              belowBarData:
              BarAreaData(
                show: true,

                gradient:
                LinearGradient(
                  colors: [
                    Colors.teal
                        .withOpacity(
                      0.25,
                    ),
                    Colors.teal
                        .withOpacity(
                      0.02,
                    ),
                  ],
                  begin:
                  Alignment.topCenter,
                  end:
                  Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GRAPH CARD
  // ============================================================

  Widget _graphCard({
    required String title,
    required String subTitle,
    required Widget child,
  }) {
    return Padding(
      padding:
      const EdgeInsets.all(12),
      child: Card(
        elevation: 2,

        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),

        child: Padding(
          padding:
          const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          title,
                          style:
                          const TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          subTitle,
                          style:
                          const TextStyle(
                            color:
                            Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration:
                    BoxDecoration(
                      color: Colors
                          .teal.shade50,
                      borderRadius:
                      BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Text(
                      widget.unit,
                      style:
                      const TextStyle(
                        color:
                        Colors.teal,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              Expanded(
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GRAPH BORDER
  // ============================================================

  FlBorderData _graphBorder() {
    return FlBorderData(
      show: true,

      border: Border(
        left: BorderSide(
          color:
          Colors.grey.shade300,
        ),

        bottom: BorderSide(
          color:
          Colors.grey.shade300,
        ),

        top: BorderSide.none,
        right: BorderSide.none,
      ),
    );
  }

  // ============================================================
  // Y LIMITS
  // ============================================================

  Map<String, double> _calculateYLimits(
      double minValue,
      double maxValue,
      ) {
    double range =
        maxValue - minValue;

    if (range == 0) {
      if (maxValue == 0) {
        range = 10;
      } else {
        range =
            maxValue.abs() * 0.2;

        if (range == 0) {
          range = 10;
        }
      }
    }

    double minY =
        minValue - (range * 0.2);

    double maxY =
        maxValue + (range * 0.2);

    if (minValue >= 0 &&
        minY < 0) {
      minY = 0;
    }

    return {
      'min': minY,
      'max': maxY,
    };
  }

  // ============================================================
  // TODAY TABLE
  // ============================================================

  Widget _buildHourlyTable() {
    if (hourlyReport.isEmpty) {
      return const Center(
        child: Text(
          'No hourly data available',
        ),
      );
    }

    return Padding(
      padding:
      const EdgeInsets.all(12),

      child: Card(
        elevation: 2,

        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),

        clipBehavior:
        Clip.antiAlias,

        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 700,
          headingRowHeight: 50,

          headingRowColor:
          MaterialStateProperty.all(
            Colors.teal,
          ),

          columns: const [
            DataColumn2(
              label:
              _TableHeader('Hour'),
              fixedWidth: 80,
            ),

            DataColumn2(
              label:
              _TableHeader('Value'),
            ),

            DataColumn2(
              label:
              _TableHeader('Min'),
            ),

            DataColumn2(
              label:
              _TableHeader('Max'),
            ),

            DataColumn2(
              label:
              _TableHeader('Avg'),
            ),

            DataColumn2(
              label:
              _TableHeader('Status'),
            ),
          ],

          rows: hourlyReport.map(
                (item) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      item.hour,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),

                  DataCell(
                    Text(
                      item.value == 'NA'
                          ? 'NA'
                          : '${item.value} ${widget.unit}',
                    ),
                  ),

                  DataCell(
                    Text(
                      item.minValue == 'NA'
                          ? 'NA'
                          : '${item.minValue} ${widget.unit}',
                    ),
                  ),

                  DataCell(
                    Text(
                      item.maxValue == 'NA'
                          ? 'NA'
                          : '${item.maxValue} ${widget.unit}',
                    ),
                  ),

                  DataCell(
                    Text(
                      item.averageValue ==
                          'NA'
                          ? 'NA'
                          : '${item.averageValue} ${widget.unit}',
                    ),
                  ),

                  DataCell(
                    _statusWidget(
                      item.errorCode,
                    ),
                  ),
                ],
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // WEEKLY / MONTHLY TABLE
  //
  // TOTAL REMOVED
  // ============================================================

  Widget _buildDailyTable() {
    if (dailyReport.isEmpty) {
      return const Center(
        child: Text(
          'No report data available',
        ),
      );
    }

    return Padding(
      padding:
      const EdgeInsets.all(12),

      child: Card(
        elevation: 2,

        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),

        clipBehavior:
        Clip.antiAlias,

        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 700,
          headingRowHeight: 50,

          headingRowColor:
          MaterialStateProperty.all(
            Colors.teal,
          ),

          columns: const [
            DataColumn2(
              label:
              _TableHeader('Date'),
              size: ColumnSize.L,
            ),



            DataColumn2(
              label:
              _TableHeader('Average'),
            ),

            DataColumn2(
              label:
              _TableHeader('Min'),
            ),

            DataColumn2(
              label:
              _TableHeader('Max'),
            ),
          ],

          rows: dailyReport.map(
                (item) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      _formatDate(
                        item.date,
                      ),
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),


                  DataCell(
                    Text(
                      item.validHours == 0
                          ? 'NA'
                          : '${item.averageValue.toStringAsFixed(2)} ${widget.unit}',
                    ),
                  ),

                  DataCell(
                    Text(
                      item.validHours == 0
                          ? 'NA'
                          : '${item.minValue.toStringAsFixed(2)} ${widget.unit}',
                    ),
                  ),

                  DataCell(
                    Text(
                      item.validHours == 0
                          ? 'NA'
                          : '${item.maxValue.toStringAsFixed(2)} ${widget.unit}',
                    ),
                  ),
                ],
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
      String value,
      ) {
    try {
      final DateTime date =
      DateFormat(
        'yyyy-MM-dd',
      ).parse(
        value,
      );

      return DateFormat(
        'dd MMM yyyy',
      ).format(
        date,
      );
    } catch (_) {
      return value;
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusWidget(
      String code,
      ) {
    Color color;
    String text;

    if (code == '255') {
      color = Colors.green;
      text = 'Normal';
    } else if (code == 'NA' ||
        code.trim().isEmpty) {
      color = Colors.grey;
      text = 'NA';
    } else {
      color = Colors.red;
      text = 'ERR-$code';
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),

      decoration: BoxDecoration(
        color:
        color.withOpacity(0.08),

        borderRadius:
        BorderRadius.circular(20),

        border: Border.all(
          color:
          color.withOpacity(0.20),
        ),
      ),

      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight:
          FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
      String message,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

// ============================================================
// TABLE HEADER
// ============================================================

class _TableHeader
    extends StatelessWidget {
  final String text;

  const _TableHeader(
      this.text,
      );

  @override
  Widget build(
      BuildContext context,
      ) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight:
        FontWeight.bold,
      ),
    );
  }
}