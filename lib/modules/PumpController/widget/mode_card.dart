import 'package:flutter/material.dart';

/// The three possible pump modes.
enum PumpMode { auto, manual/*, idle*/ }

extension PumpModeX on PumpMode {
  String get label {
    switch (this) {
      case PumpMode.auto:
        return 'Auto Mode';
      case PumpMode.manual:
        return 'Manual Mode';
    // case PumpMode.idle:
    //   return 'Idle';
    }
  }

  /// Solid color used for the card background / popup option background.
  Color get color {
    switch (this) {
      case PumpMode.auto:
        return const Color(0xFF2F80ED); // blue
      case PumpMode.manual:
        return const Color(0xFF27AE60); // green
    // case PumpMode.idle:
    //   return const Color(0xFF9E9E9E); // grey
    }
  }

  IconData get icon {
    switch (this) {
      case PumpMode.auto:
        return Icons.autorenew;
      case PumpMode.manual:
        return Icons.pan_tool_alt;
    // case PumpMode.idle:
    //   return Icons.pause_circle_outline;
    }
  }

  /// Adjust this mapping to match whatever string codes your
  /// backend/payload actually sends (e.g. "0", "1", "2" or
  /// "MANUAL", "AUTO", "IDLE"...).
  static PumpMode fromStatus(String status) {
    switch (status.toUpperCase()) {
      case '0':
      case 'MANUAL':
        return PumpMode.manual;
      case '1':
      case 'AUTO':
        return PumpMode.auto;
    // case '2':
    // case 'IDLE':
    //   return PumpMode.idle;
      default:
        return PumpMode.manual; // Defaulting to manual instead of idle
    }
  }

  /// The raw code you send back out in the SMS/MQTT payload.
  String get statusCode {
    switch (this) {
      case PumpMode.auto:
        return 'OFF';
      case PumpMode.manual:
        return 'ON';
    // case PumpMode.idle:
    //   return 'IDLE';
    }
  }
}

/// Card that shows the current mode and opens a popup to change it.
Widget buildModeCard({
  required String modeStatus, // raw value from your live payload
  required Function(PumpMode) onModeSelected,
  required String pumpName,
  bool isLoading = false,
  required BuildContext context,
}) {
  final PumpMode currentMode = PumpModeX.fromStatus(modeStatus);

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: currentMode.color.withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        // Container color depends on the current mode.
        color: currentMode.color,
        child: InkWell(
          onTap: isLoading
              ? null
              : () => _showModePickerDialog(
            context: context,
            currentMode: currentMode,
            onModeSelected: onModeSelected,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Pump info with live indicator
                Expanded(
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentMode == PumpMode.manual ? 'Mobile Mode' : currentMode.label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // text color white
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  currentMode.icon,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentMode.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white, // text color white
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right side - loading or chevron to indicate "tap to change"
                isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(
                  Icons.expand_more,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Popup shown on tap, letting the user choose Auto / Manual / Idle.
/// Each option's container color matches its mode, with white text.
void _showModePickerDialog({
  required BuildContext context,
  required PumpMode currentMode,
  required Function(PumpMode) onModeSelected,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Select Mode',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...PumpMode.values.map((mode) {
                final bool isSelected = mode == currentMode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: mode.color,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        if (!isSelected) {
                          onModeSelected(mode);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(mode.icon, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                mode.label,
                                style: const TextStyle(
                                  color: Colors.white, // text color white
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}