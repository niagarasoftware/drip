import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../StateManagement/customer_provider.dart';
import '../../../../repository/repository.dart';
import '../../../../services/http_service.dart';
import '../../../../services/mqtt_service.dart';
import '../../../../utils/environment.dart';
import '../../../../utils/formatters.dart';
import '../../../../views/common/widgets/build_loading_indicator.dart';
import '../model/weather_model.dart';
import '../view_model/weather_view_model.dart';
import '../weather_report_monthly.dart';
import '../widgets/info_box.dart';
import '../widgets/sensor_chip.dart';
import '../widgets/sun_time_card.dart';
import '../widgets/time_of_day_icon_new.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';
import 'dart:async';

Color sensorStatusColor(int code) {
  if (code == 255) return Colors.green.shade700;
  switch (code) {
    case 1:
      return Colors.red.shade700;
    case 2:
      return Colors.yellow.shade700;
    case 3:
      return Colors.orange.shade700;
    default:
      return Colors.grey.shade600;
  }
}

class WeatherScreenNew extends StatefulWidget {
  const WeatherScreenNew({
    super.key,
    required this.customerId,
    required this.controllerId,
    required this.deviceID,
    required this.isNarrow,
  });

  final int customerId, controllerId;
  final String deviceID;
  final bool isNarrow;

  @override
  State<WeatherScreenNew> createState() => _WeatherScreenNewState();
}

class _WeatherScreenNewState extends State<WeatherScreenNew>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final MqttService manager = MqttService();
  Timer? _autoRefreshTimer;

  @override
  void dispose() {
    _tabController?.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    // _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        Request();
        Provider.of<WeatherViewModel>(context, listen: false).fetchWeatherData(
          widget.customerId,
          widget.controllerId,
        );
      }
    });
  }

  Request() {
    String payLoadFinal = jsonEncode({
      "5000":
      {"5001": ""},
    });
    manager.topicToPublishAndItsMessage(
        payLoadFinal, '${Environment.mqttPublishTopic}/${widget.deviceID}');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(Provider.of<CustomerProvider>(context).controllerId),
      create: (_) => WeatherViewModel(Repository(HttpService()))
        ..fetchWeatherData(widget.customerId, widget.controllerId),
      child: Consumer<WeatherViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoadingWeather) {
            return buildLoadingIndicator(context);
          }

          if (vm.weatherModel == null) {
            return const Center(child: Text("No weather data available"));
          }


          if (!vm.hasAnyWeatherStation) {
            return  Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text("No weather station data available"),
                    IconButton(
                      icon:  const Icon(Icons.refresh),
                      onPressed: () {
                        Request();
                        vm.fetchWeatherData(
                          widget.customerId,
                          widget.controllerId,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          final lines = vm.irrigationTree;

          if (_tabController != null &&
              _tabController!.length != lines.length) {
            _tabController!.dispose();
            _tabController = null;
          }

          _tabController ??= TabController(
            length: lines.length,
            vsync: this,
          );

          if(lines.length > 1){
             return MediaQuery.sizeOf(context).width < 600 ? Scaffold(
              appBar: AppBar(
                title: const Text("Weather"),
                bottom: TabBar(
                   labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: Colors.white,

                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    for (final line in lines) Tab(text: line.line.name),
                  ],
                ),
                actions: [IconButton(
                  icon:  const Icon(Icons.refresh),
                  onPressed: () {
                    Request();
                    vm.fetchWeatherData(
                      widget.customerId,
                      widget.controllerId,
                    );
                  },
                )],
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  for (final line in lines)
                    _LineTabView(line: line, vm: vm, isNarrow: widget.isNarrow,customerId: widget.customerId,userId: widget.controllerId,deviceId: widget.deviceID,),
                ],
              ),
            ) : Scaffold(  body: TabBarView(
               controller: _tabController,
               children: [
                 for (final line in lines)
                   _LineTabView(line: line, vm: vm, isNarrow: widget.isNarrow,customerId: widget.customerId,userId: widget.controllerId,deviceId: widget.deviceID,),
               ],
             ),);

          }else {
             return Scaffold(
               body: _LineTabView(line: lines[0], vm: vm, isNarrow: widget.isNarrow,customerId: widget.customerId,userId: widget.controllerId,deviceId: widget.deviceID,),
            );
          }
        },
      ),
    );
  }
}

