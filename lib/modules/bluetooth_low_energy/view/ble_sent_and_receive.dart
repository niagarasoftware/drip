import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state_management/ble_service.dart';

class BleSentAndReceive extends StatefulWidget {
  const BleSentAndReceive({super.key});

  @override
  State<BleSentAndReceive> createState() => _BleSentAndReceiveState();
}

class _BleSentAndReceiveState extends State<BleSentAndReceive> {
  late BleProvider bleService;

  @override
  void initState() {
    super.initState();
    bleService = Provider.of<BleProvider>(context, listen: false);
  }
  @override
  Widget build(BuildContext context) {
    bleService = Provider.of<BleProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
          title: const Text('Ble Sent And Receive')
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: ListView.builder(
          itemCount: bleService.sentAndReceive.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Text(bleService.sentAndReceive[index]),
            );
          },
        ),
      ),
    );
  }
}
