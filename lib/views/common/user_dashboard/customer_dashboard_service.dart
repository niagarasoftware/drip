import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../view_models/bottom_nav_view_model.dart';
import '../../../view_models/customer/controller_settings_view_model.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../../../view_models/nav_rail_view_model.dart';

class CustomerDashboardService extends StatelessWidget {
  final int customerId;
  final Widget child;

  const CustomerDashboardService({
    super.key,
    required this.customerId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [

        ChangeNotifierProvider(
          create: (_) => CustomerScreenControllerViewModel(
            context,
            Repository(HttpService()),
            Provider.of<MqttPayloadProvider>(context, listen: false),
          )..getAllMySites(context, customerId),
        ),

        ChangeNotifierProxyProvider<CustomerScreenControllerViewModel,
            ControllerSettingsViewModel>(
          create: (_) => ControllerSettingsViewModel(Repository(HttpService())),
          update: (_, customerVm, settingsVm) {

            settingsVm ??= ControllerSettingsViewModel(Repository(HttpService()));

            if (customerVm.mySiteList.data.isEmpty) return settingsVm;

            final sIndex = customerVm.sIndex;
            final mIndex = customerVm.mIndex;

            if (sIndex >= customerVm.mySiteList.data.length ||
                mIndex >= customerVm.mySiteList.data[sIndex].master.length) {
              return settingsVm;
            }

            final site = customerVm.mySiteList.data[sIndex];
            final master = site.master[mIndex];

            WidgetsBinding.instance.addPostFrameCallback((_) {
              settingsVm!.getSettingsMenu(
                site.customerId,
                master.controllerId,
                master.modelId,
              );
            });

            return settingsVm;
          },
        ),

        ChangeNotifierProvider(create: (_) => BottomNavViewModel()),
        ChangeNotifierProvider(create: (_) => NavRailViewModel(Repository(HttpService()))),
      ],

      child: child,
    );
  }
}