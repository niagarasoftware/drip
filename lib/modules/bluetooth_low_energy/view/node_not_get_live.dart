import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../state_management/ble_service.dart';

class NodeNotGetLive extends StatefulWidget {
  final void Function()? onPressed;
  final bool loading;
  const NodeNotGetLive({super.key, required this.onPressed, required this.loading});

  @override
  State<NodeNotGetLive> createState() => _NodeNotGetLiveState();
}

class _NodeNotGetLiveState extends State<NodeNotGetLive> {
  late BleProvider bleService;

  @override
  void initState() {
    super.initState();
    bleService = Provider.of<BleProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    bleService = Provider.of<BleProvider>(context, listen: true);

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        spacing: 30,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Column(
            children: [
              SvgPicture.asset(
                'assets/Images/Svg/SmartComm/get_live.svg',
                width: MediaQuery.of(context).size.width,
              ),
              if(widget.loading)
                const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            onPressed: widget.onPressed,
            label: const Text('Live Request'),
            style: FilledButton.styleFrom(
              backgroundColor: widget.loading ? Colors.grey : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
