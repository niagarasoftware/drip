import 'package:flutter/material.dart';

class AppInfo extends StatelessWidget {
  const AppInfo({super.key});


  @override
  Widget build(BuildContext context) {
    const String irrigationInfo = '''
🌾 About This Irrigation Automation System

Smart Irrigation Automation is an intelligent solution designed to efficiently manage water and fertilizer delivery in agricultural fields, gardens, and landscaping systems. It reduces manual effort, optimizes water usage, and improves crop yield by automating key components like valves, filters, and fertilizer injectors.

🔧 Key Components and Features

💧 Automated Valves:
- Control water flow to different zones (drip lines, sprinklers).
- Operate automatically based on schedule or tank level.
- Can be manually controlled through the app.

🧼 Filter Monitoring and Backwash:
- Detects filter clogging based on pressure or flow.
- Automatically triggers backwash to clean the filter.
- Protects pumps, valves, and crops from damage.

🌿 Fertilizer Dosing System:
- Delivers nutrients through venturi or dosing pump injectors.
- Schedule or sensor-based fertigation control.
- Ensures proper nutrition for different crop stages.

📅 Irrigation Scheduling:
- Supports daily, weekly, or condition-based schedules.
- Works with tank levels, rain sensors, and soil moisture.
- Fully customizable through the app.

📲 Remote Monitoring and Control:
- View live status of pumps, valves, filters, fertilizer injectors and sensor current values.
- Receive alerts and warnings (low water, blockages, errors).
- Control your farm from anywhere using your phone.

✅ Benefits:
- Saves water and labor.
- Ensures consistent crop health.
- Increases efficiency and reduces manual work.
- Enables remote access and full automation.

📌 Example Use Case:
A farmer manages multiple irrigation zones at a time with automatic solenoid valves. The system includes a pressure filter that cleans itself when dirty. Fertilizer is injected automatically every 2 days during growth season. The entire system is controlled via a mobile app with live feedback.

For more support, contact: support@niagaraautomation.com
''';
    return Scaffold(
      appBar: AppBar(title: const Text('Irrigation System Info')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            irrigationInfo,
            style: TextStyle(fontSize: 14.5, height: 1.5),
          ),
        ),
      ),
    );
  }
}