import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../modules/config_maker/view/config_base_page.dart';
import '../../providers/user_provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../view_models/customer/site_config_view_model.dart';

class SiteConfig extends StatelessWidget {
  final int userId, customerId, groupId;
  final String customerName, groupName;

  const SiteConfig({super.key,
    required this.userId,
    required this.customerId,
    required this.customerName,
    required this.groupId,
    required this.groupName});

  @override
  Widget build(BuildContext context) {

    final loggedUser = Provider.of<UserProvider>(context, listen: false).loggedInUser;

    return ChangeNotifierProvider(
      create: (_) => SiteConfigViewModel(Repository(HttpService()))..getCustomerSite(customerId),
      child: Consumer<SiteConfigViewModel>(
        builder: (context, viewModel, _) {
          return SizedBox(
            height: MediaQuery.of(context).size.height - 160,
            width: MediaQuery.of(context).size.width,
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 160,
              width: MediaQuery.of(context).size.width,
              child: ListView.builder(
                itemCount: viewModel.customerSiteList.length,
                itemBuilder: (context, siteIndex) {
                  final site = viewModel.customerSiteList[siteIndex];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group name
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
                        child: Text(
                          site.groupName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),

                      // Master list
                      ...List.generate(site.master.length, (mstIndex) {
                        var masterData = site.master[mstIndex];
                        return Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Card(
                            color: Colors.white,
                            child: ListTile(
                              title: Text(masterData.categoryName,
                                  style: const TextStyle(fontSize: 15)),
                              subtitle: SelectableText(masterData.deviceId.toString(),
                                  style: const TextStyle(fontSize: 12)),
                              trailing: SizedBox(
                                width: 170,
                                child: !loggedUser.configPermission ?
                                MaterialButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) {
                                        return ConfigBasePage(
                                          fromDashboard: true,
                                          masterData: {
                                            "userId": userId,
                                            "customerId": customerId,
                                            "controllerId": masterData.controllerId,
                                            "productId": masterData.productId,
                                            "deviceId": masterData.deviceId,
                                            "deviceName": masterData.deviceName,
                                            "categoryId": masterData.categoryId,
                                            "categoryName": masterData.categoryName,
                                            "modelId": masterData.modelId,
                                            "modelDescription": masterData.modelDescription,
                                            "modelName": masterData.modelName,
                                            "groupId": site.userGroupId,
                                            "groupName": site.groupName,
                                            "connectingObjectId": [
                                              ...masterData.outputObjectId.split(','),
                                              ...masterData.inputObjectId.split(','),
                                            ],
                                            "productStock" : []
                                          },
                                        );
                                      }),
                                    );
                                  },
                                  color: Theme.of(context).primaryColorLight,
                                  child: const Row(
                                    children: [
                                      Icon(Icons.confirmation_number_outlined,
                                          color: Colors.white),
                                      SizedBox(width: 5),
                                      Text('Site Configuration',
                                          style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ): null,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
