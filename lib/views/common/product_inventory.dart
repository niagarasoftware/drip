import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import '../../models/admin_dealer/inventory_model.dart';
import '../../StateManagement/search_provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/enums.dart';
import '../../view_models/admin_dealer/inventory_view_model.dart';


class ProductInventory extends StatelessWidget {
  const ProductInventory({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InventoryViewModel>(
      create: (context) {
        final viewedCustomer = context.read<UserProvider>().viewedCustomer!;
        final vm = InventoryViewModel(Repository(HttpService()), viewedCustomer.id, viewedCustomer.role);
        vm.loadInventoryData(1);
        return vm;
      },
      child: const _ProductInventoryContent(),
    );
  }
}

class _ProductInventoryContent extends StatefulWidget {
  const _ProductInventoryContent();

  @override
  State<_ProductInventoryContent> createState() => _ProductInventoryContentState();
}

class _ProductInventoryContentState extends State<_ProductInventoryContent> {

  late SearchProvider searchProviderListener;

  @override
  void initState() {
    super.initState();
    searchProviderListener = context.read<SearchProvider>();
    searchProviderListener.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final sp = searchProviderListener;
    final vm = context.read<InventoryViewModel>();

    if (!sp.isSearching) return;
    if (!sp.pendingSearch) return;

    // CASE 1: Search text
    if (sp.searchValue.isNotEmpty) {
      vm.fetchFilterData(null, null, sp.searchValue);
    }
    // CASE 2: Filter Category
    else if (sp.categoryId != 0) {
      vm.fetchFilterData(sp.categoryId, null, null);
    }
    // CASE 3: Filter Model
    else if (sp.modelId != 0) {
      vm.fetchFilterData(null, sp.modelId, null);
    }
    // CASE 4: nothing → reset
    else {
      vm.loadInventoryData(1);
    }

    sp.markHandled();
  }

