import 'dart:convert';

import '../repository/repository.dart';
import '../services/http_service.dart';
import '../services/weather_service.dart';
import '../services/ai_service.dart';

import 'package:flutter/foundation.dart';

import '../utils/my_function.dart'; // for ValueNotifier

class AiAdvisoryService {
  final Repository _repository = Repository(HttpService());
  final ValueNotifier<Map<String, dynamic>?> aiResponseNotifier = ValueNotifier(null);

  Future<void> getAdvisory({
    required int userId,
    required int controllerId,
  }) async {
    try {
      final body = {
        "userId": userId,
        "controllerId": controllerId,
      };

      final response = await _repository.fetchSiteAiAdvisoryData(body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["code"] == 200) {
          final data = jsonData['data'];

          if (data != null && data.isNotEmpty) {
            final weatherData = await WeatherService().fetchWeather(city: data['location']);


            aiResponseNotifier.value = null;

            if (weatherData['statusCode'] == '404') {
              print('Error: ${weatherData['message']}');

              aiResponseNotifier.value = {
                'percentage': 0,
                'reason': '${weatherData['message']}',
              };

            } else {
              final params = IrrigationParams(
                cropType: data['cropName'],
                soilType: data['soilType'],
                moistureLevel: 'unknown',
                weather: '${weatherData['rainfall']}',
                area: data['fieldArea'],
                growthStage: data['stage'],
                temperature: '${weatherData['temperature']}',
                humidity: '${weatherData['humidity']}',
                windSpeed: '${weatherData['wind_speed']}',
                windDirection: '${weatherData['wind_direction']}',
                cloudCover: '${weatherData['cloud_cover']}',
                pressure: '${weatherData['pressure']}',
                recentRainfall: '${weatherData['rainfall']}',
                irrigationMethod: data['irrigationType'],
              );

              final prompt = params.toPrompt();

              try {
                final aiResponse = await AIService().sendTextToAI(prompt, "English");
                final lines = aiResponse.trim().split('\n');

                final percent = extractPercentageOnly(lines[0]);
                final reason = lines.skip(1).join('\n').trim();

                if (percent != null) {
                  aiResponseNotifier.value = {
                    'percentage': percent,
                    'reason': reason,
                  };
                } else {
                  aiResponseNotifier.value = {
                    'error': '⚠️ Could not extract irrigation percentage.',
                  };
                }
              } catch (e) {
                aiResponseNotifier.value = {
                  'error': '❌ Error fetching AI advisory.',
                };
              }
            }
          }
        }
      }
    } catch (e) {
      print('Failed to load advisory: $e');
    }
  }

  /// helper to extract percent
  int? extractPercentageOnly(String input) {
    final match = RegExp(r'(\d+)%').firstMatch(input);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}