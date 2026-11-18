
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Screens/Dealer/configureMqttTopic.dart';

import 'bLE_update.dart';
import 'controllerlogfile.dart';

class BLEMobileScreen extends StatelessWidget {
  final String deviceID;
  final String communicationType;
  final  userId, controllerId;

  const BLEMobileScreen({
    Key? key,
    required this.deviceID,
    required this.communicationType,
    required this.userId,
    required this.controllerId,
   }) : super(key: key);

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        title: Text("Controller: $deviceID"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              Text("Communication: $communicationType"),
              const SizedBox(height: 20),


              /// Firmware Update Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FirmwareBLEPage(
                           ),
                        ),
                      );
                    },
                    child: const Text("Update Firmware"),
                  ),


                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Show log
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ControllerLog(
                            deviceID: deviceID,
                            communicationType: communicationType,
                          ),
                        ),
                      );
                    },
                    child: const Text("View Log"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfigureMqtt(deviceID: deviceID, userId: userId, controllerId: controllerId,communicationType:communicationType),
                        ),
                      );
                    },
                    child: const Text("Update HW Settings"),
                  ),


                 ],
              ),
            ],
          ),
        ),
      ),
    );
  }



}