  @override
  Widget build(BuildContext context) {
    final viewedCustomer = context.watch<UserProvider>().viewedCustomer;
    final searchProvider = context.watch<SearchProvider>();
    debugPrint("searchProvider called");

    return Consumer<InventoryViewModel>(
      builder: (context, vm, _) {

        return Scaffold(
          backgroundColor: Theme.of(context).primaryColorDark.withAlpha(1),
          body: vm.isLoading ? _buildLoading(context) :
          Column(
            children: [
              Expanded(
                child: DataTable2(
                    scrollController: vm.scrollController,
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 1050,
                    dataRowHeight: 35.0,
                    headingRowHeight: 30,
                    headingRowColor: WidgetStateProperty.all<Color>(
                      Colors.cyan.shade50,
                    ),
                    columns: _buildColumns(),
                    rows: searchProvider.isSearching
                        ? _buildFilteredRows(context, vm, viewedCustomer!)
                        : _buildAllRows(context, vm, viewedCustomer!)
                ),
              ),
              if (!searchProvider.isSearching && vm.isLoadingMore) _buildBottomLoader(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Container(
        height: 50,
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width / 2 - 100,
        ),
        child: const LoadingIndicator(
          indicatorType: Indicator.ballPulse,
        ),
      ),
    );
  }

  Widget _buildBottomLoader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 30,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width / 2 - 30,
      ),
      child: const LoadingIndicator(
        indicatorType: Indicator.ballPulse,
      ),
    );
  }

  List<DataColumn2> _buildColumns() {
    return const [
      DataColumn2(label: Center(child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold))), fixedWidth: 70),
      DataColumn2(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.S),
      DataColumn2(label: Text('Model', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.M),
      DataColumn2(label: Text('Device Id', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.S),
      DataColumn2(label: Center(child: Text('M.Date', style: TextStyle(fontWeight: FontWeight.bold))), fixedWidth: 100),
      DataColumn2(label: Center(child: Text('Warranty', style: TextStyle(fontWeight: FontWeight.bold))), fixedWidth: 90),
      DataColumn2(label: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))), fixedWidth: 110),
      DataColumn2(label: Text('Sales Person', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.S),
      DataColumn2(label: Center(child: Text('Modify Date', style: TextStyle(fontWeight: FontWeight.bold))), fixedWidth: 100),
      DataColumn2(label: Center(child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))), fixedWidth: 55),
    ];
  }

  List<DataRow> _buildFilteredRows(BuildContext context, InventoryViewModel vm, UserModel viewedCustomer) {

    return List<DataRow>.generate(
      vm.filterProductInventoryList.length, (index) => DataRow(
        cells: [
          DataCell(Center(child: Text('${index + 1}'))),
          DataCell(Center(child: Text(vm.filterProductInventoryList[index].categoryName))),
          DataCell(Center(child: Text(vm.filterProductInventoryList[index].modelName))),
          DataCell(Center(
            child: SelectableText(vm.filterProductInventoryList[index].deviceId, style: const TextStyle(fontSize: 12)),
          )),
          DataCell(Center(child: Text(vm.filterProductInventoryList[index].dateOfManufacturing))),
          DataCell(Center(child: Text('${vm.filterProductInventoryList[index].warrantyMonths}'))),
          DataCell(_buildStatus(vm.userRole, vm.filterProductInventoryList[index].productStatus)),
          DataCell(Center(child: viewedCustomer.name == vm.filterProductInventoryList[index].latestBuyer
              ? const Text('-')
              : Text(vm.filterProductInventoryList[index].latestBuyer))),
          const DataCell(Center(child: Text('25-09-2023'))),
          _buildActionButton(context, vm, vm.filterProductInventoryList[index], viewedCustomer.id),
        ],
      ),
    );
  }

  List<DataRow> _buildAllRows(BuildContext context, InventoryViewModel vm, UserModel viewedCustomer) {
    return List<DataRow>.generate(
      vm.productInventoryList.length,
          (index) => DataRow(
        color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          return index % 2 == 0 ? Colors.white : Colors.grey.shade100;
        }),
        cells: [
          DataCell(Center(child: Text('${index + 1}', style: const TextStyle(fontSize: 12)))),
          DataCell(Text(vm.productInventoryList[index].categoryName, style: const TextStyle(fontSize: 12))),
          DataCell(Text(vm.productInventoryList[index].modelName, style: const TextStyle(fontSize: 12))),
          DataCell(SelectableText(vm.productInventoryList[index].deviceId, style: const TextStyle(fontSize: 12))),
          DataCell(Center(child: Text(vm.productInventoryList[index].dateOfManufacturing, style: const TextStyle(fontSize: 12)))),
          DataCell(Center(child: Text('${vm.productInventoryList[index].warrantyMonths}', style: const TextStyle(fontSize: 12)))),
          DataCell(_buildStatus(vm.userRole, vm.productInventoryList[index].productStatus)),
          DataCell(viewedCustomer.name == vm.productInventoryList[index].latestBuyer ? const Text('-') :
          Text(vm.productInventoryList[index].latestBuyer, style: const TextStyle(fontSize: 12))),
          const DataCell(Center(child: Text('25-09-2023', style: TextStyle(fontSize: 12)))),
          _buildActionButton(context, vm, vm.productInventoryList[index], viewedCustomer.id),
        ],
      ),
    );
  }

  Widget _buildStatus(UserRole role, int status) {
    Color color;
    String text;

    if (role == UserRole.admin) {
      color = status == 1 ? Colors.pink :
      status == 2 ? Colors.blue :
      status == 3 ? Colors.purple :
      status == 4 ? Colors.yellow :
      status == 5 ? Colors.deepOrangeAccent : Colors.green;

      text = status == 1 ? 'In-Stock' :
      status == 2 ? 'Stock' :
      status == 3 ? 'Sold-Out' : 'Active';
    } else {
      color = status == 1 ? Colors.pink :
      status == 2 ? Colors.purple :
      status == 3 ? Colors.yellow : Colors.green;

      text = status == 2 ? 'In-Stock' :
      status == 3 ? 'Sold-Out' : 'Active';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }

  DataCell _buildActionButton(BuildContext context, InventoryViewModel vm, InventoryModel product, int customerId) {
    if (vm.userRole == UserRole.admin) {
      return DataCell(Center(
        child: IconButton(
          tooltip: 'Edit product',
          onPressed: () {
            vm.getModelByActiveList(
              context,
              product.categoryId,
              product.categoryName,
              product.modelName,
              product.modelDescription,
              product.modelId,
              product.deviceId,
              product.warrantyMonths,
              product.productId,
              customerId,
            );
          },
          icon: const Icon(Icons.edit_outlined),
        ),
      ));
    } else {
      return DataCell(Center(
        child: IconButton(
          tooltip: 'Replace product',
          onPressed: () {
            vm.displayReplaceProductDialog(
              context,
              product.categoryId,
              product.categoryName,
              product.modelName,
              product.modelId,
              product.deviceId,
              product.warrantyMonths,
              product.productId,
              product.buyerId,
              product.modelId,
            );
          },
          icon: const Icon(Icons.repeat),
        ),
      ));
    }
  }

  @override
  void dispose() {
    searchProviderListener.removeListener(_onSearchChanged);
    super.dispose();
  }
}