class _LineTabView extends StatefulWidget {
  final WeatherViewModel vm;
  final IrrigationLineExpanded line;
  final bool isNarrow;
  final int customerId;
  final int userId;
  final String deviceId;

  const _LineTabView({
    required this.vm,
    required this.line,
    required this.isNarrow, required this.customerId, required this.userId,required this.deviceId,
  });

  @override
  State<_LineTabView> createState() => _LineTabViewState();
}

class _LineTabViewState extends State<_LineTabView> {
  int selectedStationIndex = 0;
  final MqttService manager = MqttService();

  Request() {
    String payLoadFinal = jsonEncode({
      "5000":
      {"5001": ""},
    });
    manager.topicToPublishAndItsMessage(
        payLoadFinal, '${Environment.mqttPublishTopic}/${widget.deviceId}');
  }
  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final line = widget.line;

    if (line.stations.isEmpty) {
      return const Center(child: Text("No weather stations"));
    }

    final station = line.stations[selectedStationIndex];
    final device = station.device;

    final rawDate =
        vm.weatherModel!.weatherLive.cD.toString().split(' ').first;

    String liveDateAndTime =
        '${rawDate}T${vm.weatherModel!.weatherLive.cT}';

    final formattedDT =
    Formatters.formatDateTime(liveDateAndTime);

    final temp = vm.getSensorLiveBySerial(
      serial: device.serialNumber,
      objectName: "Temperature Sensor",
      controllerId: device.controllerId,

    );

    final wind = vm.getSensorLiveBySerial(
      serial: device.serialNumber,
      objectName: "Wind Speed Sensor",
      controllerId: device.controllerId,
    );

    final humidity = vm.getSensorLiveBySerial(
      serial: device.serialNumber,
      objectName: "Humidity Sensor",
      controllerId: device.controllerId,
    );

    final tempText = temp == null ? "--" : temp.value.toStringAsFixed(1);
    final windText =
    wind == null ? "No Data" : "${wind.value.toStringAsFixed(1)} km/h";
    final humidityText =
    humidity == null ? "No Data" : "${humidity.value.toStringAsFixed(1)} %";

    print("line.stations.length${line.stations.length}");


    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              alignment: WrapAlignment.start,
              runAlignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(line.stations.length, (i) {
                print("i:$i,line.stations.length${line.stations.length}");
                final d = line.stations[i].device;
                return ChoiceChip(
                  label: Text(d.deviceName),
                  selected: i == selectedStationIndex,
                  onSelected: (_) {
                    setState(() => selectedStationIndex = i);
                  },
                );
              }),
            ),
          ),
        ),
        Expanded(
          child: widget.isNarrow
              ? _buildNarrowLayout(station, device, formattedDT, tempText, windText, humidityText)
              : _buildWideLayout(station, device, formattedDT, tempText, windText, humidityText),
        ),
      ],
    );
  }
