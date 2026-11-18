import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class PolygonAreaCalculator {
  PolygonAreaCalculator._();

  static const double sqMetersPerAcre = 4046.8564224;
  static const double sqMetersPerCent = 40.468564224;
  static const double sqFeetPerSqMeter = 10.76391041671;

  // Google Earth reference values for debugging only.
  // These values are NOT used in area calculation.
  static const double googleEarthReferenceAcres = 0.71;
  static const double googleEarthReferencePerimeter = 216.09;

  /// Check whether GPS coordinates are valid.
  static bool _isValidPoint(gmaps.LatLng point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }

  /// Compare two GPS coordinates.
  static bool _samePoint(
      gmaps.LatLng a,
      gmaps.LatLng b,
      ) {
    return a.latitude == b.latitude &&
        a.longitude == b.longitude;
  }

  /// Prepare polygon coordinates without modifying original points.
  static List<gmaps.LatLng> _normalizePoints(
      List<gmaps.LatLng> points,
      ) {
    if (points.isEmpty) return [];

    // Reject invalid coordinates instead of silently removing vertices.
    for (int i = 0; i < points.length; i++) {
      if (!_isValidPoint(points[i])) {
        if (kDebugMode) {
          debugPrint(
            'PolygonAreaCalculator -> '
                'Invalid coordinate at index $i: ${points[i]}',
          );
        }
        return [];
      }
    }

    final normalized = List<gmaps.LatLng>.from(points);

    // Remove duplicate closing coordinates.
    while (normalized.length > 1 &&
        _samePoint(normalized.first, normalized.last)) {
      normalized.removeLast();
    }

    // Remove consecutive duplicate coordinates.
    final unique = <gmaps.LatLng>[];

    for (final point in normalized) {
      if (unique.isEmpty || !_samePoint(unique.last, point)) {
        unique.add(point);
      }
    }

    return unique;
  }

  /// Convert google_maps_flutter coordinates to maps_toolkit.
  static List<mp.LatLng> _toToolkitPoints(
      List<gmaps.LatLng> points,
      ) {
    return _normalizePoints(points)
        .map(
          (point) => mp.LatLng(
        point.latitude,
        point.longitude,
      ),
    )
        .toList();
  }

  /// Calculate polygon area in square meters.
  static double calculateSquareMeters(
      List<gmaps.LatLng> points,
      ) {
    final toolkitPoints = _toToolkitPoints(points);

    if (toolkitPoints.length < 3) {
      if (kDebugMode) {
        debugPrint(
          'PolygonAreaCalculator -> '
              'Invalid polygon: minimum 3 points required. '
              'Received ${toolkitPoints.length}.',
        );
      }
      return 0.0;
    }

    try {
      final area =
      mp.SphericalUtil.computeArea(toolkitPoints).toDouble();

      if (!area.isFinite || area < 0) {
        if (kDebugMode) {
          debugPrint(
            'PolygonAreaCalculator -> Invalid area result: $area',
          );
        }
        return 0.0;
      }

      if (kDebugMode) {
        debugPrint(
          'PolygonAreaCalculator -> '
              'Points: ${toolkitPoints.length}, '
              'Square meters: ${area.toStringAsFixed(6)}',
        );
      }

      return area;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'PolygonAreaCalculator -> Area calculation error: $e',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      return 0.0;
    }
  }

  /// Calculate polygon area in acres.
  static double calculateAcres(
      List<gmaps.LatLng> points,
      ) {
    final squareMeters = calculateSquareMeters(points);
    final acres = squareMeters / sqMetersPerAcre;

    if (kDebugMode) {
      debugPrint(
        'PolygonAreaCalculator -> '
            '${squareMeters.toStringAsFixed(4)} m² = '
            '${acres.toStringAsFixed(6)} acres',
      );
    }

    return acres;
  }

  /// Calculate polygon area in cents.
  static double calculateCents(
      List<gmaps.LatLng> points,
      ) {
    final squareMeters = calculateSquareMeters(points);
    final cents = squareMeters / sqMetersPerCent;

    if (kDebugMode) {
      debugPrint(
        'PolygonAreaCalculator -> '
            '${squareMeters.toStringAsFixed(4)} m² = '
            '${cents.toStringAsFixed(6)} cents',
      );
    }

    return cents;
  }

  /// Calculate polygon area in square feet.
  static double calculateSquareFeet(
      List<gmaps.LatLng> points,
      ) {
    final squareMeters = calculateSquareMeters(points);
    final squareFeet = squareMeters * sqFeetPerSqMeter;

    if (kDebugMode) {
      debugPrint(
        'PolygonAreaCalculator -> '
            '${squareMeters.toStringAsFixed(4)} m² = '
            '${squareFeet.toStringAsFixed(4)} ft²',
      );
    }

    return squareFeet;
  }

  /// Calculate complete polygon perimeter in meters.
  static double calculatePerimeterMeters(
      List<gmaps.LatLng> points,
      ) {
    final toolkitPoints = _toToolkitPoints(points);

    if (toolkitPoints.length < 3) return 0.0;

    try {
      final closedPath = <mp.LatLng>[
        ...toolkitPoints,
        toolkitPoints.first,
      ];

      final perimeter =
      mp.SphericalUtil.computeLength(closedPath).toDouble();

      if (!perimeter.isFinite || perimeter < 0) {
        return 0.0;
      }

      if (kDebugMode) {
        debugPrint(
          'PolygonAreaCalculator -> '
              'Perimeter: ${perimeter.toStringAsFixed(4)} meters',
        );
      }

      return perimeter;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'PolygonAreaCalculator -> Perimeter error: $e',
        );
      }
      return 0.0;
    }
  }


}