import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Screens/planning/weather/view_model/weather_view_model.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../widgets/crop_air_quality_card.dart';
import '../widgets/crop_hourly_weather_card.dart';
import '../widgets/crop_rainfall_card.dart';
import '../widgets/crop_weather_header.dart';
import '../widgets/crop_weather_info_card.dart';
import '../widgets/crop_wind_details_card.dart';

class CropWeatherscreen extends StatefulWidget {
  final int userId;
  final int controllerId;

  const CropWeatherscreen({super.key, required this.userId, required this.controllerId});

  @override
  State<CropWeatherscreen> createState() => _CropWeatherscreenState();
}

class _CropWeatherscreenState extends State<CropWeatherscreen> {
  final ScrollController _controller = ScrollController();
  static const double itemWidth = 110;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final screenWidth = MediaQuery.of(context).size.width;

      final offset = (DateTime.now().hour * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

      if (_controller.hasClients) {
        _controller.jumpTo(
          offset.clamp(0.0, _controller.position.maxScrollExtent),
        );
      }
    });
  }


  double getTemperature(int hour) {
    // Peak around 2 PM (14:00)
    const minTemp = 22;
    const maxTemp = 33;

    final radians = ((hour - 2) / 24) * 2 * pi;

    return minTemp +
        ((sin(radians - pi / 2) + 1) / 2) *
            (maxTemp - minTemp);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WeatherViewModel(Repository(HttpService()))
        ..fetchWeatherData(widget.userId, widget.controllerId),
      child: Consumer<WeatherViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoadingWeather) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (vm.weatherModel == null || !vm.hasAnyWeatherStation) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("No weather station data available"),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => vm.fetchWeatherData(widget.userId, widget.controllerId),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          }

          final device = vm.selectedDevice;
          final controllerId = device?.controllerId ?? widget.controllerId;

          final temp = vm.getSensorLiveBySerial(
            serial: device?.serialNumber ?? 0,
            objectName: "Temperature Sensor",
            controllerId: controllerId,
          );

          final humidity = vm.getSensorLiveBySerial(
            serial: device?.serialNumber ?? 0,
            objectName: "Humidity Sensor",
            controllerId: controllerId,
          );

          final windSpeed = vm.getSensorLiveBySerial(
            serial: device?.serialNumber ?? 0,
            objectName: "Wind Speed Sensor",
            controllerId: controllerId,
          );

          final windDir = vm.getSensorLiveBySerial(
            serial: device?.serialNumber ?? 0,
            objectName: "Wind Direction Sensor",
            controllerId: controllerId,
          );

          final rainFall = vm.getSensorLiveBySerial(
            serial: device?.serialNumber ?? 0,
            objectName: "Rain Fall Sensor",
            controllerId: controllerId,
          );

          final co2 = vm.getSensorLiveBySerial(
            serial: device?.serialNumber ?? 0,
            objectName: "Co2 Sensor",
            controllerId: controllerId,
          );

          final tempText = temp == null ? "--" : "${temp.value.toStringAsFixed(1)}°";
          final humidityText = humidity == null ? "No Data" : "${humidity.value.toStringAsFixed(1)} %";
          final windSpeedText = windSpeed == null ? "No Data" : "${windSpeed.value.toStringAsFixed(1)} km/h";
          final windDirText = windDir == null ? "No Data" : "${windDir.value.toStringAsFixed(1)}°";
          final rainFallText = rainFall == null || rainFall.value == 0 ? "0" : rainFall.value.toStringAsFixed(1);
          final co2Text = co2 == null ? "No Data" : co2.value.toStringAsFixed(1);

          final now = DateTime.now();

          return Scaffold(
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () => vm.fetchWeatherData(widget.userId, widget.controllerId),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.network(
                          'https://oroprodblob.blob.core.windows.net/images/1780744311762-crop_image.jpg',
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error);
                          },
                        ),
                      ),
                      WeatherHeader(temp: tempText),
                      const SizedBox(height: 20),
                      WeatherInfoCard(humm: humidityText, rain: rainFallText, wind: windSpeedText),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Text(
                            "Today",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(width: 20),
                          Text(
                            "Tomorrow",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(width: 20),
                          Text(
                            "Next 7 Days",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          controller: _controller,
                          scrollDirection: Axis.horizontal,
                          itemCount: 24,
                          itemBuilder: (context, index) {
                            final isCurrentHour = index == now.hour;
                            final temp = getTemperature(index).round();

                            final hourVal = isCurrentHour ?  tempText : temp;
                            final displayTime = "${index % 12 == 0 ? 12 : index % 12} ${index >= 12 ? "pm" : "am"}";

                            return SizedBox(
                              width: 110,
                              child: HourlyWeatherCard(
                                time: displayTime,
                                temp: '$hourVal°',
                                isHour: isCurrentHour,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: AirQualityCard(co2: co2Text)),
                          const SizedBox(width: 12),
                          Expanded(child: CropRainfallCard(rainfall: rainFallText)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      WindDetailsCard(
                        direction: windDirText,
                        speed: windSpeedText,
                        gust: "0",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}