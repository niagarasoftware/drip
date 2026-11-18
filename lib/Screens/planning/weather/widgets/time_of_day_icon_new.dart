import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Screens/planning/weather/widgets/time_icon_new.dart';

class TimeOfDayIconNew extends StatelessWidget {
  final String time;

  const TimeOfDayIconNew({
    super.key,
    required this.time,
  });

  int get hour {
    if (!time.contains(':')) return 0;
    return int.tryParse(time.split(':').first) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (hour >= 5 && hour < 12) {
      return const TimeIconNew(
        icon: Icons.wb_twilight,
        gradient: RadialGradient(
          colors: [
            Color(0xFFFFF9C4),
            Color(0xFFFFC107),
            Color(0xFFFF8F00),
          ],
        ),
        glowColor: Colors.orange,
      );
    } else if (hour >= 12 && hour < 17) {
      return const TimeIconNew(
        icon: Icons.wb_sunny,
        gradient: RadialGradient(
          colors: [
            Color(0xFFFFFDE7),
            Color(0xFFFFEB3B),
            Color(0xFFFFC107),
          ],
        ),
        glowColor: Colors.yellow,
      );
    } else if (hour >= 17 && hour < 19) {
      return const TimeIconNew(
        icon: Icons.wb_twilight,
        gradient: RadialGradient(
          colors: [
            Color(0xFFFFE0B2),
            Color(0xFFFF8A65),
            Color(0xFFD84315),
          ],
        ),
        glowColor: Colors.deepOrange,
      );
    } else {
      return const TimeIconNew(
        icon: Icons.nights_stay,
        gradient: RadialGradient(
          colors: [
            Color(0xFFB39DDB),
            Color(0xFF5E35B1),
            Color(0xFF311B92),
          ],
        ),
        glowColor: Colors.deepPurple,
      );
    }
  }
}