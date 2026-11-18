import 'package:flutter/material.dart';

import '../../../models/customer/site_model.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';
import 'app_bar_action.dart';
import 'app_bar_drop_down_menu.dart';
import 'app_bar_logo.dart';

PreferredSizeWidget buildCustomerAppBar(
    BuildContext context,
    CustomerScreenControllerViewModel vm,
    MasterControllerModel cM,
    GlobalKey<ScaffoldState>? scaffoldKey, {
      bool showMenu = false,
      bool isNarrow = false,
    }) {
  return AppBar(
    title: isNarrow ? appBarLogo() : appBarDropDownMenu(context, vm, cM),
    actions: [
      ...appBarActions(context, vm, cM, isNarrow),
      if (showMenu)
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => scaffoldKey?.currentState?.openEndDrawer(),
        ),
    ],
    bottom: isNarrow ? PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: appBarDropDownMenu(context, vm, cM),
    ) : null,
  );
}
