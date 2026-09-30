import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin_dealer/stock_model.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/formatters.dart';
import '../../view_models/admin_dealer/dealer_device_list_view_model.dart';

class DealerDeviceList extends StatelessWidget {
  const DealerDeviceList({
    super.key,
    required this.userId,
    required this.customerName,
    required this.customerId,
    required this.userRole,
    required this.productStockList,
    required this.fromAdminPage,
    //required this.onDeviceListAdded,
  });

  final int userId, customerId;
  final String userRole, customerName;
  final List<StockModel> productStockList;
  final bool fromAdminPage;
  //final Function(Map<String, dynamic>) onDeviceListAdded;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = DealerDeviceListViewModel(
            Repository(HttpService()), userId, customerId, productStockList.length);
        viewModel.loadDeviceList(1);
        return viewModel;
      },
      child: Consumer<DealerDeviceListViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                customerName,
                style: const TextStyle(fontSize: 16),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                tooltip: "Close",
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              actions: [
                MaterialButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                    side: const BorderSide(color: Colors.white54, width: 0.5),
                  ),
                  textColor: Colors.white,
                  onPressed: () => _showAddProductDialog(
                    context,
                    viewModel,
                    productStockList,
                    fromAdminPage,
                  ),
                  child: const Row(
                    children: [
                      Text('Add New Product'),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
            body: viewModel.isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : Column(
              children: [
                Expanded(
                  child: viewModel.dealerDeviceList.isNotEmpty
                      ? DataTable2(
                    scrollController: viewModel.scrollController,
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    headingRowHeight: 30,
                    headingRowColor: WidgetStateProperty.all<Color>(
                        Theme.of(context).primaryColorDark.withAlpha(1)),
                    dataRowHeight: 35,
                    minWidth: 580,
                    columns: const [
                      DataColumn2(
                        label: Text('S.No'),
                        fixedWidth: 40,
                      ),
                      DataColumn2(
                        label: Text('Category'),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('Model'),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('IMEI'),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('Status'),
                        fixedWidth: 90,
                      ),
                      DataColumn2(
                        label: Text('Modify Date'),
                        fixedWidth: 90,
                      ),
                    ],
                    rows: List<DataRow>.generate(
                      viewModel.dealerDeviceList.length,
                          (index) => DataRow(
                        cells: [
                          DataCell(Center(
                            child: Text(
                              '${index + 1}',
                              style: viewModel.commonTextStyle,
                            ),
                          )),
                          DataCell(Text(
                              viewModel.dealerDeviceList[index].categoryName,
                              style: viewModel.commonTextStyle)),
                          DataCell(Text(viewModel.dealerDeviceList[index].model,
                              style: viewModel.commonTextStyle)),
                          DataCell(SelectableText(
                              viewModel.dealerDeviceList[index].deviceId,
                              style: viewModel.commonTextStyle)),
                          DataCell(Center(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 5,
                                  backgroundColor:
                                  viewModel.dealerDeviceList[index].productStatus ==
                                      1
                                      ? Colors.pink
                                      : viewModel.dealerDeviceList[index]
                                      .productStatus ==
                                      2
                                      ? Colors.blue
                                      : viewModel.dealerDeviceList[index]
                                      .productStatus ==
                                      3
                                      ? Colors.purple
                                      : Colors.green,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  viewModel.dealerDeviceList[index].productStatus == 1
                                      ? 'In-Stock'
                                      : viewModel.dealerDeviceList[index]
                                      .productStatus ==
                                      2
                                      ? 'Stock'
                                      : viewModel.dealerDeviceList[index]
                                      .productStatus ==
                                      3
                                      ? 'Free'
                                      : 'Active',
                                  style: viewModel.commonTextStyle,
                                ),
                              ],
                            ),
                          )),
                          DataCell(
                            Text(
                              Formatters()
                                  .formatDate(viewModel.dealerDeviceList[index].modifyDate),
                              style: viewModel.commonTextStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : const Center(
                    child: Text('No device available'),
                  ),
                ),
                viewModel.isLoading
                    ? Container(
                  width: double.infinity,
                  height: 30,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(300, 0, 300, 0),
                  child: const CircularProgressIndicator(),
                )
                    : Container(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddProductDialog(
      BuildContext context,
      DealerDeviceListViewModel viewModel,
      List<StockModel> productStockList,
      bool fromAdminPage,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _AddProductDialog(
        viewModel: viewModel,
        productStockList: productStockList,
        fromAdminPage: fromAdminPage,
      ),
    );
  }
}

class _AddProductDialog extends StatefulWidget {
  const _AddProductDialog({
    required this.viewModel,
    required this.productStockList,
    required this.fromAdminPage,
  });

  final DealerDeviceListViewModel viewModel;
  final List<StockModel> productStockList;
  final bool fromAdminPage;

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Original indices into productStockList / viewModel.selectedProducts,
  /// filtered by the search query and sorted so checked items float to top.
  List<int> get _visibleIndices {
    final all = List<int>.generate(widget.productStockList.length, (i) => i);

    final filtered = _query.trim().isEmpty
        ? all
        : all.where((i) {
      final item = widget.productStockList[i];
      final q = _query.trim().toLowerCase();
      return item.categoryName.toLowerCase().contains(q) ||
          item.imeiNo.toLowerCase().contains(q);
    }).toList();

    filtered.sort((a, b) {
      final aChecked = widget.viewModel.selectedProducts[a];
      final bChecked = widget.viewModel.selectedProducts[b];
      if (aChecked == bChecked) return 0;
      return aChecked ? -1 : 1;
    });

    return filtered;
  }

  void _cancel() {
    setState(() {
      widget.viewModel.selectedProducts =
      List<bool>.filled(widget.productStockList.length, false);
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final indices = _visibleIndices;
    final selectedCount =
        widget.viewModel.selectedProducts.where((v) => v).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add New Product',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (selectedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$selectedCount selected',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search by category or IMEI',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _query = '';
                      });
                    },
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: widget.productStockList.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No stock available to add in the site'),
                  ),
                )
                    : indices.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No matching products')),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: indices.length,
                  itemBuilder: (context, listIndex) {
                    final i = indices[listIndex];
                    final item = widget.productStockList[i];
                    final checked = widget.viewModel.selectedProducts[i];
                    return CheckboxListTile(
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(item.categoryName),
                      subtitle: Text(item.imeiNo),
                      value: checked,
                      onChanged: (_) {
                        setState(() {
                          widget.viewModel.toggleProductSelection(i);
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MaterialButton(
                    color: Colors.red,
                    textColor: Colors.white,
                    onPressed: _cancel,
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 8),
                  MaterialButton(
                    color: Colors.green,
                    textColor: Colors.white,
                    onPressed: widget.productStockList.isEmpty
                        ? null
                        : () {
                      widget.viewModel.addProductToDealer(
                        context,
                        widget.productStockList,
                        widget.fromAdminPage,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('ADD'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}