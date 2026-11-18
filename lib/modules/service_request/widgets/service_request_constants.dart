import 'package:flutter/material.dart';

class ServiceRequestPalette {
  static const primary = Color(0xFF036666);
  static const primarySoft = Color(0xFFE4F1F1);
  static const ink = Color(0xFF111827);
  static const inkSoft = Color(0xFF374151);
  static const muted = Color(0xFF6B7280);
  static const mutedLight = Color(0xFF9CA3AF);
  static const border = Color(0xFFEEF0F2);
  static const canvas = Color(0xFFFCFCFB);
  static const panel = Color(0xFFF7FAFA);
  static const field = Color(0xFFF7F8FA);

  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFC2410C);
  static const warningBg = Color(0xFFFFEEDD);
  static const pending = Color(0xFF475569);
  static const pendingBg = Color(0xFFEEF1F4);
}

const radiusSm = 10.0;
const radiusMd = 14.0;
const radiusLg = 20.0;

class ServiceRequestStatusStyle {
  final Color fg;
  final Color bg;
  const ServiceRequestStatusStyle(this.fg, this.bg);

  static const pending = ServiceRequestStatusStyle(ServiceRequestPalette.pending, ServiceRequestPalette.pendingBg);
  static const inProgress = ServiceRequestStatusStyle(ServiceRequestPalette.warning, ServiceRequestPalette.warningBg);
  static const closed = ServiceRequestStatusStyle(ServiceRequestPalette.success, ServiceRequestPalette.successBg);

  static ServiceRequestStatusStyle of(String status) {
    switch (status) {
      case 'Closed':
        return closed;
      case 'In progress':
        return inProgress;
      default:
        return pending;
    }
  }
}

class ServiceRequestHandlerAccents {
  static const List<Color> _colors = [
    ServiceRequestPalette.primary,
    Color(0xFF7C3AED), // violet
    Color(0xFF2563EB), // blue
    Color(0xFFC2410C), // amber/orange
    Color(0xFF0891B2), // cyan
  ];
  static Color of(int index) => _colors[index % _colors.length];
}