//web
  Widget _buildWideLayout(
      station,
      device,
      String formattedDT,
      String tempText,
      String windText,
      String humidityText,
      )
  {
    print("_buildWideLayout call station.sensors:${station.sensors}");

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 320,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon:  const Icon(Icons.refresh),
                      onPressed: () {
                        Request();
                        widget.vm.fetchWeatherData(widget.customerId, widget.userId,);
                      },
                    ),
                    const Text("Get Live Data")
                  ],
                ),
                 _weatherSummaryCard(
                  formattedDT,
                  tempText,
                  windText,
                  humidityText,
                  widget.vm.weatherModel!.weatherLive.cT,
                ),
                const SizedBox(height: 16),
                sunCard(),
              ],
            ),
          ),
        ),
              Expanded(
    child: RefreshIndicator(
    onRefresh: () async {
    widget.vm.fetchWeatherData(widget.customerId, widget.userId,);
    // Wait a little to show the indicator
    await Future.delayed(const Duration(milliseconds: 500));
    },
    child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: station.sensors.map<Widget>((s) {
                      print("station.sensors name check:${s.name}");
                      return GestureDetector(
                        onTap: (){
                          // AppLog.log('deviceID ->${station.device[selectedStationIndex].deviceId}');
                          AppLog.log('device ->${station.device.controllerId}');
                          AppLog.log('deviceID ->$station');
                           // AppLog.log('userId ->${widget.userId} customerId ->${widget.customerId}');
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (_) => SensorHourlyReportPage(
                          //       deviceSrNo: '${station.device.serialNumber}',
                          //       sensorSrNo: s.sNo.toString(), sensorName: s.name, userId: '${widget.customerId}', controllerId: "${widget.userId}" ,unit:unit(s.name),
                          //     ),
                          //   ),
                          // );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SensorHourlyReportPage(
                                deviceSrNo: '${station.device.serialNumber}',
                                sensorSrNo: s.sNo.toString(), sensorName: s.name, userId: '${widget.customerId}', controllerId: "${widget.userId}" ,unit:unit(s.name),
                              ),
                            ),
                          );


                        },
                        child: SensorChip(
                          sensor: s,
                          vm: widget.vm,
                          device: device,
                          isNarrow:  widget.isNarrow,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),)
      ],
    );
  }
  String unit(String type) {
    type = type.toLowerCase();
    if (type.contains('moisture')) return 'CB';
    if (type.contains('temperature')) return '°C';
    if (type.contains('humidity')) return '%';
    if (type.contains('co2')) return 'ppm';
    if (type.contains('direction')) return '°';
    if (type.contains('Wind')) return 'km/h';
    if (type.contains('rain')) return 'mm';
    if (type.contains('lux')) return 'Lu';
    return '';
  }

  Widget _buildNarrowLayout(
      station,
      device,
      String formattedDT,
      String tempText,
      String windText,
      String humidityText,
      )
  {
    return   ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Row(
            children: [
              IconButton(
                icon:  const Icon(Icons.refresh),
                onPressed: () {
                  Request();
                  widget.vm.fetchWeatherData(widget.customerId, widget.userId);
                },
              ),
              const Text("Get Live Data")
            ],
          ),
          _weatherSummaryCard(
            formattedDT,
            tempText,
            windText,
            humidityText,
            widget.vm.weatherModel!.weatherLive.cT,
          ),
          const SizedBox(height: 16),
          sunCard(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: station.sensors.map<Widget>((s) {
                  return GestureDetector(
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SensorHourlyReportPage(
                            deviceSrNo: '${station.device.serialNumber}',
                            sensorSrNo: s.sNo.toString(), sensorName: s.name, userId: '${widget.customerId}', controllerId: "${widget.userId}" ,unit:unit(s.name),
                          ),
                        ),
                      );
                    },
                    child: SensorChip(
                      sensor: s,
                      vm: widget.vm,
                      device: device,
                      isNarrow: widget.isNarrow,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],

    );
  }

  Widget _weatherSummaryCard(
      String formattedDT,
      String tempText,
      String windText,
      String humidityText,
      String time,
      ) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.location_solid),
              SizedBox(width: 6),
              Text("Coimbatore"),
            ],
          ),
          const SizedBox(height: 12),
          Text(formattedDT),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$tempText °C",
                      style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Feel Like $tempText °C"),
                ],
              ),
              const SizedBox(width: 30),
              TimeOfDayIconNew(time: time),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: InfoBox(CupertinoIcons.wind, "Wind", windText)),
              const SizedBox(width: 12),
              Expanded(child: InfoBox(CupertinoIcons.drop_fill, "Humidity", humidityText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget sunCard() {
    return const Row(
      children: [
        Expanded(child: SunTimeCard("Sunrise", "6:10 AM", 'assets/Images/sunrise.png')),
        SizedBox(width: 12),
        Expanded(child: SunTimeCard("Sunset", "6:45 PM", 'assets/Images/sunset.png')),
      ],
    );
  }
}