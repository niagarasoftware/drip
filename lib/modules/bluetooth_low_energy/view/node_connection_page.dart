import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:oro_drip_irrigation/modules/bluetooth_low_energy/view/node_dashboard.dart';
import 'package:geolocator/geolocator.dart';
import '../state_management/ble_service.dart';
import 'package:provider/provider.dart';

/// Represents the state of the BLE node connection page.


class NodeConnectionPage extends StatefulWidget {
  final Map<String, dynamic> nodeData;
  final Map<String, dynamic> masterData;
  final ConnectMode connectMode;
  const NodeConnectionPage({super.key, required this.nodeData, required this.masterData, required this.connectMode});

  @override
  State<NodeConnectionPage> createState() => _NodeConnectionPageState();
}

class _NodeConnectionPageState extends State<NodeConnectionPage> {
  late BleProvider bleService;
  late Future<int> nodeBluetoothResponse;

  @override
  void initState() {
    super.initState();
    print(widget.nodeData);
    bleService = Provider.of<BleProvider>(context, listen: false);
    // nodeBluetoothResponse = getData();
    if (mounted) {
      _checkRequirements();
    }
  }

  // Future<int> getData()async{
  //   try{
  //     await Future.delayed(const Duration(seconds: 1));
  //     var body = {
  //       "userId": widget.masterData['customerId'],
  //       "controllerId": widget.masterData['controllerId'],
  //       "categoryId": widget.nodeData['categoryId'],
  //       "modelId": widget.nodeData['modelId'],
  //       "nodeControllerId": widget.nodeData['controllerId'],
  //       "deviceId": widget.nodeData['deviceId'],
  //       "hardwareModelId" : bleService.nodeDataFromHw['MID']
  //     };
  //     print("body : $body");
  //     var nodeBluetoothResponse = await BleRepository().getNodeBluetoothSetting(body);
  //     Map<String, dynamic> nodeJsonData = jsonDecode(nodeBluetoothResponse.body);
  //     bleService.editNodeDataFromServer(nodeJsonData['data']['default'], widget.nodeData);
  //     if(nodeJsonData['code'] == 200){
  //       if (mounted) {
  //         _checkRequirements();
  //       }
  //     }
  //     return nodeJsonData['code'];
  //   }catch(e,stacktrace){
  //     print('Error on getting constant data :: $e');
  //     print('Stacktrace on getting constant data :: $stacktrace');
  //     rethrow;
  //   }
  // }

  Future<void> _checkRequirements() async {
    bool isBluetoothOn = await _isBluetoothEnabled();
    if (!isBluetoothOn) {
      setState(() => bleService.bleNodeState = BleNodeState.bluetoothOff);
      return;
    }

    bool isLocationOn = await _isLocationEnabled();
    if (!isLocationOn) {
      setState(() => bleService.bleNodeState = BleNodeState.locationOff);
      return;
    }
    if(bleService.bleNodeState != BleNodeState.deviceFound){
      bleService.autoScanAndFoundDevice(macAddressToConnect: widget.nodeData['deviceId'], modelIdToUpdate: widget.nodeData['modelId'], connectMode: widget.connectMode);
    }
  }

