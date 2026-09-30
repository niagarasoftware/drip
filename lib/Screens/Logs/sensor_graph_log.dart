import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../services/http_service.dart';

class SensorGraphLog extends StatefulWidget {
  final int userId;
  final int controllerId;
  final DateTime fromDate;
  final DateTime toDate;

  const SensorGraphLog({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<SensorGraphLog> createState() => _SensorGraphLogState();
}

enum GraphType { area, line, bar }

class SensorDataInfo {
  final String name;
  final String unit;
  final IconData icon;
  final List<List<ChartData>> multiData;
  final List<String> phaseNames;
  final List<double> phaseLatestValues;
  final List<double> phaseMaxValues;
  final List<double> phaseMinValues;
  final List<double> phaseLastActiveValues;

  SensorDataInfo({
    required this.name,
    required this.unit,
    required this.icon,
    required this.multiData,
    required this.phaseNames,
    required this.phaseLatestValues,
    required this.phaseMaxValues,
    required this.phaseMinValues,
    required this.phaseLastActiveValues,
  });
}

class ChartData {
  ChartData(this.time, this.value);
  final String time;
  final double value;
}

class _SensorGraphLogState extends State<SensorGraphLog> with SingleTickerProviderStateMixin {
  GraphType _selectedGraphType = GraphType.area;
  List<SensorDataInfo> _sensors = [];
  int _selectedSensorIndex = 0;
  final Set<int> _visiblePhases = {0, 1, 2};

  // Standard R-Y-B Phase Colors universally used in 3-phase electrical systems
  static const List<Color> phaseColors3 = [
    Color(0xFFE53935), // Red Phase (R)
    Color(0xFFFFB300), // Yellow/Amber Phase (Y)
    Color(0xFF1E88E5), // Blue Phase (B)
  ];

  static const List<Color> phaseBgColors3 = [
    Color(0xFFFFEBEE), // Light Red tint
    Color(0xFFFFF8E1), // Light Yellow tint
    Color(0xFFE3F2FD), // Light Blue tint
  ];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _apiDate(DateTime date) {
    final yyyy = date.year;
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  String _displayDate(DateTime date) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${monthNames[date.month - 1]} ${date.year}';
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fromDateStr = _apiDate(widget.fromDate);
      final toDateStr = _apiDate(widget.toDate);
      final body = {
        "userId": widget.userId,
        "controllerId": widget.controllerId,
      };
      
      final logBody = {
        ...body,
        "fromDate": fromDateStr,
        "toDate": toDateStr,
      };

      final configRes = await HttpService().postRequest('/user/configMaker/getAsDefault', body);
      final logRes = await HttpService().postRequest('/user/log/scheduleSensor/get', logBody);

      if (configRes.statusCode == 200 && logRes.statusCode == 200) {
        final configJson = jsonDecode(configRes.body);
        final logJson = jsonDecode(logRes.body);
        if (configJson['code'] == 200 && logJson['code'] == 200) {
          _parseData(configJson, logJson);
        } else {
          setState(() {
            _errorMessage = ''
                '${logJson['message']}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server Error: ${configRes.statusCode} / ${logRes.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _parseData(Map<String, dynamic> configJson, Map<String, dynamic> logJson) {
    // 3. Mapping sNo to Sensor Metadata from Config
    Map<String, Map<String, String>> sNoMetadata = {};
    if (configJson['data'] != null && configJson['data']['configObject'] != null) {
      for (var obj in configJson['data']['configObject']) {
        String sNo = obj['sNo'].toString();
        sNoMetadata[sNo] = {
          'name': obj['name']?.toString() ?? 'Unknown Sensor',
          'objectName': obj['objectName']?.toString() ?? 'Unknown',
        };
      }
    }

    // 4. Parsing the Logs and populating _sensors
    List<SensorDataInfo> parsedSensors = [];
    if (logJson['data'] != null && logJson['data']['log'] != null) {
      for (var logEntry in logJson['data']['log']) {
        
        // Handle both "scheduleSensor" (new API format) and "irrigation" (old mock format)
        Map<String, dynamic>? dataGroup;
        if (logEntry['scheduleSensor'] != null) {
          dataGroup = logEntry['scheduleSensor'];
        } else if (logEntry['irrigation'] != null) {
          dataGroup = logEntry['irrigation'];
        }

        if (dataGroup != null && dataGroup.isNotEmpty) {
          // Aggregate all sensor data across multiple schedule IDs (410, 411, 412, etc.)
          Map<String, List<String>> aggregatedSensorsLog = {};
          
          dataGroup.forEach((scheduleId, sensorsLog) {
            sensorsLog.forEach((sensorKey, valuesList) {
              if (!aggregatedSensorsLog.containsKey(sensorKey)) {
                aggregatedSensorsLog[sensorKey] = [];
              }
              // Add all timestamps from this schedule segment to the master list for this sensor
              aggregatedSensorsLog[sensorKey]!.addAll(List<String>.from(valuesList));
            });
          });

          // Now parse the aggregated time-series data for each sensor
          aggregatedSensorsLog.forEach((sensorKey, valuesList) {
            List<String> keyParts = sensorKey.split('_');
            String sNo = keyParts[0];
            String subParam = keyParts.length > 1 ? keyParts[1] : '';
              
              var meta = sNoMetadata[sNo] ?? {'name': 'Sensor $sNo', 'objectName': ''};
              String sensorName = meta['name']!;
              String objectType = meta['objectName']!;
              
              String unit = '';
              IconData icon = Icons.sensors_rounded;

              // Assign properties based on the STRICT objectName from the backend
              switch (objectType) {
                case 'Moisture Sensor':
                  unit = '%';
                  icon = Icons.water_drop_rounded;
                  break;
                case 'Soil Temperature Sensor':
                case 'Temperature Sensor':
                  unit = '°C';
                  icon = Icons.thermostat_rounded;
                  break;
                case 'Level Sensor':
                  unit = '%';
                  icon = Icons.waves_rounded;
                  break;
                case 'Pressure Sensor':
                  unit = 'bar';
                  icon = Icons.speed_rounded;
                  break;
                case 'EC Sensor':
                  unit = 'dS/m';
                  icon = Icons.science_rounded;
                  break;
                case 'PH Sensor':
                  unit = 'pH';
                  icon = Icons.opacity_rounded;
                  break;
                case 'Pump':
                  if (subParam == '-1') {
                    sensorName += ' (Voltage)';
                    unit = 'V';
                    icon = Icons.bolt_rounded;
                  } else if (subParam == '-2') {
                    sensorName += ' (Current)';
                    unit = 'A';
                    icon = Icons.electric_meter_rounded;
                  } else {
                    icon = Icons.water_damage_rounded;
                  }
                  break;
                default:
                  unit = '';
                  icon = Icons.analytics_rounded;
              }

              List<List<ChartData>> multiData = [[], [], []];
              int phaseCount = 1;

              for (String valStr in valuesList) {
                List<String> parts = valStr.split(',');
                if (parts.length >= 2) {
                  String time = parts[0].substring(0, 5); // Extract "08:15"
                  String dataPart = parts[1];
                  
                  List<String> phaseStrings = dataPart.split('_');
                  phaseCount = phaseStrings.length;
                  
                  for (int i = 0; i < phaseStrings.length; i++) {
                     double parsedValue = 0.0;
                     if (phaseStrings[i].contains(':')) {
                       parsedValue = double.tryParse(phaseStrings[i].split(':').last) ?? 0.0;
                     } else {
                       parsedValue = double.tryParse(phaseStrings[i]) ?? 0.0;
                     }
                     if (i < 3) {
                       multiData[i].add(ChartData(time, parsedValue));
                     }
                  }
                }
              }

              multiData = multiData.take(phaseCount).toList();

              // Compute phase statistics
              List<double> latestValues = [];
              List<double> maxValues = [];
              List<double> minValues = [];
              List<double> lastActiveValues = [];

              for (int i = 0; i < phaseCount; i++) {
                var series = multiData[i];
                if (series.isNotEmpty) {
                  latestValues.add(series.last.value);
                  
                  double mx = series.map((e) => e.value).reduce((a, b) => a > b ? a : b);
                  maxValues.add(mx);
                  
                  double mn = series.map((e) => e.value).reduce((a, b) => a < b ? a : b);
                  minValues.add(mn);

                  var nonZeroSeries = series.where((e) => e.value > 0).toList();
                  if (nonZeroSeries.isNotEmpty) {
                    lastActiveValues.add(nonZeroSeries.last.value);
                  } else {
                    lastActiveValues.add(0.0);
                  }
                } else {
                  latestValues.add(0.0);
                  maxValues.add(0.0);
                  minValues.add(0.0);
                  lastActiveValues.add(0.0);
                }
              }

              List<String> phaseNames = [];
              if (phaseCount == 3) {
                phaseNames = ['R Phase (Red)', 'Y Phase (Yellow)', 'B Phase (Blue)'];
              } else {
                phaseNames = List.generate(phaseCount, (i) => 'Phase ${i + 1}');
              }

              parsedSensors.add(
                SensorDataInfo(
                  name: sensorName,
                  unit: unit,
                  icon: icon,
                  multiData: multiData,
                  phaseNames: phaseNames,
                  phaseLatestValues: latestValues,
                  phaseMaxValues: maxValues,
                  phaseMinValues: minValues,
                  phaseLastActiveValues: lastActiveValues,
                )
              );
            });
          }
        }
    }

    setState(() {
      _sensors = parsedSensors;
      if (_sensors.isNotEmpty) {
        _visiblePhases.clear();
        _visiblePhases.addAll(List.generate(_sensors[0].multiData.length, (i) => i));
      }
      _isLoading = false;
    });
  }

  void _onSensorSelected(int index) {
    setState(() {
      _selectedSensorIndex = index;
      _visiblePhases.clear();
      _visiblePhases.addAll(List.generate(_sensors[index].multiData.length, (i) => i));
    });
  }

  void _togglePhase(int phaseIndex) {
    setState(() {
      if (_visiblePhases.contains(phaseIndex)) {
        if (_visiblePhases.length > 1) {
          _visiblePhases.remove(phaseIndex);
        }
      } else {
        _visiblePhases.add(phaseIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor.withValues(alpha: 0.05),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.query_stats_rounded, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              'Sensor Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                color: textColor,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: primaryColor.withValues(alpha: 0.1),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody(primaryColor, backgroundColor, textColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Color primaryColor, Color backgroundColor, Color textColor) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (_sensors.isEmpty) {
      String dateText = widget.fromDate.isAtSameMomentAs(widget.toDate)
          ? _displayDate(widget.fromDate)
          : '${_displayDate(widget.fromDate)} - ${_displayDate(widget.toDate)}';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: textColor.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No Sensor Data Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No logs found for $dateText',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    final selectedSensor = _sensors[_selectedSensorIndex];

    return Column(
      children: [
        _buildSensorSelector(primaryColor, textColor),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prominent R Phase, Y Phase, B Phase Interactive Cards
                _buildPhaseCardsSection(primaryColor, textColor, selectedSensor),
                const SizedBox(height: 20),

                    // Graph Header & Graph Controls (Area / Line / Bar)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.insights_rounded, color: primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Trend Graph",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Swipe to pan • Tap cards to filter",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textColor.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildGraphTypeToggle(primaryColor, textColor),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Interactive Syncfusion Chart
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        key: ValueKey('$_selectedSensorIndex-$_selectedGraphType-${_visiblePhases.join(",")}'),
                        height: MediaQuery.of(context).size.height * (MediaQuery.of(context).size.width > 600 ? 0.5 : 0.45),
                        constraints: BoxConstraints(minHeight: 280, maxHeight: MediaQuery.of(context).size.width > 600 ? 600 : 400),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildSyncfusionChart(primaryColor, textColor, selectedSensor),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // // Dual Insights: Farmer Friendly + Technical Breakdown
                    // _buildDualInsights(primaryColor, textColor, selectedSensor),
                    // const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  // Widget _buildTopAppBar(Color primaryColor, Color textColor, SensorDataInfo selectedSensor) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).scaffoldBackgroundColor,
  //       border: Border(
  //         bottom: BorderSide(color: textColor.withValues(alpha: 0.06), width: 1),
  //       ),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Row(
  //           children: [
  //             // IconButton(
  //             //   icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
  //             //   onPressed: () {
  //             //     if (Navigator.canPop(context)) Navigator.pop(context);
  //             //   },
  //             // ),
  //             const SizedBox(width: 4),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Sensor & Phase Logs',
  //                   style: TextStyle(
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                     color: textColor,
  //                   ),
  //                 ),
  //                 Text(
  //                   selectedSensor.category,
  //                   style: TextStyle(
  //                     fontSize: 12,
  //                     color: textColor.withValues(alpha: 0.55),
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //           decoration: BoxDecoration(
  //             color: selectedSensor.statusColor.withValues(alpha: 0.12),
  //             borderRadius: BorderRadius.circular(20),
  //             border: Border.all(color: selectedSensor.statusColor.withValues(alpha: 0.4), width: 1),
  //           ),
  //           child: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Container(
  //                 width: 8,
  //                 height: 8,
  //                 decoration: BoxDecoration(
  //                   color: selectedSensor.statusColor,
  //                   shape: BoxShape.circle,
  //                 ),
  //               ),
  //               const SizedBox(width: 6),
  //               Text(
  //                 selectedSensor.overallStatus,
  //                 style: TextStyle(
  //                   fontSize: 11,
  //                   fontWeight: FontWeight.bold,
  //                   color: selectedSensor.statusColor,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSensorSelector(Color primaryColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.02),
        border: Border(bottom: BorderSide(color: textColor.withValues(alpha: 0.05), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_sensors.length, (index) {
            final isSelected = _selectedSensorIndex == index;
            final sensor = _sensors[index];
            return GestureDetector(
              onTap: () => _onSensorSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : textColor.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Row(
                  children: [
                    Icon(
                      sensor.icon,
                      color: isSelected ? Colors.white : primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sensor.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : textColor.withValues(alpha: 0.8),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (sensor.multiData.length == 3) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.25) : primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '3 Phase',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : primaryColor,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPhaseCardsSection(Color primaryColor, Color textColor, SensorDataInfo sensor) {
    if (sensor.multiData.length == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '3-Phase Live Values',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Text(
                'Tap card to filter graph',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (i) {
              final isVisible = _visiblePhases.contains(i);
              final phaseColor = phaseColors3[i];
              final phaseBg = phaseBgColors3[i];
              final phaseName = sensor.phaseNames[i];
              final latestVal = sensor.phaseLatestValues[i];
              final lastActiveVal = sensor.phaseLastActiveValues[i];
              final maxVal = sensor.phaseMaxValues[i];

              // Display value: if latest is 0, show peak active value with clear indicator
              final displayVal = latestVal > 0 ? latestVal : lastActiveVal;
              final isOff = latestVal == 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _togglePhase(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: isVisible 
                          ? LinearGradient(
                              colors: [
                                phaseColor.withValues(alpha: 0.15),
                                phaseColor.withValues(alpha: 0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isVisible ? null : textColor.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isVisible ? phaseColor.withValues(alpha: 0.6) : textColor.withValues(alpha: 0.08),
                        width: isVisible ? 2 : 1,
                      ),
                      boxShadow: isVisible
                          ? [
                              BoxShadow(
                                color: phaseColor.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Phase Tag (R / Y / B)
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: isVisible ? phaseColor : Colors.grey.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                boxShadow: isVisible ? [
                                  BoxShadow(
                                    color: phaseColor.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ] : [],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                phaseName.split(' ').first, // 'R', 'Y', 'B'
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isVisible ? phaseColor : textColor.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            Icon(
                              isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              size: 16,
                              color: isVisible ? phaseColor : textColor.withValues(alpha: 0.2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Phase Value
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                displayVal.toStringAsFixed(displayVal.truncateToDouble() == displayVal ? 0 : 1),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: isVisible ? textColor : textColor.withValues(alpha: 0.3),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sensor.unit,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isVisible ? phaseColor : textColor.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Peak / Status subtext
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOff ? Colors.transparent : (isVisible ? phaseColor.withValues(alpha: 0.1) : Colors.transparent),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isOff ? textColor.withValues(alpha: 0.1) : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            isOff ? 'Peak: ${maxVal.toStringAsFixed(0)} ${sensor.unit}' : 'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isOff
                                  ? textColor.withValues(alpha: 0.5)
                                  : (isVisible ? phaseColor : textColor.withValues(alpha: 0.4)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );
    } else {
      // 1-Phase Card
      final val = sensor.phaseLatestValues.isNotEmpty ? sensor.phaseLatestValues[0] : 0.0;
      final maxV = sensor.phaseMaxValues.isNotEmpty ? sensor.phaseMaxValues[0] : 0.0;
      final minV = sensor.phaseMinValues.isNotEmpty ? sensor.phaseMinValues[0] : 0.0;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.12),
              primaryColor.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(sensor.icon, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sensor.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1),
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sensor.unit,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: textColor.withValues(alpha: 0.05)),
                  ),
                  child: Text(
                    'Max: $maxV ${sensor.unit}',
                    style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: textColor.withValues(alpha: 0.05)),
                  ),
                  child: Text(
                    'Min: $minV ${sensor.unit}',
                    style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildGraphTypeToggle(Color primaryColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(Icons.stacked_line_chart_rounded, 'Area', GraphType.area, primaryColor, textColor),
          _buildToggleOption(Icons.show_chart_rounded, 'Line', GraphType.line, primaryColor, textColor),
          _buildToggleOption(Icons.bar_chart_rounded, 'Bar', GraphType.bar, primaryColor, textColor),
        ],
      ),
    );
  }

  Widget _buildToggleOption(IconData icon, String label, GraphType type, Color primaryColor, Color textColor) {
    final isSelected = _selectedGraphType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGraphType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? primaryColor : textColor.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncfusionChart(Color primaryColor, Color textColor, SensorDataInfo sensor) {
    double maxVal = -double.infinity;
    double minVal = double.infinity;
    
    for (int i = 0; i < sensor.multiData.length; i++) {
      if (!_visiblePhases.contains(i)) continue;
      for (var point in sensor.multiData[i]) {
        if (point.value > maxVal) maxVal = point.value;
        if (point.value < minVal) minVal = point.value;
      }
    }
    
    if (maxVal == -double.infinity) maxVal = 10;
    if (minVal == double.infinity) minVal = 0;

    double rangePadding = (maxVal - minVal) == 0 ? (maxVal == 0 ? 10 : maxVal * 0.2) : (maxVal - minVal) * 0.25;
    double yMax = maxVal + rangePadding;
    double yMin = (minVal - rangePadding) < 0 ? 0 : (minVal - rangePadding);
    if (yMax == 0) yMax = 10;

    int maxDataPoints = 0;
    for (var series in sensor.multiData) {
      if (series.length > maxDataPoints) maxDataPoints = series.length;
    }

    return SfCartesianChart(
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enablePinching: true,
        enableDoubleTapZooming: true,
        zoomMode: ZoomMode.x,
      ),
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      legend: Legend(
        isVisible: sensor.multiData.length > 1,
        position: LegendPosition.top,
        alignment: ChartAlignment.center,
        textStyle: TextStyle(
          color: textColor.withValues(alpha: 0.8),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        iconHeight: 12,
        iconWidth: 12,
        padding: 8,
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: '',
        canShowMarker: true,
        shared: true,
        format: 'series.name: point.y ${sensor.unit}',
        color: textColor.withValues(alpha: 0.95),
        textStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).scaffoldBackgroundColor,
          fontSize: 12,
        ),
        elevation: 8,
      ),
      primaryXAxis: CategoryAxis(
        initialVisibleMinimum: maxDataPoints > 8 
            ? (maxDataPoints - 8).toDouble() 
            : 0.0,
        initialVisibleMaximum: maxDataPoints > 0 
            ? (maxDataPoints - 1).toDouble() 
            : 0.0,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: AxisLine(width: 1, color: textColor.withValues(alpha: 0.1)),
        labelStyle: TextStyle(
          color: textColor.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        majorTickLines: const MajorTickLines(size: 4),
      ),
      primaryYAxis: NumericAxis(
        minimum: yMin,
        maximum: yMax,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(
          width: 1,
          color: textColor.withValues(alpha: 0.06),
          dashArray: const <double>[4, 4],
        ),
        labelStyle: TextStyle(
          color: textColor.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        labelFormat: '{value} ${sensor.unit}',
      ),
      series: _getChartSeries(primaryColor, sensor),
    );
  }

  List<CartesianSeries<ChartData, String>> _getChartSeries(Color primaryColor, SensorDataInfo sensor) {
    List<CartesianSeries<ChartData, String>> seriesList = [];
    
    List<Color> phaseColors = sensor.multiData.length == 3 
        ? phaseColors3 
        : [primaryColor, Colors.orange, Colors.green];

    for (int i = 0; i < sensor.multiData.length; i++) {
       if (!_visiblePhases.contains(i)) continue;

       Color seriesColor = sensor.multiData.length == 1 ? primaryColor : phaseColors[i];
       String seriesName = sensor.phaseNames.length > i ? sensor.phaseNames[i] : 'Phase ${i + 1}';

       if (_selectedGraphType == GraphType.area) {
          seriesList.add(SplineAreaSeries<ChartData, String>(
            name: seriesName,
            dataSource: sensor.multiData[i],
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.value,
            gradient: LinearGradient(
              colors: [
                seriesColor.withValues(alpha: 0.3),
                seriesColor.withValues(alpha: 0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderColor: seriesColor,
            borderWidth: 3.5,
            markerSettings: const MarkerSettings(
              isVisible: true,
              height: 6,
              width: 6,
              shape: DataMarkerType.circle,
            ),
            animationDuration: 800,
          ));
       } else if (_selectedGraphType == GraphType.line) {
          seriesList.add(SplineSeries<ChartData, String>(
            name: seriesName,
            dataSource: sensor.multiData[i],
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.value,
            color: seriesColor,
            width: 3.5,
            markerSettings: const MarkerSettings(
              isVisible: true,
              height: 6,
              width: 6,
              shape: DataMarkerType.circle,
            ),
            animationDuration: 800,
          ));
       } else {
          seriesList.add(ColumnSeries<ChartData, String>(
            name: seriesName,
            dataSource: sensor.multiData[i],
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.value,
            color: seriesColor.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            width: sensor.multiData.length == 1 ? 0.4 : 0.6,
            animationDuration: 800,
          ));
       }
    }
    return seriesList;
  }

  // Widget _buildDualInsights(Color primaryColor, Color textColor, SensorDataInfo sensor) {
  //   return Column(
  //     children: [
  //       // 1. Simple Farmer Friendly Card (Easy for uneducated users)
  //       Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: const Color(0xFFE8F5E9), // Light green farmer theme
  //           borderRadius: BorderRadius.circular(16),
  //           border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
  //         ),
  //         child: Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: const BoxDecoration(
  //                 color: Color(0xFF2E7D32),
  //                 shape: BoxShape.circle,
  //               ),
  //               child: const Icon(
  //                 Icons.eco_rounded,
  //                 color: Colors.white,
  //                 size: 20,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     'Farmer Simple Summary',
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.bold,
  //                       color: Color(0xFF1B5E20),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     sensor.farmerTip,
  //                     style: const TextStyle(
  //                       fontSize: 13,
  //                       color: Color(0xFF2E7D32),
  //                       height: 1.4,
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 12),
  //
  //       // 2. Technical Diagnostics Card (For educated users / engineers)
  //       Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: Theme.of(context).cardColor,
  //           borderRadius: BorderRadius.circular(16),
  //           border: Border.all(color: textColor.withValues(alpha: 0.08), width: 1),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withValues(alpha: 0.03),
  //               blurRadius: 8,
  //               offset: const Offset(0, 3),
  //             ),
  //           ],
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(
  //                   Icons.analytics_rounded,
  //                   color: primaryColor,
  //                   size: 20,
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Text(
  //                   'Technical Diagnostics & Metrics',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.bold,
  //                     color: textColor,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 10),
  //             Text(
  //               sensor.insightOptimal,
  //               style: TextStyle(
  //                 fontSize: 13,
  //                 color: textColor.withValues(alpha: 0.75),
  //                 height: 1.4,
  //                 fontWeight: FontWeight.w400,
  //               ),
  //             ),
  //             if (sensor.multiData.length == 3) ...[
  //               const Divider(height: 20),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceAround,
  //                 children: [
  //                   _buildTechStat('R Peak', '${sensor.phaseMaxValues[0].toStringAsFixed(0)} ${sensor.unit}', phaseColors3[0]),
  //                   _buildTechStat('Y Peak', '${sensor.phaseMaxValues[1].toStringAsFixed(0)} ${sensor.unit}', phaseColors3[1]),
  //                   _buildTechStat('B Peak', '${sensor.phaseMaxValues[2].toStringAsFixed(0)} ${sensor.unit}', phaseColors3[2]),
  //                   _buildTechStat('Variance', '< 2%', primaryColor),
  //                 ],
  //               ),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildTechStat(String label, String val, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
