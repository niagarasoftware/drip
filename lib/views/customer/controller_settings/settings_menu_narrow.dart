import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/views/customer/controller_settings/widgets/settings_screen_factory.dart';
import 'package:provider/provider.dart';

import '../../../models/customer/controller_context.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/constants.dart';
import '../../../view_models/customer/controller_settings_view_model.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';

class SettingsMenuNarrow extends StatelessWidget {
  const SettingsMenuNarrow({super.key});

  @override
  Widget build(BuildContext context) {

    final loggedInUser = Provider.of<UserProvider>(context).loggedInUser;

    final cVM = context.watch<CustomerScreenControllerViewModel>();
    final master = cVM.mySiteList.data[cVM.sIndex].master[cVM.mIndex];

    final ctx = ControllerContext(
      userId: loggedInUser.id,
      customerId: cVM.mySiteList.data[cVM.sIndex].customerId,
      controllerId: master.controllerId,
      categoryId: master.categoryId,
      modelId: master.modelId,
      imeiNo: master.deviceId,
      deviceName: master.deviceName,
      master: master,
      categoryName: master.categoryName,
      isSubUser: master.isSubUser,
    );

    final viewModel = context.watch<ControllerSettingsViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.separated(
        itemCount: viewModel.filteredSettingList.length,
        separatorBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(left: 50, top: 5),
          child: Divider(height : 0, thickness: 0.5, color: Colors.black12),
        ),
        itemBuilder: (context, index) {
          final item = viewModel.filteredSettingList[index];
          final title = item['title'];

          return ListTile(
            visualDensity: const VisualDensity(vertical: -4),
            isThreeLine: true,
            leading: Icon(
              item['icon'],
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              AppConstants.getSettingsSummary(title),
              style: const TextStyle(color: Colors.black45),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => SettingsScreenFactory.navigateTo(context, title, ctx, true),
          );
        },
      ),
    );
  }
}