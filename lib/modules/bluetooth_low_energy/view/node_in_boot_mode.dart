import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../state_management/ble_service.dart';
import 'ble_sent_and_receive.dart';

class NodeInBootMode extends StatefulWidget {
  const NodeInBootMode({super.key});

  @override
  State<NodeInBootMode> createState() => _NodeInBootModeState();
}

class _NodeInBootModeState extends State<NodeInBootMode> {
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
      appBar: bleService.nodeDataFromHw['BOOT'] == "30" ? AppBar(
        title: const Text('Update Firmware'),
        actions: [
          Text(bleService.connectionState(), style: TextStyle(color: Colors.white),),
          const SizedBox(width: 20,)
        ],
      ) : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/Images/Svg/SmartComm/bootMode.svg',
                height: 300,
              ),
              Text(
                'Hardware is in boot mode.\nPlease update the firmware to proceed.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              if([
                FileMode.idle.name,
                FileMode.errorOnConnected.name,
                FileMode.disConnected.name,
                FileMode.fileNameNotGet.name,
                FileMode.errorOnWhileGetFileName.name,
                FileMode.tryAgainToGetFileName.name,
                FileMode.downloadFileFailed.name,
                FileMode.bootFail.name,
              ].contains(bleService.fileMode.name))
                FilledButton.icon(
                  icon: const Icon(Icons.system_update_alt_rounded),
                  onPressed: () {
                    bleService.getFileName();
                  },
                  label: const Text('Get Latest Firmware'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: nodeFileStatusBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sendFileWidget(){
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 10,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bleService.nodeFirmwareFileName,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if(bleService.fileMode == FileMode.downloadingFile)
            downloading(),
          if(bleService.fileMode == FileMode.downloadFileSuccess)
            sendButton(),
          if(bleService.fileMode == FileMode.sendingToHardware)
            fileSending(),
          if([FileMode.crcPass.name, FileMode.firmwareUpdating.name, FileMode.bootPass.name, FileMode.bootFail.name].contains(bleService.fileMode.name))
            fileMatched(),
        ],
      ),
    );
  }

  num getPercent() {
    if (bleService.totalNoOfLines == 0) return 0;

    double result = (bleService.currentLine / bleService.totalNoOfLines) * 100;

    if (result.isNaN || result.isInfinite) return 0;

    return result.round();
  }

  Widget sendButton(){
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton(
          onPressed: (){
            bleService.sendBootFile();
          },
          child: const Text('Send File', style: TextStyle(color: Colors.white),)
      ),
    );
  }

  Widget fileSending(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: getPercent()/100),
        const SizedBox(height: 8),
        Text('${getPercent()}% complete'),
      ],
    );
  }

  Widget nodeFileStatusBox(){
    return SizedBox(
      width: double.infinity,
      // height: 200,
      child: (bleService.fileMode == FileMode.connecting || bleService.fileMode == FileMode.connected) ?
      connecting()
          : bleService.nodeFirmwareFileName.isNotEmpty
          ? sendFileWidget() : _fileNotAvailable(),
    );
  }

  Widget _fileNotAvailable() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/Images/Png/file_not_available.png',
          height: 100,
          width: 100,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Click the above button to get the latest firmware.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget downloading(){
    return const Column(
      spacing: 20,
      children: [
        Text(
          'Downloading.....', style: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
          textAlign: TextAlign.center,
        ),
        SizedBox(
          width: double.infinity,
          child: LinearProgressIndicator(
            minHeight: 6,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget connecting(){
    return Row(
      children: [
        SvgPicture.asset(
          'assets/Images/Svg/SmartComm/connecting.svg',
          width: 100,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: [

              Text(bleService.fileMode.name,style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              const SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  minHeight: 6,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget fileMatched(){
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          if(bleService.fileMode == FileMode.bootPass)
            Image.asset(
              'assets/Images/Png/firmware_updated.png',
              width: 150,
            ),
          if(bleService.fileMode == FileMode.crcPass || bleService.fileMode == FileMode.firmwareUpdating)
            Lottie.asset(
              'assets/json/file_matched.json',
              width: 150,
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: [
              Text(
                bleService.fileMode == FileMode.crcPass
                    ? "CRC matched successfully!"
                    : bleService.fileMode == FileMode.crcFail
                    ? "CRC not matched!"
                    : bleService.fileMode == FileMode.bootPass ?
                    "Firmware updated successfully!"
                    : bleService.fileMode == FileMode.bootFail
                    ? "Firmware updated Failed!"
                    : "Please wait firmware is updating...",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              if(![FileMode.bootPass.name, FileMode.bootFail.name].contains(bleService.fileMode.name))
                const SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              if(bleService.fileMode == FileMode.bootFail)
                FilledButton.icon(
                  icon: const Icon(Icons.send, color: Colors.white,),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context){
                      return const BleSentAndReceive();
                    }));
                    },
                  label: const Text('Sent And Receive'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColorLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }
}
