import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:mqtt_client/mqtt_client.dart';

class ConnectionErrorToast extends StatelessWidget {
  final int dataFetchingStatus;

  const ConnectionErrorToast({super.key, required this.dataFetchingStatus});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: dataFetchingStatus == 1
          ? const SizedBox.shrink()
          : Container(
        key: const ValueKey("ConnectionError"),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(5),
        width: MediaQuery.of(context).size.width <= 500 ? MediaQuery.of(context).size.width : 400,
        decoration: BoxDecoration(
          color: Colors.red.shade300,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(dataFetchingStatus == 2 ? MdiIcons.progressAlert : MdiIcons.signalOff, color: Colors.white, size: 16,),
              const SizedBox(width: 10),
              Text(
                dataFetchingStatus == 2 ? "Wait for live sync..." : "Device is offline",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}