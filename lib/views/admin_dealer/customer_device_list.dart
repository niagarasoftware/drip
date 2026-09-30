import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/config_base_page.dart';
import 'package:provider/provider.dart';
import '../../models/admin_dealer/product_list_with_node.dart';
import '../../models/admin_dealer/stock_model.dart';
import '../../providers/user_provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/formatters.dart';
import '../../view_models/admin_dealer/customer_device_list_view_model.dart';

enum MasterController {gem1, gem2, gem3, gem4, gem5, gem6, gem7, gem8, gem9, gem10,}

class CustomerDeviceList extends StatefulWidget {
  const CustomerDeviceList({
    super.key,
    required this.userId,
    required this.customerName,
    required this.customerId,
    required this.userRole,
    required this.productStockList,
    required this.onCustomerProductChanged,
  });

  final int userId, customerId;
  final String userRole, customerName;
  final List<StockModel> productStockList;

  final void Function(String action, List<StockModel> updatedProducts) onCustomerProductChanged;


  @override
  State<CustomerDeviceList> createState() => _CustomerDeviceListState();
}

class _CustomerDeviceListState extends State<CustomerDeviceList> with TickerProviderStateMixin {
  late TabController tabController;
  late CustomerDeviceListViewModel viewModel;
  final List<String> tabList = ['Product List', 'Site'];
  int currentSiteInx = 0;

  @override
  void initState() {
    super.initState();

    viewModel = CustomerDeviceListViewModel(
      Repository(HttpService()),
      widget.userId,
      widget.customerId,
      widget.productStockList.length,
      onProductUpdatedCallback: (action, updatedProducts) {
        widget.onCustomerProductChanged(action, updatedProducts);
        viewModel.getMasterProduct();
      },
    );

    tabController = TabController(length: tabList.length, vsync: this);
    tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => viewModel..loadDeviceList(1)..getCustomerSite()..getMasterProduct(),
      child: Consumer<CustomerDeviceListViewModel>(
        builder: (context, viewModel, _) {

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: "Close",
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                AnimatedBuilder(
                  animation: tabController,
                  builder: (context, _) {
                    return _buildActionPopup(context);
                  },
                ),
                const SizedBox(width: 20),
              ],
              bottom: TabBar(
                controller: tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
                tabs: tabList.map((label) => Tab(child: Text(label))).toList(),
              ),
            ),
            body: viewModel.isLoading ?
            const Center(child: CircularProgressIndicator()) :
            TabBarView(
              controller: tabController,
              children: [
                const CustomerDeviceTable(),
                CustomerSiteTabView(
                  viewModel: viewModel,
                  currentSiteInx: currentSiteInx,
                  onSiteChange: (index) => setState(() => currentSiteInx = index),
                  productStock: widget.productStockList,
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildActionPopup(BuildContext context) {
    return PopupMenuButton(
      tooltip: tabController.index == 0
          ? 'Add new product to ${widget.customerName}'
          : 'Create new site for ${widget.customerName}',
      child : Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tabController.index == 0 ? 'Add New Product' : 'Create New Site',
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.arrow_drop_down, color: Colors.black54),
          ],
        ),
      ),

      onCanceled: () {
        viewModel.selectedProducts =
        List<bool>.filled(widget.productStockList.length, false);
      },

      itemBuilder: (context) {
        return tabController.index == 0
            ? _buildProductListPopup(context)
            : _buildMasterSitePopup(context);
      },
    );
  }

