import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../Screens/Dealer/sevicecustomer.dart';
import '../../../flavors.dart';
import '../../../modules/UserChat/view/user_chat.dart';
import '../../../utils/routes.dart';
import '../../../utils/shared_preferences_helper.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../../common/user_profile/user_profile.dart';
import '../app_info.dart';
import '../customer_product.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../help_support.dart';


class CustomerDrawer extends StatelessWidget {
  final int customerId;
  final String customerName;
  final String customerMobileNo;
  final String customerEmailId;
  final dynamic loggedInUser;
  final CustomerScreenControllerViewModel vm;
  const CustomerDrawer({
    super.key,
    required this.customerId,
    required this.loggedInUser,
    required this.vm,
    required this.customerName, required this.customerMobileNo, required this.customerEmailId,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(),
      surfaceTintColor: Colors.white,
      child: Column(
        children: [
          _buildHeader(context),
          _buildDrawerItem(
            context,
            icon: Icons.account_circle_outlined,
            text: "Profile",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserProfile(isNarrow: true)),
            ),
          ),
          _divider(),
          _buildDrawerItem(
            context,
            icon: Icons.info_outline,
            text: "App Info",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AppInfo()),
            ),
          ),
          _divider(),
          _buildDrawerItem(
            context,
            icon: Icons.help_outline,
            text: "Help & Support",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardHelpPage(),
              ),
            ),
          ),
          _divider(),
          _buildDrawerItem(
            context,
            icon: Icons.feedback_outlined,
            text: "Send Feedback",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserChatScreen(
                  userId: customerId,
                  userName: customerName,
                  phoneNumber: customerMobileNo,
                ),
              ),
            ),
          ),
          _divider(),
          _buildDrawerItem(
            context,
            icon: Icons.support_agent_sharp,
            text: "Service Request",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketHomePage(
                  userId: loggedInUser.id,
                  controllerId: vm.mySiteList.data[vm.sIndex].master[vm.mIndex].controllerId,
                ),
              ),
            ),
          ),
          _divider(),
          _buildDrawerItem(
            context,
            icon: Icons.devices,
            text: "All my devices",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerProduct(customerId: loggedInUser.id),
              ),
            ),
          ),
          _divider(),
          _buildLogoutButton(context),
          const Spacer(),
          _buildFooterLogo(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(color: Theme.of(context).primaryColor),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 70,
            height: 70,
            child: CircleAvatar(),
          ),
          SizedBox(
            width: MediaQuery.sizeOf(context).width,
            child: Column(
              children: [
                Text(
                  customerName,
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  customerMobileNo,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  customerEmailId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.keyboard_arrow_right_rounded),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 25),
      child: Divider(height: 0, color: Colors.grey.shade300),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
      child: TextButton.icon(
          onPressed: () async {
            await PreferenceHelper.clearAll();

            if (!context.mounted) return;

            if (kIsWeb) {
              // Only safe to check on web
              if (isSkiaWeb) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.login,
                      (route) => false,
                );
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.loginOtp,
                      (route) => false,
                );
              }
            } else {
              // Mobile / desktop path
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.loginOtp,
                    (route) => false,
              );
            }
          },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          "Logout",
          style: TextStyle(color: Colors.red, fontSize: 17),
        ),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildFooterLogo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          F.appFlavor!.name.contains('oro') ?
          Image.asset('assets/png/company_logo_nia.png', width: 60) :
          F.appFlavor!.name.contains('agritel') ?
          Image.asset('assets/png/agritel_logo.png', width: 157) :
          SizedBox(
            height: 60,
            child: Image.asset('assets/png/company_logo.png'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}