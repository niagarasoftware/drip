import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../services/communication_service.dart';

class ProgramPreview extends StatefulWidget {
  const ProgramPreview({super.key, required this.isNarrow});
  final bool isNarrow;

  @override
  State<ProgramPreview> createState() => _ProgramPreviewState();
}

class _ProgramPreviewState extends State<ProgramPreview> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final payload = jsonEncode({"sentSms": "program_view"});
      await context.read<CommunicationService>().sendCommand(
        serverMsg: '',
        payload: payload,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Program preview", style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text("Program",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),

              Selector<MqttPayloadProvider, String?>(
                selector: (_, provider) => provider.getProgramPreview(),
                builder: (_, status, __) {

                  if (status == null) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Skeletonizer(
                        enabled: true,
                        child: Column(
                          children: List.generate(14, (index) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(width: 130, height: 20,
                                  color: Colors.grey),
                              ),
                              trailing: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(width: 130, height: 20,
                                  color: Colors.grey),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  }

                  final List<String> items = status.split(',').map((e) => e.trim()).toList();

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: List.generate(items.length, (index) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(getPrgLabelByIndex(index), style: const TextStyle(color: Colors.black54)),
                          trailing: Text(
                            items[index],
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: widget.isNarrow ? 16 : 14),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              const Text("Sequence",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),

              Selector<MqttPayloadProvider, String?>(
                selector: (_, provider) => provider.getSequencePreview(),
                builder: (_, status, __) {

                  if (status == null) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Skeletonizer(
                        enabled: true,
                        child: Column(
                          children: List.generate(8, (index) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(width: 130, height: 20,
                                    color: Colors.grey),
                              ),
                              trailing: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(width: 130, height: 20,
                                    color: Colors.grey),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  }

                  final List<String> sequenceList =
                  status.split(';').map((e) => e.trim()).toList();

                  final List<List<String>> parsedSequence = sequenceList
                      .map((seq) => seq.split(',').map((e) => e.trim()).toList())
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(parsedSequence.length, (index) {
                      final List<String> seq = parsedSequence[index];
                      final String sequenceName = seq[0];        // First → Title
                      final List<String> subItems = seq.sublist(1); // Others → Details

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ----------- Sequence Title ----------- //
                            ListTile(title: Text("Sequence_$sequenceName",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            )),

                            // ----------- Sub Items with Labels ----------- //
                            ...List.generate(subItems.length, (i) {
                              final label = getSeqLabelByIndex(i + 1);
                              final value = subItems[i];

                              return Padding(
                                padding: const EdgeInsets.only(left: 20.0, right: 8.0),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Text("${i+1}"),
                                  title: Text(label, style: const TextStyle(color: Colors.black54)),
                                  trailing: Text(value,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: widget.isNarrow ? 16 : 14),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String getPrgLabelByIndex(int index) {
    switch (index) {
      case 0:
        return "Name";
      case 1:
        return "Valve mode";
      case 2:
        return "Program mode";
      case 3:
        return "Fertilizer mode";
      case 4:
        return "Decide Last";
      case 5:
        return "Decide feedback last";
      case 6:
        return "Valve delay (MM:SS)";
      case 7:
        return "Feedback delay (MM:SS)";
      case 8:
        return "Cyc completed restart ON/OFF";
      case 9:
        return "Cyc completed com restart dly";
      case 10:
        return "Cyc restart ON/OFF";
      case 11:
        return "Program selection";
      case 12:
        return "Start from";
      case 13:
        return "Day count RTC time(HH:MM:SS)";
      case 14:
        return "Skip days";
      case 15:
        return "Skip days ON/OFF";
      case 16:
        return "Program percentage";
      case 17:
        return "Fertilizer ON/OFF";
      case 18:
        return "Venture flow rate";
      default:
        return "Prg $index";
    }
  }

  String getSeqLabelByIndex(int index) {
    switch (index) {
      case 1: return "Valve duration (HH:MM)";
      case 2: return "Valve flow liters";
      case 3: return "Selected valve";
      case 4: return "Fertilizer duration (HH:MM)";
      case 5: return "Fertilizer flow liters";
      default: return "Item $index";
    }
  }

}