import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Constants/dialog_boxes.dart';
import 'package:oro_drip_irrigation/Widgets/custom_buttons.dart';
import 'package:provider/provider.dart';

import '../state_management/ble_service.dart';

class TraceScreen extends StatefulWidget {
  final Map<String, dynamic> nodeData;

  const TraceScreen({super.key, required this.nodeData});

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen> {
  late BleProvider bleService;

  @override
  void dispose() {
    bleService.traceScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    bleService = Provider.of<BleProvider>(context, listen: false);
    bleService.traceScrollController = ScrollController();
    bleService.sendTraceCommand();
  }

  @override
  Widget build(BuildContext context) {
    bleService = Provider.of<BleProvider>(context, listen: true);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, result) async {
        print("didPop: $didPop");
        print("result: $result");

        // Avoid further processing if the route is already popped
        if (didPop) return;

        if (bleService.traceMode == TraceMode.traceOn) {
          bool? shouldLeave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                "Alert",
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              content: const Text(
                "Do you really want to leave?",
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Stay on page
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    bleService.sendTraceCommand();
                    Navigator.of(context).pop(true); // Allow leaving
                  },
                  child: const Text("Trace off and leave"),
                ),
              ],
            ),
          );

          // If user confirms leaving, pop the route
          if (shouldLeave == true) {
            Navigator.of(context).pop(result);
          }
        } else {
          // If trace mode is off, allow the pop
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
            title: const Text('Trace')
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.file_copy),
              label: Text(bleService.traceMode == TraceMode.traceOn ? 'Trace Off' : 'Trace On'),
              onPressed: (){
                bleService.sendTraceCommand();
              },
              style: FilledButton.styleFrom(
                backgroundColor: bleService.traceMode == TraceMode.traceOn ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Upload'),
              onPressed: (){
                bleService.uploadTraceFile(deviceId: widget.nodeData['deviceId']);
                showDialogForUploadingFlags();

              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: Scrollbar(
          thumbVisibility: true,
          child: ListView.builder(
            controller: bleService.traceScrollController,
            itemCount: bleService.traceData.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                child: Text(bleService.traceData[index]),
              );
            },
          ),
        ),
      ),
    );
  }

  void showDialogForUploadingFlags()async{
    showDialog(
        barrierDismissible: false,
        context: context, builder: (context){
      return const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            spacing: 20,
            children: [
              CircularProgressIndicator(),
              Text('Please wait...')
            ],
          ),
        ),
      );
    }
    );
    int waitingDelay = 60;
    bool success = false;
    for(var second = 0; second < waitingDelay;second++){
      if(bleService.fileMode == FileMode.uploadFileSuccess){
        success = true;
        break;
      }else if(bleService.fileMode == FileMode.uploadFileFailed || bleService.fileMode == FileMode.errorOnConnected){
        break;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    Navigator.pop(context);
    simpleDialogBox(context: context, title: 'Upload Message', message: 'Trace file upload ${success ? 'successfully' : 'failed'}');
  }
}