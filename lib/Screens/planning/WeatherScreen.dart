import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:oro_drip_irrigation/Screens/planning/weather_reports.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../models/weather_modelnew.dart';
import '../../Widgets/animated_cloud.dart';
import '../../modules/IrrigationProgram/view/water_and_fertilizer_screen.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/environment.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen(
      {Key? key,
        required this.userId,
        required this.controllerId,
        required this.deviceID});
  final userId, controllerId, deviceID;
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  //  0aa7f59482130e8e8384ae8270d79097 // API KEY
  Map<String, dynamic> weatherData = {};
  late DateTime _currentTime;
  String sunrise = '06:00 AM';
  String sunset = '06:00 PM';
  String daylight = 'Day Light Length: 12:00:00';
  List<String> weekDayList = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  bool isLoading = false;
  int tabclickindex = 0;
  String errorMsgstatus = '';
  WeatherData weathernewlive = WeatherData(cC: '', cT: '', cD: '', stations: []) ;
  late List<IrrigationLine>  weatherdatairrigationline ;
  late List<DeviceW>  weatherdatadevicelist ;
  final MqttService manager = MqttService();


  late List<ConfigObjectWeather> weatherdataconfigobjects ;


  @override
  void initState() {
    _currentTime = DateTime.now();
    super.initState();
    Request();
    fetchDataSunRiseSet();
    fetchDataLive();

  }

  @override
  void dispose() {
    //_timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (weatherData.isNotEmpty && (weatherData != null)) {
      sunrise = '${weatherData['results']['sunrise']}';
      sunset = '${weatherData['results']['sunset']}';
      daylight = 'Day Light Length: ${weatherData['results']['day_length']}';
    }
    if (weathernewlive == null) {
      return const Center(child: CircularProgressIndicator());
    }
    else if (weathernewlive.stations.isEmpty) {
      // return const Center(child: Text('Currently No Weather Data Available'));
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
              child: Text('Currently No Weather Data Available...')),


        ],
      );
    }
    else {
      return DefaultTabController(
        length: weathernewlive.stations.length,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: TabBar(
                      // controller: _tabController,

                      indicatorColor:Theme.of(context).primaryColorLight,
                      isScrollable: true,
                      unselectedLabelColor: Colors.black,
                      labelColor: Theme.of(context).primaryColor,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: [
                        for (var i = 0;
                        i < weathernewlive.stations.length;
                        i++)
                          Tab(
                            text:'${deviceFind(weathernewlive.stations[i].deviceId)?.deviceName ?? 'Weather Station'}',
                          ),
                      ],
                      onTap: (value) {
                        setState(() {
                          tabclickindex = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: TabBarView(children: [
                        for (var i = 0;
                        i < weathernewlive.stations.length;
                        i++)
                          buildTab(i)
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  String getSensorUnit(double sno) {
    final Map<int, String> sensorUnits = {
      25: 'CB',
      29: '°C',
      30: '°C',
      31: '',
      32: 'km/h',
      33: 'ppm',
      34: 'lx',
      35: 'Lu',
      36: '%',
      37: '%',
      38: 'MM',
      39: 'kPa',
    };

    return sensorUnits[sno.floor()] ?? '';
  }

  changeval(int Selectindexrow) {}
  Widget buildTab(int i) {
    // List<String> titlelist = ['SoilMoisture 1','SoilMoisture 2','SoilMoisture 3','SoilMoisture 4','Temperature','AtmospherePressure','Humidity','LeafWetness','Co2','LDR','Lux','Rainfall','WindSpeed','Wind Direction'];
    // List<String> unitlist = ['CB','CB','CB','CB','°C','°C','kPa','%','%','ppm','Lu','MM','km/h',''];

    String? irname = findIrrigationLine(weathernewlive.stations[i].deviceId)!;


    return Scaffold(body: Center(
      child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (MediaQuery.sizeOf(context).width < 800) {
              //mobile view
              return SafeArea(
                child: Container(color: Theme.of(context).scaffoldBackgroundColor,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header


                        // Main Weather Display
                        SizedBox(
                          height: 350, // Increased height from 300 to 350 to accommodate content
                          child: Stack(
                            children: [
                              AnimatedClouds(),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.sunny_snowing, // Replace with a rain icon if available
                                    size: 100,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    '28°',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 80,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Precipitations',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'MAX.: 31°  MIN.: 25°',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildWeatherDetail(Icons.water_drop, '6%'),
                                      const SizedBox(width: 16),
                                      _buildWeatherDetail(Icons.arrow_upward, '90%'),
                                      const SizedBox(width: 16),
                                      _buildWeatherDetail(Icons.air, '19 km/h'),
                                    ],
                                  ),
                                ],
                              )],
                          ),
                        ),

                        // Weather Cards
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              // String value = '${weathernewlive.stations[i].sensors[index].value}';
                              // String errorStatus = '${weathernewlive.stations[i].sensors[index].errorStatus}';
                              for (var index = 0;index < weathernewlive.stations[i].sensors.length; index++)
                                _buildWeatherCard(getConfigObjectNameBySNo(weatherdataconfigobjects,weathernewlive.stations[i].sensors[index].sno)!, '${weathernewlive.stations[i].sensors[index].value} ${getSensorUnit(weathernewlive.stations[i].sensors[index].sno)}', '', Colors.orange),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );

            } else {
              return Row(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height,
                    width: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.grey.shade100,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                const Text('Last Sync:'),
                                IconButton(
                                    onPressed: () {
                                      Request();
                                      fetchDataLive();
                                    },
                                    icon: const Icon(Icons.refresh)),
                              ],
                            ),
                            Text(
                              maxLines: 3,
                              '${weathernewlive.cT} / ${weathernewlive.cD}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Image.asset(
                          'assets/images/w08.png',
                          width: 150.0,
                          height: 150.0,
                          fit: BoxFit.cover,
                        ),
                        // Text(
                        //   '${weathernewlive.stations[i].sensors[6].value}°C',
                        //   style: TextStyle(
                        //       fontWeight: FontWeight.normal,
                        //       fontSize: 68,
                        //       color: Theme.of(context).primaryColor),
                        // ),
                        SizedBox(
                          height: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Image.asset(
                                    'assets/images/sunrise.png',
                                    width: 50.0,
                                    height: 50.0,
                                    fit: BoxFit.cover,
                                  ),
                                  Text(
                                    '$sunrise',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 18),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Image.asset(
                                    'assets/images/sunset.png',
                                    width: 50.0,
                                    height: 50.0,
                                    fit: BoxFit.cover,
                                  ),
                                  Text(
                                    '$sunset',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$daylight',
                          style: const TextStyle(
                              fontWeight: FontWeight.normal, fontSize: 15),
                        ),

                        // Container(
                        //   height: 1,
                        //   color: Colors.black,
                        // ),

                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Container(
                            height: 20,
                            padding:
                            const EdgeInsets.only(left: 30, right: 30, bottom: 5),
                            alignment: Alignment.centerLeft,
                            child:  Text(
                              'Weather Sensors : $irname',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),

//${findIrrigationLine(weathernewlive.stations[i].deviceId) ?? ''}
                          Expanded(
                            flex: 3,
                            child: Container(
                              color: Colors.teal.shade100,
                              padding:
                              const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                              // height: constraints.maxHeight * 0.59,
                              child: LayoutBuilder(
                                builder: (BuildContext context,
                                    BoxConstraints constraints) {
                                  return SingleChildScrollView(
                                    child: customizeGridView(
                                      maxWith: 200,
                                      maxHeight: 290,
                                      screenWidth: constraints.maxWidth,
                                      listOfWidget: [
                                        for (var index = 0;
                                        index < weathernewlive.stations[i].sensors.length;
                                        index++)
                                      GestureDetector(
                                      onDoubleTap: (){
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReportPage(
                                          sensorsrno: weatherdataconfigobjects[index].sNo ,
                                            devicesnro: 6,
                                            userId:widget.userId,
                                            controllerId:widget.controllerId,
                                            deviceID: widget.deviceID,
                                            initialReportType: getReportType(weatherdataconfigobjects[index].objectName,weatherdataconfigobjects[index].sNo) ?? "SoilMoisture1",
                                       ),
                                    ));
                                  },
                                            child: gaugeViewWeather(
                                                getConfigObjectNameBySNo(weatherdataconfigobjects,weathernewlive.stations[i].sensors[index].sno)!,
                                                i,
                                                index),
                                          )

                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          }),
    ));
  }
  double? extractNumber(String value) {
    RegExp regExp = RegExp(r'-?\d+(\.\d+)?');
    Match? match = regExp.firstMatch(value);
    if (match != null) {
      return double.tryParse(match.group(0)!);
    } else {
      return 0.0;
    }
  }
  Widget _buildWeatherDetail(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black, size: 20),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildWeatherCard(String title, String value, String status, Color statusColor) {
    double? extractval = extractNumber(value);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.6), // Adjust opacity and color
          borderRadius: BorderRadius.circular(16), // Rounded corners
          border: Border.all(
            color: Colors.teal, // Subtle border
            width: 1,
          ),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CircleAvatar(
              backgroundColor:Colors.blueGrey,
              radius: 20,
              child:  Icon(Icons.air, color: Colors.white, size: 20),
            ),

            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title.contains('Direction') ?  degreeToDirection(value) : value,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  // const Text( degreeToDirection(value)
                  //   'MAX.: 00/00  MIN.: 00/00',
                  //   style: TextStyle(color: Colors.white70, fontSize: 12),
                  // ),
                ],
              ),
            ),
            Column(
              children: [
                Stack(
                  children: [
                    Center(
                      child: extractval! > 25 ? Image.asset(
                        'assets/mob_dashboard/weathergraphval.png',
                        fit: BoxFit.cover,
                      ) : Image.asset(
                        'assets/mob_dashboard/weathergraphemtyval.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 20,
                      left: 18,
                      child: Text(
                        '$extractval',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  String? getReportType(String objectName, double sNo) {
    print("objectNamecall$objectName");
    print("sNo$sNo");
    // Static reportTypes
    const List<String> reportTypes = [
      'SoilMoisture1',
      'SoilMoisture2',
      'SoilMoisture3',
      'SoilMoisture4',
      'SoilTemperature',
      'Humidity',
      'WindDirection',
      'WindSpeed',
      'temperature',
      'AtmosphericPressure',
      'LeafWetness',
      'Rainfall',
      'CO2',
      'LDR',
      'Lux'
    ];

    // Static objectName → base mapping
    const Map<String, String> objectNameToBase = {
      'Moisture Sensor': 'SoilMoisture',
      'Temperature Sensor': 'temperature',
      'Soil Temperature Sensor': 'SoilTemperature',
      'Wind Direction Sensor': 'WindDirection',
      'Wind Speed Sensor': 'WindSpeed',
      'Humidity Sensor': 'Humidity',
      'Leaf Wetness Sensor': 'LeafWetness',
      'Rain Fall Sensor': 'Rainfall',
      'Co2 Sensor': 'CO2',
      'LUX Sensor': 'Lux',
      'LDR Sensor': 'LDR',
      'Atmospheric Pressure': 'AtmosphericPressure',
    };

    // 1️⃣ get base
    final base = objectNameToBase[objectName];
    if (base == null) return null;

    // 2️⃣ Moisture Sensor → needs index
    if (base == 'SoilMoisture') {
      // 25.001 → 1, 25.002 → 2
      final index = ((sNo * 1000).round() % 1000);
      final value = '$base$index';
print("value$value");
      return reportTypes.contains(value) ? value : "SoilMoisture1";
    }

    // 3️⃣ Other sensors
    print("value$base");

    return reportTypes.contains(base) ? base : "SoilMoisture1";
  }





  Color Getcolor(String val) {
    if (val == '1') {
      return Colors.red.shade100;
    } else if (val == '2') {
      return Colors.yellow.shade100;
    } else if (val == '3') {
      return Colors.orange.shade100;
    } else {
      return Colors.white70;
    }
  }

  DeviceW? deviceFind(int serialNumber) {
    return weatherdatadevicelist.where((device) => device.serialNumber == serialNumber).toList().isNotEmpty
        ? weatherdatadevicelist.where((device) => device.serialNumber == serialNumber).first
        : null;
  }
// Find irrigation line by controllerId using .where
  String? findIrrigationLine(int controllerId) {
    int? devicctrlid = deviceFind(controllerId)?.controllerId!;
    var irrigationLine = weatherdatairrigationline.where((line) => line.weatherStation.contains(devicctrlid)).toList();
    return irrigationLine.isNotEmpty ? irrigationLine.first.name : 'All Line';
  }

  Widget gaugeViewWeather(String title, int i, int index) {
    String type = '0';
    String Unit = '0';
    String imageAsserStr = '';
    double Max = 100;
    String value = '${weathernewlive.stations[i].sensors[index].value}';
    String errorStatus = '${weathernewlive.stations[i].sensors[index].errorStatus}';

    Color bgcolor = Colors.transparent;
    if (errorStatus == '1') {
      bgcolor = Colors.red.shade50;
    } else if (errorStatus == '2') {
      bgcolor = Colors.yellow.shade50;
    } else if (errorStatus == '3') {
      bgcolor = Colors.orange.shade50;
    } else {
      bgcolor = Colors.white;
    }

    if (title.contains('Moisture')) {
      type = '1';
      Unit = 'CB';
      Max = 200;
      imageAsserStr = 'assets/mob_dashboard/SoilMoisture.png';
    }  else if (title.contains('Temperature')) {
      type = '2';
      Unit = '°C';
      Max = 100;
      imageAsserStr = 'assets/mob_dashboard/SoilTemp .png';
    }   else if (title.contains('Atmosphere Pressure')) {
      type = '3';
      Unit = 'kPa';
      Max = 2000;
      imageAsserStr = 'assets/mob_dashboard/pressure.png';
    } else if (title.contains('Leaf')) {
      type = '2';
      Unit = '%';
      Max = 100;
      imageAsserStr = 'assets/mob_dashboard/leafWetness.png';
    }
    else if (title.contains('Humidity')) {
      type = '2';
      Unit = '%';
      Max = 100;
      imageAsserStr = 'assets/mob_dashboard/pressure.png';
    }
    else if (title.contains('Co2')) {
      type = '2';
      Unit = 'ppm';
      Max = 1000;
      imageAsserStr = 'assets/mob_dashboard/CO-2.png';
    } else if (title.contains('LDR')) {
      type = '5';
      Unit = 'Lu';
      Max = 100;
      imageAsserStr = 'assets/mob_dashboard/LDR.png';
    } else if (title.contains('LUX')) {
      type = '5';
      Unit = 'Lu';
      Max = 100;
      imageAsserStr = 'assets/mob_dashboard/Lux.png';
    } else if (title.contains('Wind Direction')) {
      type = '7';
      Unit = 'CB';
      Max = 360;
      imageAsserStr = 'assets/mob_dashboard/WindDirection.png';
    } else if (title.contains('Rain Fall')) {
      type = '2';
      Unit = 'mm';
      Max = 100;
      imageAsserStr = 'assets/mob_dashboard/rainFall.png';
    } else if (title.contains('Wind Speed')) {
      type = '3';
      Unit = 'km/h';
      Max = 100;
      imageAsserStr = 'assets/mob_dashboard/WindSpeed.png';
    } else {
      type = '0';
      Unit = '';
      imageAsserStr = 'assets/mob_dashboard/WindSpeed.png';
    }


    // type = '1';
    if (type == "1") {
      return Container(
        color: bgcolor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Image.asset(
                    imageAsserStr,
                    width: 30.0,
                    height: 30.0,
                    // fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 30, width: 150, child: Text('$title',textAlign: TextAlign.center, style: const TextStyle(fontSize: 15,fontWeight: FontWeight.bold))),
              ],
            ),
            Container(height: 200,
                width: 200,
                decoration: BoxDecoration(
                    border: Border.all(width: 0.1),
                    borderRadius: BorderRadius.circular(5)),
                child: SfRadialGauge(
                    backgroundColor: bgcolor,
                    enableLoadingAnimation: true,
                    animationDuration: 1000,
                    // title: GaugeTitle(text: title),
                    axes: <RadialAxis>[
                      RadialAxis(
                          axisLineStyle: const AxisLineStyle(
                              thicknessUnit: GaugeSizeUnit.factor, thickness: 0.25),
                          radiusFactor:   0.8,
                          showTicks: false,
                          showLastLabel: true,
                          maximum: Max,
                          axisLabelStyle: const GaugeTextStyle(),
                          // Added custom axis renderer that extended from RadialAxisRenderer
                          pointers: <GaugePointer>[
                            RangePointer(
                                value: double.parse(value),
                                width: 0.25,
                                sizeUnit: GaugeSizeUnit.factor,
                                color: const Color(0xFF494CA2),
                                animationDuration: 1300,
                                animationType: AnimationType.easeOutBack,
                                gradient: const SweepGradient(
                                    colors: <Color>[Colors.greenAccent,Colors.amber, Color(0xFFE63B86),Colors.redAccent],
                                    stops: <double>[0.30,0.50,1.0,2.0]),
                                enableAnimation: true)
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                                widget: Container(
                                    child: Text('${value} ${Unit}',
                                        style: const TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.bold))),
                                angle: 90,
                                positionFactor: 1.2)
                          ]
                      ),
                    ])),
            // Column(mainAxisAlignment: MainAxisAlignment.start,
            //   children: [
            //     Center(child: SizedBox(height: 20, width: 150, child: MinMAxvalues("Min",'00','00:00:00'))),
            //     Center(child: SizedBox(height: 20, width: 150, child: MinMAxvalues("Max",'00','00:00:00'))),
            //   ],
            // ),

          ],
        ),
      );
    } else if (type == "2") {
      return Container(
        color: bgcolor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Image.asset(
                    imageAsserStr,
                    width: 30.0,
                    height: 30.0,
                    // fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 30, width: 160, child: Text('$title',textAlign: TextAlign.center, style: const TextStyle(fontSize: 14,fontWeight: FontWeight.bold))),
              ],
            ),
            Container(
              height: 180,
              width: 200,
              decoration: BoxDecoration(
                  border: Border.all(width: 0.1),
                  borderRadius: BorderRadius.circular(5)),
              child: SfLinearGauge(
                minimum: 0,
                maximum: Max,
                orientation: LinearGaugeOrientation.vertical,
                markerPointers: [
                  LinearShapePointer(
                    shapeType: LinearShapePointerType.invertedTriangle,
                    color: Colors.green,
                    value: double.parse(value),
                  ),
                ],
                ranges: [
                  LinearGaugeRange(
                    edgeStyle: LinearEdgeStyle.bothCurve,
                    startWidth: 10,
                    endWidth: 10,
                    midWidth: 10,
                    startValue: 0,
                    endValue: double.parse(value),
                  ),

                ],
              ),

            ),
            SizedBox(
                height: 30,
                width: 200,
                child: Text(
                    '$value  $Unit',
                    textAlign: TextAlign.center,   style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold)
                )),
            // Column(mainAxisAlignment: MainAxisAlignment.start,
            //   children: [
            //     Center(child: SizedBox(height: 20, width: 150, child: MinMAxvalues("Min",'00','00:00:00'))),
            //     Center(child: SizedBox(height: 20, width: 150, child: MinMAxvalues("Max",'00','00:00:00'))),
            //   ],
            // ),
          ],
        ),
      );
    } else if (type == "3") {
      return Container(
        color: bgcolor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Image.asset(
                    imageAsserStr,
                    width: 30.0,
                    height: 30.0,
                    // fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 30, width: 160, child: Text('$title',textAlign: TextAlign.center, style: const TextStyle(fontSize: 14,fontWeight: FontWeight.bold))),
              ],
            ),
            Container(height: 200,
                width: 200,
                decoration: BoxDecoration(
                    border: Border.all(width: 0.1),
                    borderRadius: BorderRadius.circular(5)),
                child: SfRadialGauge(
                    backgroundColor: bgcolor,
                    enableLoadingAnimation: true,
                    animationDuration: 1000,
                    axes: <RadialAxis>[
                      RadialAxis(
                          showFirstLabel: true,
                          showLastLabel: true,
                          showLabels: true,
                          majorTickStyle: const MajorTickStyle(
                              length: 7,
                              thickness: 2,
                              lengthUnit: GaugeSizeUnit.logicalPixel,
                              color: Colors.deepOrangeAccent),
                          canScaleToFit: true,
                          minimum: 0,
                          maximum: Max,
                          ranges: <GaugeRange>[
                            GaugeRange(
                                startValue: 0,
                                endValue: (40 / 100) * Max,
                                color: Colors.green),
                            GaugeRange(
                                startValue: (40 / 100) * Max,
                                endValue: (60 / 100) * Max,
                                color: Colors.yellow),
                            GaugeRange(
                                startValue: (60 / 100) * Max,
                                endValue: (80 / 100) * Max,
                                color: Colors.orange),
                            GaugeRange(
                                startValue: (80 / 100) * Max,
                                endValue: (100 / 100) * Max,
                                color: Colors.red)
                          ],
                          pointers: <GaugePointer>[
                            NeedlePointer(
                              value: double.parse(value),
                              needleLength: 0.7,
                              needleEndWidth: 5,
                              needleStartWidth: 0.8,
                              tailStyle: const TailStyle(
                                width: 5,
                              ),
                            )
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                                widget: Container(
                                    child: Text('${value} ${Unit}',
                                        style: const TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.bold))),
                                angle: 90,
                                positionFactor: 0.9)
                          ])
                    ])),
            // Column(mainAxisAlignment: MainAxisAlignment.start,
            //   children: [
            //     Center(child: SizedBox(height: 20, width: 150, child: MinMAxvalues("Min",'00','00:00:00'))),
            //     Center(child: SizedBox(height: 20, width: 150, child: MinMAxvalues("Max",'00','00:00:00'))),
            //   ],
            // ),
          ],
        ),
      );
    } else if (type == "7") {//winddirection
      return Container(
        color: bgcolor,
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Image.asset(
                    imageAsserStr,
                    width: 30.0,
                    height: 30.0,
                    // fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 30, width: 150, child: Text('$title',textAlign: TextAlign.center, style: const TextStyle(fontSize: 14,fontWeight: FontWeight.bold))),
              ],
            ),
            Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                    border: Border.all(width: 0.1),
                    borderRadius: BorderRadius.circular(5)),
                child: SfRadialGauge(

                    backgroundColor: bgcolor,
                    enableLoadingAnimation: true,
                    animationDuration: 1000,
                    axes: <RadialAxis>[
                      RadialAxis(
                          backgroundImage: const AssetImage('assets/mob_dashboard/compass.png'),
                          radiusFactor: 1,
                          canRotateLabels: true,
                          offsetUnit: GaugeSizeUnit.factor,
                          onLabelCreated: handleAxisLabelCreated,
                          startAngle: 270,
                          endAngle: 270,
                          maximum: 360,
                          interval: 30,
                          minorTicksPerInterval: 4,

                          showAxisLine: false,
                          showFirstLabel: false,
                          showLastLabel: false,
                          showLabels: false,
                          canScaleToFit: false,
                          showTicks: false,
                          minimum: 0,
                          ranges: <GaugeRange>[],
                          pointers: <GaugePointer>[
                            MarkerPointer(
                              value: double.parse(value),
                              color: Colors.redAccent,
                              enableAnimation: true,
                              animationDuration: 1200,
                              markerOffset: 0.62,
                              offsetUnit: GaugeSizeUnit.factor,
                              markerType: MarkerType.triangle,
                              markerHeight: 70,
                              markerWidth: 15,
                            ),
                            MarkerPointer(
                              value: double.parse(value) < 180 ? double.parse(value) + 180 : double.parse(value) - 180,
                              color: Colors.grey,
                              enableAnimation: true,
                              animationDuration: 1200,
                              markerOffset: 0.60,
                              offsetUnit: GaugeSizeUnit.factor,
                              markerType: MarkerType.triangle,
                              markerHeight: 70,
                              markerWidth: 15,
                            )

                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                                widget: Container(
                                    child: Text(degreeToDirection(value),
                                        style: const TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.bold))),
                                angle: 90,
                                positionFactor: 1.1)
                          ]
                      ),

                    ])),
          ],
        ),
      );
    } else {
      return Container(
        color: bgcolor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Image.asset(
                    imageAsserStr,
                    width: 30.0,
                    height: 30.0,
                    // fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 30, width: 150, child: Text('$title',textAlign: TextAlign.center, style: const TextStyle(fontSize: 14,fontWeight: FontWeight.bold))),
              ],
            ),
            Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                    border: Border.all(width: 0.1),
                    borderRadius: BorderRadius.circular(5)),
                child: SfRadialGauge(
                    backgroundColor: bgcolor,
                    enableLoadingAnimation: true,
                    animationDuration: 1000,
                    axes: <RadialAxis>[
                      RadialAxis(
                          showFirstLabel: true,
                          showLastLabel: true,
                          showLabels: true,
                          majorTickStyle: const MajorTickStyle(
                              length: 7,
                              thickness: 2,
                              lengthUnit: GaugeSizeUnit.logicalPixel,
                              color: Colors.deepOrangeAccent),
                          canScaleToFit: true,
                          minimum: 0,
                          maximum: Max,
                          ranges: <GaugeRange>[
                            GaugeRange(
                                startValue: 0,
                                endValue: (40 / 100) * Max,
                                color: Colors.green),
                            GaugeRange(
                                startValue: (40 / 100) * Max,
                                endValue: (60 / 100) * Max,
                                color: Colors.yellow),
                            GaugeRange(
                                startValue: (60 / 100) * Max,
                                endValue: (80 / 100) * Max,
                                color: Colors.orange),
                            GaugeRange(
                                startValue: (80 / 100) * Max,
                                endValue: (100 / 100) * Max,
                                color: Colors.red)
                          ],
                          pointers: <GaugePointer>[
                            NeedlePointer(
                              value: double.parse(value),
                              needleLength: 0.7,
                              needleEndWidth: 5,
                              needleStartWidth: 0.8,
                              tailStyle: const TailStyle(
                                width: 5,
                              ),
                            )
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                                widget: Container(
                                    child: Text('${value} ${Unit}',
                                        style: const TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.bold))),
                                angle: 90,
                                positionFactor: 0.9)
                          ])
                    ])),
            // Center(child: SizedBox(height: 20, width: 150, child: MinMAxvalues("Min",'00','00:00:00'))),
            // Center(child: SizedBox(height: 20, width: 150, child: MinMAxvalues("Max",'00','00:00:00'))),
          ],
        ),
      );
    }
  }
  Widget MinMAxvalues(String M,String Mval,String Mtime )
  {
    return Column(mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20, width: 150, child: RichText(
          text:   TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: '$M: ',
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
              TextSpan(
                text: '$Mval',
                style: const TextStyle(color: Colors.red, fontSize: 14,fontWeight: FontWeight.bold),
              ),

              TextSpan(
                text: '\t\t$Mtime',
                style: TextStyle(color: Theme.of(context).primaryColorDark, fontSize: 14,fontWeight: FontWeight.w100),
              ),

            ],
          ),
        ), ),
      ],
    );
  }
  static String degreeToDirection(String degreestr) {
    print('degreestr$degreestr');
    String cleanedString = degreestr.replaceAll('º', '').trim();
    double degree = double.parse(degreestr);
    if ((degree >= 337.5 && degree <= 360) || (degree >= 0.0 && degree < 22.5)) {
      return 'North';
    } else if (degree >= 22.5 && degree < 67.5) {
      return 'NorthEast';
    } else if (degree >= 67.5 && degree < 112.5) {
      return 'East';
    } else if (degree >= 112.5 && degree < 157.5) {
      return 'SouthEast';
    } else if (degree >= 157.5 && degree < 202.5) {
      return 'South';
    } else if (degree >= 202.5 && degree < 247.5) {
      return 'SouthWest';
    } else if (degree >= 247.5 && degree < 292.5) {
      return 'West';
    } else if (degree >= 292.5 && degree < 337.5) {
      return 'NorthWest';
    } else {
      return degreestr;
    }
  }
  void handleAxisLabelCreated(AxisLabelCreatedArgs args) {
    if (args.text == '90') {
      args.text = 'E';
      args.labelStyle = const GaugeTextStyle(
        color: Color(0xFFDF5F2D),
        fontSize: 10,
      );
    } // Gauge TextStyle
    else if (args.text == '360') {
      args.text = '';
    } else {
      if (args.text == '0') {
        args.text = 'N';
      } else if (args.text == '180') {
        args.text = 'S';
      } else if (args.text == '270') {
        args.text = 'W';
      }
      args.labelStyle =
      const GaugeTextStyle(color: Color(0xFFFFFFFF), fontSize: 10);
    }
  }
  Request() {
    String payLoadFinal = jsonEncode({
      "5000":
      {"5001": ""},

    });
    manager.topicToPublishAndItsMessage(
        payLoadFinal, '${Environment.mqttPublishTopic}/${widget.deviceID}');
   }
  // TODO: implement widget
  Future<void> fetchDataSunRiseSet() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.sunrisesunset.io/json?lat=11.0168&lng=77.9558'));
      if (response.statusCode == 200) {
        weatherData = json.decode(response.body);
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
      DateTime nowDate = DateTime.now();
      String day = DateFormat('EEE').format(nowDate);

      int indexOfThu = weekDayList.indexOf(day); // 3

      weekDayList = [
        ...weekDayList.sublist(indexOfThu),
        ...weekDayList.sublist(0, indexOfThu),
      ];
    } catch (e) {
      print('Exception: $e');
    }
  }
  void fetchDataLive() async {
    print("getData");
    try
    {
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.getweather({
        "userId": widget.userId ?? 4,
        "controllerId": widget.controllerId ?? 1

      });

      final jsonData = jsonDecode(getUserDetails.body);
      print('jsonData  fetch device  ${jsonData['data']['deviceList']}');
      print('jsonData  fetch irrigationLine ${jsonData['data']['irrigationLine']}');
      if (jsonData['code'] == 200) {
        setState(() {
          weathernewlive = WeatherData.fromJson(jsonData);
          // weatherdatairrigationline = IrrigationLine.fromJson(jsonData['data']['irrigationLine']);
          // weatherdatadevicelist = Device.fromJson(jsonData['data']['deviceList']);
          weatherdatairrigationline = List<IrrigationLine>.from(
            jsonData['data']['irrigationLine'].map((data) => IrrigationLine.fromJson(data)),
          );

          // Parse devices as a List of Device objects
          weatherdatadevicelist = List<DeviceW>.from(
            jsonData['data']['deviceList'].map((data) => DeviceW.fromJson(data)),
          );

          weatherdataconfigobjects = List<ConfigObjectWeather>.from(
            jsonData['data']['configObject'].map(
                  (data) => ConfigObjectWeather.fromJson(data),
            ),
          );


        });
      }
    } catch (e, stackTrace) {
      print(' trace overAll getData  => ${stackTrace}');
    }
  }
}