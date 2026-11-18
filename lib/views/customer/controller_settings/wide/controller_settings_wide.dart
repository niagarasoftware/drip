import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/view_models/customer/controller_settings_view_model.dart';
import 'package:provider/provider.dart';
import '../../../../StateManagement/customer_provider.dart';
import '../../../../models/customer/controller_context.dart';
import '../../../../models/customer/site_model.dart';
import '../../../../repository/repository.dart';
import '../../../../services/http_service.dart';
import '../../../common/widgets/build_loading_indicator.dart';
import '../widgets/settings_screen_factory.dart';

class ControllerSettingWide extends StatelessWidget {
  const ControllerSettingWide({
    super.key,
    required this.customerId,
    required this.userId,
    required this.masterController,
  });

  final int customerId, userId;
  final MasterControllerModel masterController;

  ControllerContext get ctx => ControllerContext(
    userId: userId,
    customerId: customerId,
    controllerId: masterController.controllerId,
    categoryId: masterController.categoryId,
    modelId: masterController.modelId,
    imeiNo: masterController.deviceId,
    deviceName: masterController.deviceName,
    master: masterController,
    categoryName: masterController.categoryName,
    isSubUser: masterController.isSubUser,
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(Provider.of<CustomerProvider>(context).controllerId),
      create: (_) => ControllerSettingsViewModel(Repository(HttpService()))
        ..getSettingsMenu(customerId, masterController.controllerId, masterController.modelId),
      child: Consumer<ControllerSettingsViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return buildLoadingIndicator(context);
          }
          return Scaffold(
            backgroundColor: Colors.white,
            body: DefaultTabController(
              length: viewModel.filteredSettingList.length,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: Theme.of(context).primaryColorLight,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    isScrollable: true,
                    tabs: viewModel.filteredSettingList.map((tab) {
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tab['icon'], size: 18),
                            const SizedBox(width: 6),
                            Text(tab['title']),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: viewModel.filteredSettingList.map((tab) {
                        return _buildTabContent(tab['title']);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(String title) {
    return SettingsScreenFactory.getScreenWidget(title, ctx, false) ?? const SizedBox();
  }
}