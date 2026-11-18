import 'package:flutter/material.dart';

import '../../../view_models/customer/customer_screen_controller_view_model.dart';

class SiteSelectorWidget extends StatelessWidget {
  final CustomerScreenControllerViewModel vm;
  final BuildContext context;

  const SiteSelectorWidget({
    super.key,
    required this.vm,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {

    final siteList = vm.mySiteList.data;
    if (siteList.length <= 1) return const SizedBox();

    return DropdownButton(
      isExpanded: false,
      underline: Container(),
      items: (vm.mySiteList.data).map((site) {
        return DropdownMenuItem(
          value: site.groupName,
          child: Text(
            site.groupName,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
      onChanged: (siteName) => vm.siteOnChanged(siteName!),
      value: vm.myCurrentSite,
      dropdownColor: Theme.of(context).primaryColorLight,
      iconEnabledColor: Colors.white,
      iconDisabledColor: Colors.white,
      focusColor: Colors.transparent,
    );
  }
}