import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String _apiKey = '440faba4d67293ec99cb1ed8d9951478';
  final String _weatherUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String _forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  Future<Map<String, dynamic>> fetchWeather({String? city, double? lat, double? lon}) async {
    Uri uri;
    if (city != null && city.isNotEmpty) {
      uri = Uri.parse('$_weatherUrl?q=$city&appid=$_apiKey&units=metric');
    } else if (lat != null && lon != null) {
      uri = Uri.parse('$_weatherUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');
    } else {
      throw Exception('Provide either a city name or coordinates');
    }

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'statusCode': '${response.statusCode}',
        'temperature': data['main']['temp'],
        'humidity': data['main']['humidity'],
        'rainfall': data['rain'] != null ? data['rain']['1h'] ?? 0.0 : 0.0,
        'wind_speed': data['wind']['speed'],
        'wind_direction': data['wind']['deg'],
        'cloud_cover': data['clouds']['all'],
        'pressure': data['main']['pressure'],
      };
    } else {
      //throw Exception('Failed to fetch weather data: ${response.statusCode}');

      final data = jsonDecode(response.body);
      final code = data['cod'];
      final message = data['message'];

      return  {
        'statusCode': code,
        'message': message,
      };
    }
  }

  Future<List<Map<String, dynamic>>> fetchWeatherForecast({String? city, double? lat, double? lon}) async {
    Uri uri;
    if (city != null && city.isNotEmpty) {
      uri = Uri.parse('$_forecastUrl?q=$city&appid=$_apiKey&units=metric');
    } else if (lat != null && lon != null) {
      uri = Uri.parse('$_forecastUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');
    } else {
      throw Exception('Provide either a city name or coordinates');
    }

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Map<String, dynamic>> forecast = [];
      for (var item in data['list']) {
        forecast.add({
          'timestamp': item['dt'],
          'temperature': item['main']['temp'],
          'humidity': item['main']['humidity'],
          'rainfall': item['rain'] != null ? item['rain']['3h'] ?? 0.0 : 0.0,
          'wind_speed': item['wind']['speed'],
          'cloud_cover': item['clouds']['all'],
        });
      }
      return forecast;
    } else {
      throw Exception('Failed to fetch forecast data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchSoilData({required double lat, required double lon}) async {
    throw UnimplementedError('Soil data integration not implemented');
  }
}