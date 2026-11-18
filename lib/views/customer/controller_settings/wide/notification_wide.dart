import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';

import '../../../../repository/repository.dart';
import '../../../../services/http_service.dart';
import '../../../../view_models/customer/notification_view_model.dart';

class NotificationWide extends StatelessWidget {
  const NotificationWide({
    super.key,
    required this.customerId,
    required this.controllerId,
    required this.userId,
  });

  final int customerId;
  final int controllerId;
  final int userId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationViewModel(Repository(HttpService()))
        ..getNotificationList(customerId, controllerId),
      child: Consumer<NotificationViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.loadingState) {
            return Scaffold(body: _buildLoadingIndicator(context));
          }

          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Notifications On/Off",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 5,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemCount: viewModel.notificationList.length,
                      itemBuilder: (context, index) {
                        final item = viewModel.notificationList[index];
                        return Card(
                          color: Colors.white,
                          child: Center(
                            child: ListTile(
                              title: Text(item.notificationName),
                              trailing: Switch(
                                value: item.pushNotification,
                                onChanged: (value) =>
                                    viewModel.toggleNotification(index, value, isPush: true),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Save to (Send & Receive)",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 5,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemCount: viewModel.notificationList.length,
                      itemBuilder: (context, index) {
                        final item = viewModel.notificationList[index];
                        return Card(
                          color: Colors.white,
                          child: Center(
                            child: ListTile(
                              title: Text(item.notificationName),
                              trailing: Switch(
                                value: item.sendAndReceive,
                                onChanged: (value) =>
                                    viewModel.toggleNotification(index, value, isPush: false),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: ElevatedButton(
              onPressed: () => viewModel.updateNotificationList(context, customerId, controllerId, userId),
              child: const Text("Update", style: TextStyle(color: Colors.white)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 50,
        height: 50,
        child: LoadingIndicator(indicatorType: Indicator.ballPulse),
      ),
    );
  }
}