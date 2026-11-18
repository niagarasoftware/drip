import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/views/customer/widgets/site_selector_widget.dart';
import 'package:provider/provider.dart';

import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/formatters.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';
import 'irrigation_line_selector_widget.dart';
import 'master_selector_widget.dart';

Widget appBarDropDownMenu(BuildContext context,
    CustomerScreenControllerViewModel vm, MasterControllerModel master) {
  return Container(
    color: Theme.of(context).primaryColor,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.transparent,
              ),
              width: 45,
              height: 45,
              child: IconButton(
                tooltip: 'refresh',
                onPressed: vm.onRefreshClicked,
                icon: const Icon(Icons.refresh),
                color: Colors.white,
                iconSize: 24.0,
                hoverColor: Theme.of(context).primaryColorLight,
              ),
            ),
            Selector<CustomerScreenControllerViewModel, String>(
              selector: (_, vm) => vm.mqttProvider.liveDateAndTime,
              builder: (_, liveDateAndTime, __) => Text(
                'Last sync - ${Formatters.formatDateTime(liveDateAndTime)}',
                style: const TextStyle(fontSize: 14, color: Colors.white60),
              ),
            ),

            const SizedBox(width: 5),

            if (vm.mySiteList.data.length > 1)...[
              const VerticalDividerWhite(),
            ],
            SiteSelectorWidget(vm: vm, context: context),

            if (vm.mySiteList.data[vm.sIndex].master.length > 1)...[
              const VerticalDividerWhite(),
            ],
            MasterSelectorWidget(vm: vm, sIndex: vm.sIndex, mIndex: vm.mIndex),

            if ([...AppConstants.gemModelList, ...AppConstants.ecoGemModelList]
                .contains(master.modelId) &&
                master.irrigationLine.length > 1)...[
              const VerticalDividerWhite(),
            ],

            IrrigationLineSelectorWidget(vm: vm),

            const SizedBox(width: 15),
          ],
        ),
      ),
    ),
  );
}

class VerticalDividerWhite extends StatelessWidget {
  const VerticalDividerWhite({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 1,
        height: 20,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.white54),
        ),
      ),
    );
  }
}