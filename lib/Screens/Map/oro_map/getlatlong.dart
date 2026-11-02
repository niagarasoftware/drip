

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

Future<LatLng?> getLatLngFromInput(String input) async {
  AppLog.log("getLatLngFromInput call");
  try {
    input = input.trim();
    if (input.isEmpty) return null;

    // 1️⃣ Google Maps URL (@lat,long)
    final regExp = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
    final match = regExp.firstMatch(input);

    if (match != null) {
      final lat = double.parse(match.group(1)!);
      final long = double.parse(match.group(2)!);
      return LatLng(lat, long);
    }

    // 2️⃣ Direct lat,long
    if (input.contains(",")) {
      final coords = input.split(",");
      if (coords.length == 2) {
        final lat = double.parse(coords[0].trim());
        final long = double.parse(coords[1].trim());
        return LatLng(lat, long);
      }
    }

    final dmsRegExp = RegExp(
      r"(\d+)[°\s]+(\d+)['\s]+(\d+(?:\.\d+)?)[""'s]*([NSEW])",
      caseSensitive: false,
    );

   final matches = dmsRegExp.allMatches(input).toList();

  if (matches.length == 2) {
  double parseDMS(RegExpMatch m) {
  final degrees = double.parse(m.group(1)!);
  final minutes = double.parse(m.group(2)!);
  final seconds = double.parse(m.group(3)!);
  final direction = m.group(4)!.toUpperCase();

  double decimal = degrees + (minutes / 60) + (seconds / 3600);

  if (direction == 'S' || direction == 'W') {
  decimal *= -1;
  }

  return decimal;
  }

  final lat = parseDMS(matches[0]);
  final lng = parseDMS(matches[1]);

  return LatLng(lat, lng);
  }

    // 3️⃣ Area name → Google Geocoding API
    // final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    const apiKey = 'AIzaSyCVcK18rhs06E0rP7QAyOY8J_35CbZpBlw';
    AppLog.log("apiKey $apiKey");
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?address=$input&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);
    AppLog.log('data:$data');
    if (data["status"] == "OK") {
      final location = data["results"][0]["geometry"]["location"];
      return LatLng(location["lat"], location["lng"]);
    }

    return null;

  } catch (e) {
    AppLog.log("Location parse error: $e");
    return null;
  }
}