  List<PopupMenuEntry> _buildProductListPopup(BuildContext context) {
    if (widget.productStockList.isEmpty) {
      return [const PopupMenuItem(child: Text('No stock available'))];
    }

    String searchText = "";
    // Keep each item paired with its ORIGINAL index so filtering never has
    // to guess a position back via indexOf (which breaks whenever two items
    // are equal by value, e.g. duplicate categoryName/imeiNo).
    final List<MapEntry<int, StockModel>> indexedList =
    widget.productStockList.asMap().entries.toList();
    List<MapEntry<int, StockModel>> filteredList = List.from(indexedList);

    return [
      PopupMenuItem(
        enabled: false,
        child: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 220,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(widget.productStockList.length > 8)...[
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: "Search...",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchText = value.toLowerCase();
                          filteredList = indexedList.where((entry) {
                            final item = entry.value;
                            return item.categoryName.toLowerCase().contains(searchText) ||
                                item.imeiNo.toLowerCase().contains(searchText);
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    height: 350,
                    child: filteredList.isEmpty
                        ? const Center(child: Text('No matching products'))
                        : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final entry = filteredList[index];
                        final originalIndex = entry.key;
                        final item = entry.value;

                        return CheckboxListTile(
                          title: Text(item.categoryName),
                          subtitle: Text(item.imeiNo),
                          value: viewModel.selectedProducts[originalIndex],
                          onChanged: (value) {
                            setState(() {
                              viewModel.toggleProductSelection(originalIndex);
                            });
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MaterialButton(
                        color: Colors.red,
                        textColor: Colors.white,
                        child: const Text('CANCEL'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      MaterialButton(
                        color: Colors.green,
                        textColor: Colors.white,
                        child: const Text('ADD'),
                        onPressed: () {
                          viewModel.addProductToCustomer(
                              context, widget.productStockList);
                        },
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),
    ];
  }

  List<PopupMenuEntry> _buildMasterSitePopup(BuildContext context) {
    if (viewModel.myMasterControllerList.isEmpty) {
      return [const PopupMenuItem(child: Text('No master available to create site'))];
    }

    String searchText = "";
    // Pair each master controller with its ORIGINAL index up front so the
    // filtered list never needs indexOf to find its way back (indexOf breaks
    // if two entries are equal by value).
    final List<MapEntry<int, dynamic>> indexedList =
    viewModel.myMasterControllerList.asMap().entries.toList();
    List<MapEntry<int, dynamic>> filteredList = List.from(indexedList);

    return [
      PopupMenuItem(
        enabled: false,
        child: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 220,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (viewModel.myMasterControllerList.length > 8) ...[
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search master...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchText = value.toLowerCase();
                          filteredList = indexedList.where((entry) {
                            final item = entry.value;
                            return item.categoryName.toLowerCase().contains(searchText) ||
                                item.imeiNo.toLowerCase().contains(searchText);
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    height: 300,
                    child: filteredList.isEmpty
                        ? const Center(child: Text('No matching master'))
                        : AnimatedBuilder(
                      animation: viewModel.selectedItem,
                      builder: (context, _) {
                        return ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final entry = filteredList[index];
                            final originalIndex = entry.key;
                            final master = entry.value;

                            return RadioListTile(
                              value: MasterController.values[originalIndex],
                              groupValue: viewModel.selectedItem.value,
                              title: Text(master.categoryName),
                              subtitle: Text(master.imeiNo),
                              onChanged: (value) {
                                setState(() {
                                  viewModel.selectedItem.value = value!;
                                  viewModel.selectedRadioTile = value.index;
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      MaterialButton(
                        color: Colors.red,
                        textColor: Colors.white,
                        child: const Text('CANCEL'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      MaterialButton(
                        color: Colors.green,
                        textColor: Colors.white,
                        child: const Text('CREATE'),
                        onPressed: () {
                          Navigator.pop(context);
                          final selected =
                          viewModel.myMasterControllerList[viewModel.selectedRadioTile];
                          viewModel.displayCustomerSiteDialog(
                            context,
                            selected.categoryName,
                            selected.model,
                            selected.imeiNo.toString(),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ];
  }
}

class CustomerDeviceTable extends StatelessWidget {
  const CustomerDeviceTable({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CustomerDeviceListViewModel>(context);

    return Column(
      children: [
        Expanded(
          child: viewModel.customerDeviceList.isNotEmpty
              ? DataTable2(
            scrollController: viewModel.scrollController,
            columnSpacing: 12,
            horizontalMargin: 12,
            headingRowHeight: 30,
            headingRowColor: WidgetStateProperty.all<Color>(
              Theme.of(context).primaryColorDark.withAlpha(1),
            ),
            dataRowHeight: 35,
            minWidth: 580,
            columns: const [
              DataColumn2(label: Text('S.No'), fixedWidth: 40),
              DataColumn2(label: Text('Category'), size: ColumnSize.M),
              DataColumn2(label: Text('Model'), size: ColumnSize.M),
              DataColumn2(label: Text('IMEI'), fixedWidth: 127),
              DataColumn2(label: Text('Status'), fixedWidth: 75),
              DataColumn2(label: Text('Modify Date'), fixedWidth: 113),
            ],
            rows: List.generate(viewModel.customerDeviceList.length, (index) {
              final device = viewModel.customerDeviceList[index];
              return DataRow(cells: [
                DataCell(Center(child: Text('${index + 1}', style: viewModel.commonTextStyle))),
                DataCell(Text(device.categoryName, style: viewModel.commonTextStyle)),
                DataCell(Text(device.model, style: viewModel.commonTextStyle)),
                DataCell(SelectableText(device.deviceId, style: viewModel.commonTextStyle)),
                DataCell(Center(
                  child: Row(
                    children: [
                      CircleAvatar(radius: 5, backgroundColor: _getStatusColor(device.productStatus)),
                      const SizedBox(width: 5),
                      Text(_getStatusText(device.productStatus), style: viewModel.commonTextStyle),
                    ],
                  ),
                )),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Formatters().formatDate(device.modifyDate),
                        style: viewModel.commonTextStyle,
                      ),
                      if (device.productStatus == 3) ...[
                        const Spacer(),
                        Tooltip(
                          message: 'Remove this product',
                          child: IconButton(
                            onPressed: () => viewModel.removeProductFromCustomer(device.productId),
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ]);
            }),
          )
              : const Center(child: Text('No device available')),
        ),
        if (viewModel.isLoading)
          Container(
            width: double.infinity,
            height: 30,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 300),
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.pink;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'In-Stock';
      case 2:
        return 'Stock';
      case 3:
        return 'Free';
      default:
        return 'Active';
    }
  }
}

class CustomerSiteTabView extends StatelessWidget {
  final CustomerDeviceListViewModel viewModel;
  final int currentSiteInx;
  final ValueChanged<int> onSiteChange;
  final List<StockModel> productStock;

  const CustomerSiteTabView({
    super.key,
    required this.viewModel,
    required this.currentSiteInx,
    required this.onSiteChange,
    required this.productStock,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: viewModel.customerSiteList.length,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TabBar(
                  indicatorColor: Theme.of(context).primaryColor,
                  labelColor: Theme.of(context).primaryColor,
                  isScrollable: true,
                  tabs: [
                    for (var site in viewModel.customerSiteList)
                      Tab(text: site.groupName),
                  ],
                  onTap: onSiteChange,
                ),
              ),
              const AddMasterPopup(), // Widget 3
              const SizedBox(width: 10),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height - 160,
            child: TabBarView(
              children: [
                for (var site in viewModel.customerSiteList)
                  MasterListForSite(site: site, viewModel: viewModel, productStock: productStock)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddMasterPopup extends StatelessWidget {
  const AddMasterPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CustomerDeviceListViewModel>(context);
    return PopupMenuButton(
      elevation: 10,
      tooltip: 'Add New Master Controller',
      child: const Center(
        child: MaterialButton(
          onPressed: null,
          child: Row(
            children: [
              Icon(Icons.add, color: Colors.black),
              SizedBox(width: 3),
              Text('Add New Master', style: TextStyle(color: Colors.black)),
              SizedBox(width: 3),
              Icon(Icons.arrow_drop_down, color: Colors.black),
            ],
          ),
        ),
      ),
      onCanceled: () => viewModel.checkboxValue = false,
      itemBuilder: (context) {
        if (viewModel.myMasterControllerList.isEmpty) {
          return [const PopupMenuItem(child: Text('No master controller available'))];
        }

        String searchText = "";
        // Same fix as the other popups: keep original indices attached
        // instead of looking them up with indexOf after filtering.
        final List<MapEntry<int, dynamic>> indexedList =
        viewModel.myMasterControllerList.asMap().entries.toList();
        List<MapEntry<int, dynamic>> filteredList = List.from(indexedList);

        return [
          PopupMenuItem(
            enabled: false,
            child: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 220,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (viewModel.myMasterControllerList.length > 8) ...[
                        TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search master...',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchText = value.toLowerCase();
                              filteredList = indexedList.where((entry) {
                                final item = entry.value;
                                return item.categoryName.toLowerCase().contains(searchText) ||
                                    item.imeiNo.toLowerCase().contains(searchText);
                              }).toList();
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                      ],

                      SizedBox(
                        height: 300,
                        child: filteredList.isEmpty
                            ? const Center(child: Text('No matching master controller'))
                            : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final entry = filteredList[index];
                            final originalIndex = entry.key;
                            final controller = entry.value;

                            return RadioListTile<int>(
                              value: originalIndex,
                              groupValue: viewModel.selectedRadioTile,
                              title: Text(controller.categoryName),
                              subtitle: Text(controller.imeiNo),
                              onChanged: (value) {
                                setState(() {
                                  viewModel.selectedRadioTile = value!;
                                });
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          MaterialButton(
                            color: Colors.red,
                            textColor: Colors.white,
                            child: const Text('CANCEL'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          MaterialButton(
                            color: Colors.teal,
                            textColor: Colors.white,
                            child: const Text('ADD'),
                            onPressed: () =>
                                viewModel.createNewMaster(context, viewModel.selectedRadioTile),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ];
      },
    );
  }
}

class MasterListForSite extends StatelessWidget {
  final ProductListWithNode site;
  final dynamic viewModel;
  final List<StockModel> productStock;

  const MasterListForSite({
    super.key,
    required this.site,
    required this.viewModel, required this.productStock,
  });

  @override
  Widget build(BuildContext context) {

    final loggedUser = Provider.of<UserProvider>(context, listen: false).loggedInUser;

    return SizedBox(
      height: MediaQuery.of(context).size.height - 160,
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (int mstIndex = 0; mstIndex < site.master.length; mstIndex++)
              Column(
                children: [
                  ListTile(
                    title: Text(site.master[mstIndex].categoryName,
                        style: const TextStyle(fontSize: 15)),
                    subtitle: SelectableText(
                        site.master[mstIndex].deviceId.toString(),
                        style: const TextStyle(fontSize: 12)),
                    trailing: !loggedUser.configPermission ?
                    SizedBox(
                      width: 125,
                      child: MaterialButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              var masterData = site.master[mstIndex];
                              return ConfigBasePage(
                                fromDashboard: false,
                                masterData: {
                                  "userId": viewModel.userId,
                                  "customerId": viewModel.customerId,
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
                                  "productStock": productStock.map((e) => e.toJson()).toList(),
                                },
                              );
                            }),
                          );
                        },
                        color: Colors.teal,
                        child: const Row(
                          children: [
                            Icon(Icons.confirmation_number_outlined,
                                color: Colors.white),
                            SizedBox(width: 5),
                            Text('Site Config',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ) : null,
                  ),
                  if (site.master.length > 1) const Divider(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}