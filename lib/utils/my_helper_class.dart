
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/utils/snack_bar.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../providers/button_loading_provider.dart';
import '../providers/user_provider.dart';
import '../repository/repository.dart';
import '../services/http_service.dart';
import '../view_models/base_header_view_model.dart';
import '../view_models/customer/customer_screen_controller_view_model.dart';
import '../views/common/user_dashboard/management_dashboard_service.dart';
import 'constants.dart';


mixin LayoutHelpers {
  UserProvider getUserProvider(BuildContext context) => context.read<UserProvider>();

  ChangeNotifierProvider<BaseHeaderViewModel> wrapWithBaseHeader(
      BuildContext context, {
        required List<String> menuTitles,
        required Widget child,
      }) {
    final viewedCustomer = getUserProvider(context).viewedCustomer!;
    return ChangeNotifierProvider<BaseHeaderViewModel>(
      create: (_) => BaseHeaderViewModel(
        menuTitles: menuTitles,
        repository: Repository(HttpService()),
      )..fetchCategoryModelList(viewedCustomer.id, viewedCustomer.role),
      child: child,
    );
  }

  Widget wrapWithDashboardService({
    required int userType,
    required BuildContext context,
    required Widget child,
  }) {
    final viewedCustomer = getUserProvider(context).viewedCustomer!;
    return ManagementDashboardService(
      userId: viewedCustomer.id,
      userType: userType,
      child: child,
    );
  }
}

abstract class BaseCustomerScreenState<T extends StatefulWidget> extends State<T> with ProgramRefreshMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void callbackFunction(String status) {
    if (status == 'Program created' && mounted) {
      onProgramCreated(context);
    }
  }

  bool isGemOrNovaModel(int modelId) => [
    ...AppConstants.gemModelList,
    ...AppConstants.ecoGemModelList,
    ...AppConstants.omsGemList,
  ].contains(modelId);
}

mixin ProgramRefreshMixin<T extends StatefulWidget> on State<T> {
  void onProgramCreated(BuildContext context) {
    final viewModel = Provider.of<CustomerScreenControllerViewModel>(context, listen: false);
    final viewedCustomer = Provider.of<UserProvider>(context, listen: false).viewedCustomer;
    if (viewedCustomer != null) {
      viewModel.getAllMySites(context, viewedCustomer.id, preserveSelection: true);
    }
  }
}

class MqttAckTracker {
  static final Map<String, Timer> _timeoutTimers = {};
  static final Map<String, String> _pendingButtons = {};

  static void registerPending(String buttonId, String payloadKey) {
    _pendingButtons[buttonId] = payloadKey;

    _timeoutTimers[buttonId]?.cancel();

    _timeoutTimers[buttonId] = Timer(const Duration(seconds: 30), () {
      _onTimeout(buttonId);
    });

    debugPrint("Waiting ACK for button: $buttonId payloadKey: $payloadKey");
  }

  static void ackReceived(String payloadKey) {
    final String buttonId = _pendingButtons.entries
        .firstWhere(
            (entry) => entry.value == payloadKey,
        orElse: () => const MapEntry("", ""))
        .key;

    if (buttonId.isEmpty) {
      debugPrint("⚠ ACK arrived but no button matched payloadKey=$payloadKey");
      return;
    }

    debugPrint("ACK matched for button: $buttonId payloadKey: $payloadKey");

    final context = navigatorKey.currentContext!;
    final buttonProvider = Provider.of<ButtonLoadingProvider>(context, listen: false);

    buttonProvider.setLoading(buttonId, false);

    _timeoutTimers[buttonId]?.cancel();
    _timeoutTimers.remove(buttonId);
    _pendingButtons.remove(buttonId);
  }

  static void _onTimeout(String buttonId) {
    final context = navigatorKey.currentContext!;
    final buttonProvider = Provider.of<ButtonLoadingProvider>(context, listen: false);

    debugPrint("Timeout! No ACK for button: $buttonId");

    buttonProvider.setLoading(buttonId, false);

    GlobalSnackBar.show(context, "No response from device. Please try again.", 500);

    _timeoutTimers[buttonId]?.cancel();
    _timeoutTimers.remove(buttonId);
    _pendingButtons.remove(buttonId);
  }
}