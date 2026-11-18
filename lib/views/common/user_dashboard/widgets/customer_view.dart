import 'package:badges/badges.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../Screens/Dealer/sevicerequestdealer.dart';
import '../../../../layouts/user_layout.dart';
import '../../../../models/admin_dealer/customer_list_model.dart';
import '../../../../models/admin_dealer/stock_model.dart';
import '../../../../models/user_model.dart';
import '../../../../modules/UserChat/view/user_chat.dart';
import '../../../../providers/user_provider.dart';
import '../../../../utils/enums.dart';
import '../../../../view_models/customer_list_view_model.dart';
import '../../../../view_models/product_stock_view_model.dart';
import '../../../admin_dealer/customer_device_list.dart';
import '../../../admin_dealer/dealer_device_list.dart';
import '../../user_profile/create_account.dart';


class CustomerView extends StatelessWidget {
  const CustomerView({super.key, required this.role, required this.isNarrow,
    required this.onCustomerProductChanged});
  final UserRole role;
  final bool isNarrow;
  final void Function(String action, List<StockModel> updatedProducts) onCustomerProductChanged;


  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomerListViewModel>();
    final stockVM = context.watch<ProductStockViewModel>();

    final hasDealers = viewModel.subDealerList.isNotEmpty;
    final hasCustomers = viewModel.customerList.isNotEmpty;
    final showHeaders = hasDealers && hasCustomers;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(viewModel),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -2),
              title: Text(role.name == 'admin' ? 'My Dealers':'My Customers',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 15),
              ),
              trailing: Text(
                viewModel.isLoadingCustomer ? '': '${viewModel.myCustomerList.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Expanded(
              child: Skeletonizer(
                enabled: viewModel.isLoadingCustomer,
                child: viewModel.isLoadingCustomer ? ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return _buildCustomerTile(
                      context,
                      CustomerListModel.fake(),
                      viewModel,
                      stockVM,
                    );
                  },
                ) :
                viewModel.filteredCustomerList.isNotEmpty ?
                ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    // Dealers section
                    if (hasDealers) ...[
                      if (showHeaders) _sectionHeader(
                          viewModel.subDealerList.length>1 ? 'Dealers'  : 'Dealer'),
                      ...viewModel.subDealerList.map(
                            (customer) => _buildCustomerTile(
                          context,
                          customer,
                          viewModel,
                          stockVM,
                        ),
                      ),
                    ],

                    // Customers section
                    if (hasCustomers) ...[
                      if (showHeaders) _sectionHeader(viewModel.customerList.length>1 ?
                      'Customers' : 'Customer'),
                      ...viewModel.customerList.map(
                            (customer) => _buildCustomerTile(
                          context,
                          customer,
                          viewModel,
                          stockVM,
                        ),
                      ),
                    ],
                  ],
                ) : const Center(
                  child: Text(
                    'No customer available',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: role.name == 'admin' ? "Add new dealer" : "Add new customer",
        onPressed: () => _showCreateAccountSheet(context, viewModel),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.black54,
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(CustomerListViewModel vm) {
    final showSearch = vm.searching || vm.filteredCustomerList.length > 15;

    if (!showSearch) return null;

    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      title: SizedBox(
        height: 40,
        child: TextField(
          controller: vm.txtFldSearch,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            hintText: 'Search customers...',
            hintStyle: const TextStyle(
              color: Colors.black38,
            ),
            prefixIcon: const Icon(Icons.search, size: 20,
                color:Colors.black54),
            suffixIcon: vm.searching ? IconButton(
              icon: const Icon(Icons.clear, size: 20,
                  color: Colors.black),
              onPressed: vm.clearSearch,
            )
                : null,
            filled: true,
            fillColor:Colors.black12,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.white30),
            ),
          ),
          onChanged: (value) =>
          value.isEmpty ? vm.clearSearch() : vm.filterCustomer(value),
          onSubmitted: (_) => vm.searchCustomer(),
        ),
      ),
    );
  }


  Widget _buildCustomerTile(BuildContext context, CustomerListModel customer,
      CustomerListViewModel vm, ProductStockViewModel stockVM) {
    final textStyle = isNarrow
        ? const TextStyle(fontWeight: FontWeight.bold)
        : const TextStyle(fontWeight: FontWeight.bold, fontSize: 13);

    final subtitleStyle = isNarrow
        ? const TextStyle(color: Colors.black54)
        : const TextStyle(color: Colors.black54, fontSize: 12);

    return ListTile(
      key: ValueKey(customer.id),
      tileColor: Colors.white,
      leading: const CircleAvatar(
        backgroundImage: AssetImage("assets/png/user_thumbnail.png"),
        backgroundColor: Colors.transparent,
        radius: 20,
      ),
      title: Text(customer.name, style: textStyle),
      subtitle: Text(
        '+ ${customer.countryCode} ${customer.mobileNumber}\n${customer.emailId}',
        style: subtitleStyle,
      ),
      trailing: (role.name == 'admin' || customer.isSubdealer == '1' ) ?
      IconButton(
        tooltip: 'View and Add new product',
        icon: const Icon(Icons.playlist_add_circle),
        onPressed: () => _showDeviceList(context, customer, stockVM),
      ) :
      buildCustomerTrailing(context, customer, stockVM),
      contentPadding: const EdgeInsets.only(left: 10, right: 5),
      onTap: () => openUserDashboard(context, customer, context.read<UserProvider>()),
    );
  }

  Widget buildCustomerTrailing(BuildContext context,
      CustomerListModel customer, ProductStockViewModel stockVM) {

    return Row(
      mainAxisSize: MainAxisSize.min, // keep row compact
      children: [
        IconButton(
          tooltip: 'Chat with Customer',
          icon: const Icon(Icons.chat),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserChatScreen(
                  userId: customer.id,
                  userName: customer.name,
                  phoneNumber:
                  '+${customer.countryCode} ${customer.mobileNumber}',
                ),
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'View and Add new product',
          icon: const Icon(Icons.playlist_add_circle),
          onPressed: () => _showDeviceList(context, customer, stockVM),
        ),
        if((customer.criticalAlarmCount + customer.serviceRequestCount) > 0)...[
          Badge(
            showBadge: (customer.criticalAlarmCount + customer.serviceRequestCount) > 0,
            position: BadgePosition.topEnd(top: 0, end: 0),
            badgeStyle: const BadgeStyle(
                badgeColor: Colors.red
            ),
            badgeContent: Text(
              '${customer.criticalAlarmCount + customer.serviceRequestCount}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: IconButton(
              tooltip: 'Service Request',
              icon: const Icon(Icons.build_circle),
              onPressed: () {
                if(MediaQuery.of(context).size.width >= 600) {
                  showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return  ServiceRequestsTable(userId: customer.id);
                      }
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceRequestsTable(userId: customer.id),
                    ),
                  );
                }
              },
            ),
          ),

        ]
      ],
    );
  }

  void _showCreateAccountSheet(
      BuildContext context, CustomerListViewModel vm) {
    final userRole = role.name == 'admin' ? UserRole.admin : UserRole.dealer;

    if (isNarrow) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (_) => SizedBox(
          height: 600,
          child: CreateAccount(
            userId: vm.userId,
            role: userRole,
            customerId : 0,
            onAccountCreated: vm.updateCustomerList,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.84,
          widthFactor: 0.75,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: CreateAccount(
              userId: vm.userId,
              role: userRole,
              customerId: 0,
              onAccountCreated: vm.updateCustomerList,
            ),
          ),
        ),
      );
    }
  }

  void _showDeviceList(
      BuildContext context,
      CustomerListModel customer,
      ProductStockViewModel stockVM,
      ) {

    final loggedInUser = Provider.of<UserProvider>(context, listen: false).loggedInUser;
    final isAdmin = role.name == 'admin' || customer.isSubdealer == '1';

    final Widget deviceListWidget = isAdmin ? DealerDeviceList(
      userId: loggedInUser.id,
      customerName: customer.name,
      customerId: customer.id,
      userRole: 'Dealer',
      productStockList: stockVM.productStockList,
      fromAdminPage: role.name == 'admin' ? true : false,
      //onDeviceListAdded: stockVM.removeStockList,
    ) : CustomerDeviceList(
      userId: loggedInUser.id,
      customerName: customer.name,
      customerId: customer.id,
      userRole: 'Customer',
      productStockList: stockVM.productStockList,
      onCustomerProductChanged: onCustomerProductChanged,
    );

    if (isNarrow) {
      Navigator.push(context,
        MaterialPageRoute(builder: (context) => deviceListWidget),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
        ),
        builder: (_) => deviceListWidget,
      );
    }
  }

  void openUserDashboard(
      BuildContext context, CustomerListModel customer, UserProvider userProvider) {
    final user = UserModel(
      token: userProvider.loggedInUser.token,
      id: customer.id,
      name: customer.name,
      role: role.name == "admin" ? UserRole.dealer : UserRole.customer,
      countryCode: customer.countryCode,
      mobileNo: customer.mobileNumber,
      email: customer.emailId,
      configPermission: customer.configPermission,
      password: userProvider.loggedInUser.password,
    );

    userProvider.pushViewedCustomer(user);

    //print("userType : ${customer.isSubdealer}");

    final route = role.name == 'admin' || customer.isSubdealer == '1'
        ? const DealerScreenLayout()
        : const CustomerScreenLayout();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => route),
    ).then((_) => userProvider.popViewedCustomer());
  }
}