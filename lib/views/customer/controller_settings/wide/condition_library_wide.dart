import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../repository/repository.dart';
import '../../../../services/http_service.dart';
import '../../../../view_models/customer/condition_library_view_model.dart';
import '../widgets/build_condition_card.dart';
import '../widgets/build_floating_action_buttons.dart';
import '../widgets/condition_card_skeleton.dart';


class ConditionLibraryWide extends StatelessWidget {
  const ConditionLibraryWide({
    super.key,
    required this.customerId,
    required this.controllerId,
    required this.userId,
    required this.deviceId,
  });

  final int customerId;
  final int controllerId;
  final int userId;
  final String deviceId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConditionLibraryViewModel(Repository(HttpService()))
        ..getConditionLibraryData(customerId, controllerId),
      child: Consumer<ConditionLibraryViewModel>(
        builder: (context, vm, _) {

          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Skeletonizer(
                enabled: vm.isLoading,
                child: GridView.builder(
                  itemCount: vm.isLoading ? 6 : vm.clData.cnLibrary.condition.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 1350 ? 3 : 2,
                    crossAxisSpacing: 3.0,
                    mainAxisSpacing: 3.0,
                    childAspectRatio: _getChildAspectRatio(context),
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    if (vm.isLoading) {
                      return buildConditionCardSkeleton();
                    }
                    else if(vm.clData.cnLibrary.condition.isEmpty){
                      return const Center(child: Text('No condition available'));
                    }

                    return buildConditionCard(context, vm, index);
                  },
                ),
              ),
            ),
            floatingActionButton: vm.isLoading ? null : buildFloatingActionButtons(context, vm,
                customerId, controllerId, userId, deviceId),
          );
        },
      ),
    );
  }

  double _getChildAspectRatio(BuildContext context) {
    if (MediaQuery.of(context).size.width > 1350) {
      return MediaQuery.of(context).size.width / 1200;
    } else {
      return MediaQuery.of(context).size.width / 750;
    }
  }
}