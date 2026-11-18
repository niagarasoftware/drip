import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/customer_provider.dart';
import '../../../providers/button_loading_provider.dart';
import '../../../services/communication_service.dart';
import '../../../utils/my_helper_class.dart';
import '../../../utils/snack_bar.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';
import 'blink_text.dart';

class MyMaterialButton extends StatelessWidget {
  final String buttonId;
  final String label;
  final String payloadKey;
  final String payloadValue;
  final Color color;
  final Color textColor;
  final String serverMsg;

  final bool blink;

  const MyMaterialButton({
    super.key,
    required this.buttonId,
    required this.label,
    required this.payloadKey,
    required this.payloadValue,
    required this.color,
    required this.textColor,
    required this.serverMsg,
    this.blink = false,
  });

  Future<void> _sendCommand(BuildContext context) async {
    final customerProvider = context.read<CustomerProvider>();
    final vm = context.read<CustomerScreenControllerViewModel>();

    if (customerProvider.controllerCommMode == 2) {
      GlobalSnackBar.show(context, 'Bluetooth mode enabled. Please connect the device', 500);
      return;
    } else if (vm.isNotCommunicate) {
      GlobalSnackBar.show(context, 'Controller communication lost. Please check the connection and try again.', 500);
      return;
    }

    final buttonState = context.read<ButtonLoadingProvider>();
    final commService = context.read<CommunicationService>();

    buttonState.setLoading(buttonId, true);

    try {
      final contentKey = (int.parse(payloadKey) + 1).toString();
      final payLoadFinal = jsonEncode({
        payloadKey: {contentKey: payloadValue},
      });

      MqttAckTracker.registerPending(buttonId, payloadKey);

      await Future.delayed(const Duration(milliseconds: 100));

      await commService.sendCommand(
        serverMsg: serverMsg,
        payload: payLoadFinal,
      );

    } catch (e) {
      GlobalSnackBar.show(context, 'Error sending command: $e', 500);
      buttonState.setLoading(buttonId, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ButtonLoadingProvider>().isLoading(buttonId);
    final isDisabled = color == Colors.black26;

    return MaterialButton(
      color: color,
      textColor: textColor,
      onPressed: (isDisabled || isLoading) ? null : () => _sendCommand(context),
      disabledColor: Colors.black26,
      child: Center(
        child: isLoading ? const SizedBox(
          height: 30,
          child: LoadingIndicator(
            indicatorType: Indicator.ballPulse,
            colors: [Colors.white],
          ),
        ) : blink ? BlinkText(
          text: label,
          style: TextStyle(color: textColor),
        ) : Text(label),
      ),
    );
  }
}