  Future<bool> _isBluetoothEnabled() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e, backtrace) {
      // Snackbar.show(
      //   context,1
      //   prettyException("Bluetooth check error:", e),
      //   success: false,
      // );
      if (kDebugMode) {
        print("Bluetooth check error: $e");
        print("Backtrace: $backtrace");
      }
      return false;
    }
  }

  Future<bool> _isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  Widget build(BuildContext context) {
    bleService = Provider.of<BleProvider>(context, listen: true);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, result) async{
        print("didPop : $didPop");
        print("result : $result");
        if (didPop) return;
        if (bleService.bleConnectionState == BluetoothConnectionState.connected) {
          bool shouldLeave = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Alert", style: TextStyle(fontSize: 16, color: Colors.red)),
              content: const Text("Do you really want to leave?", style: TextStyle(fontSize: 14),),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  }, // Stay on page
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    bleService.onDisconnect(clearAll: true);
                    Navigator.of(context).pop(true);
                  },
                  child: const Text("Disconnect and leave"),
                ),
              ],
            ),
          );
          if(shouldLeave){
            Navigator.of(context).pop(result);
          }
        }
        else if([BleNodeState.scanning.name, BleNodeState.deviceFound.name, BleNodeState.connecting.name].contains(bleService.bleNodeState.name)){
          setState(() {
            bleService.forceStop = true;
          });
          Navigator.of(context).pop(result);
        }
        else{
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: InkWell(
            onTap: (){
              setState(() {
                bleService.developerOption++;
              });
            },
            child: Column(
              children: [
                Text('${widget.nodeData['deviceName']}',style: const TextStyle(fontSize: 16),),
                Text('${widget.nodeData['deviceId']}',style: const TextStyle(fontSize: 14),),
              ],
            ),
          ),
        ),
        body: Center(
          child: _buildContent(),
        ),
        // body: Center(
        //   child: FutureBuilder<int>(
        //       future: nodeBluetoothResponse,
        //       builder: (context, snapshot){
        //         if (snapshot.connectionState == ConnectionState.waiting) {
        //           return const Center(child: CircularProgressIndicator()); // Loading state
        //         } else if (snapshot.hasError) {
        //           return Text('Error: ${snapshot.error}'); // Error state
        //         } else if (snapshot.hasData) {
        //           return Center(
        //             child: _buildContent(),
        //           );
        //         } else {
        //           return const Text('No data'); // Shouldn't reach here normally
        //         }
        //       }
        //   ),
        // ),
      ),
    );
  }

  Widget _buildContent() {
    switch (bleService.bleNodeState) {
      case BleNodeState.loading:
        return _loading();
      case BleNodeState.bluetoothOff:
        return _bluetoothOffWidget();
      case BleNodeState.locationOff:
        return _locationOffWidget();
      case BleNodeState.scanning:
        return _scanningWidget();
      case BleNodeState.deviceFound:
        return _deviceFound(found: true);
      case BleNodeState.deviceNotFound:
        return _deviceFound(found: false);
      case BleNodeState.connecting:
        return _deviceConnecting();
      case BleNodeState.connected:
        return _deviceConnected();
      case BleNodeState.disConnected:
        return _deviceNotConnected();
      case BleNodeState.dashboard:
        return NodeDashboard(nodeData: widget.nodeData, masterData: widget.masterData,);
      default:
        return const Text('Unknown State');
    }
  }

  Widget _scanningWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Lottie.asset(
            'assets/json/bluetooth_scanning.json',
          height: 300
        ),
        const SizedBox(height: 24),
        Text(
          'Scanning...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColorLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Please ensure you are nearby the bluetooth kit.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            minHeight: 6,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _deviceFound({required bool found}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Lottie.asset(
            'assets/json/device_found.json',
            height: 400,
        ),
        const SizedBox(height: 12),
        Text(
          widget.nodeData['deviceName'],
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Device Id: ${widget.nodeData['deviceId']}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          found ? 'Device Found Successfully!' : 'Device Not Found!',
          style: TextStyle(
            fontSize: 16,
            color: found ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        if(!found)
          FilledButton.icon(
          icon: const Icon(Icons.bluetooth_rounded),
          label: const Text('Scan Again'),
          onPressed: () {
            bleService.autoScanAndFoundDevice(macAddressToConnect: widget.nodeData['deviceId'], modelIdToUpdate: widget.nodeData['modelId'], connectMode: widget.connectMode);
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
    );
  }

  Widget _deviceConnected() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/Images/Png/SmartComm/bluetooth_connected.png',
            height: 300,
          ),
          const SizedBox(height: 24),
          Row(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white,)
              ),
              Text(
                'Connected Successfully',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColorLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deviceConnecting() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/Images/Png/SmartComm/bluetooth_connecting.png',
            height: 300,
          ),
          const SizedBox(height: 24),
          Text(
            'Connecting to Device...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColorLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Please wait while we establish a connection.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              minHeight: 6,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceNotConnected() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        spacing: 30,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/Images/Png/SmartComm/bluetooth_connecting.png',
            height: 300,
          ),
          const Text(
            'Please ensure you are nearby the bluetooth kit.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.bluetooth),
            onPressed: () {
              bleService.autoConnect();
            },
            label: const Text('Connect Again'),
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

        ],
      ),
    );
  }

  Widget _loading() {
    return Center(
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black87
        ),
        child: Row(
          spacing: 20,
          children: [
            SizedBox(
              width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.blue.shade100,
                )
            ),
            const Text('Please Wait..', style: TextStyle(color: Colors.white, fontSize: 16),)
          ],
        ),
      ),
    );
  }

  Widget _bluetoothOffWidget() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// SVG Image
            SvgPicture.asset(
              'assets/Images/Svg/SmartComm/bluetooth_off.svg',
              height: 260,
            ),
            const SizedBox(height: 24),

            /// Message Text
            const Text(
              'Bluetooth is off.\nPlease enable it to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            /// Turn On Button
            FilledButton.icon(
              icon: const Icon(Icons.bluetooth_rounded),
              label: const Text('Turn On Bluetooth'),
              onPressed: () async {
                setState(() => bleService.bleNodeState = BleNodeState.loading);
                try {
                  if (!kIsWeb && Platform.isAndroid) {
                    await FlutterBluePlus.turnOn();
                  }
                  await Future.delayed(const Duration(seconds: 2));
                  _checkRequirements();
                } catch (e, backtrace) {
                  // Optional: You can display a SnackBar or Dialog
                  if (kDebugMode) {
                    print("Turn on Bluetooth error: $e");
                    print("Backtrace: $backtrace");
                  }
                }
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
      ),
    );
  }

  Widget _locationOffWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/Images/Svg/SmartComm/location_off.svg',
              height: 250,
            ),
            const SizedBox(height: 24),
            Text(
              'Location is off',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please enable location services to continue using the app.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.settings, color: Colors.white),
                label: const Text(
                  'Open Location Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                onPressed: () async {
                  bool openedSettings = await Geolocator.openLocationSettings();
                  if (openedSettings) {
                    await Future.delayed(const Duration(seconds: 2));
                    _checkRequirements();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}
