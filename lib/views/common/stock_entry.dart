import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/admin_dealer/new_stock_model.dart';
import '../../models/admin_dealer/simple_category.dart';
import '../../providers/user_provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../view_models/admin_dealer/stock_entry_view_model.dart';

class StockEntry extends StatefulWidget {
  const StockEntry({super.key, required this.isNarrow});
  final bool isNarrow;

  @override
  State<StockEntry> createState() => _StockEntryState();
}

class _StockEntryState extends State<StockEntry> {
  @override
  Widget build(BuildContext context) {
    final viewedCustomer = Provider.of<UserProvider>(context).viewedCustomer;
    return ChangeNotifierProvider(
      create: (_) => StockEntryViewModel(Repository(HttpService()))..getMyStock(viewedCustomer!.id, 1),
      child: Consumer<StockEntryViewModel>(
        builder: (context, viewModel, _) {

          if(widget.isNarrow) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 10, top: 8),
                              child: Card(
                                color: Colors.white,
                                elevation: 0,
                                surfaceTintColor: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<SimpleCategory>(
                                        value: viewModel.selectedCategory,
                                        hint: const Text("Select a category"),
                                        decoration: _inputDecoration(),
                                        items: viewModel.categoryList.map((category) {
                                          return DropdownMenuItem(
                                            value: category,
                                            child: Text(category.name),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            viewModel.selectedCategoryId = newValue.id;
                                            viewModel.modelTextController.clear();
                                            viewModel.selectedModelId = 0;
                                            viewModel.getModelsByCategoryId();
                                            viewModel.selectedCategory = newValue;
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      DropdownMenu<ProductModel>(
                                        controller: viewModel.modelTextController,
                                        label: const Text('Model'),
                                        width: double.infinity,
                                        dropdownMenuEntries: viewModel.modelEntries,
                                        inputDecorationTheme: _inputDecorationTheme(),
                                        onSelected: (mdl) {
                                          if (mdl != null) {
                                            viewModel.selectedModelId = mdl.modelId;
                                            viewModel.modelTextController.text = mdl.modelName;
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      _textField(
                                        controller: viewModel.imeiController,
                                        label: "Device ID",
                                        maxLength: 12,
                                        validator: _requiredValidator,
                                      ),
                                      const SizedBox(height: 12),

                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(flex:1,child: _textField(
                                            controller: viewModel.warrantyMonthsController,
                                            label: "Warranty Months",
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          )),

                                          const SizedBox(width: 8),

                                          Flexible(flex:1,child: _textField(
                                            controller: viewModel.manufacturingDateController,
                                            label: "Manufacturing Date",
                                            readOnly: true,
                                            onTap: () async {
                                              DateTime? date = await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime(1900),
                                                lastDate: DateTime(2100),
                                              );
                                              if (date != null) {
                                                viewModel.manufacturingDateController.text =
                                                    DateFormat('dd-MM-yyyy').format(date);
                                              }
                                            },
                                          )),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: MaterialButton(
                                          color: Colors.blue, // Background color
                                          textColor: Colors.white, // Text & icon color
                                          onPressed: viewModel.saveStockListToLocal,
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add),
                                              SizedBox(width: 8),
                                              Text("Add"),
                                              SizedBox(width: 5),
                                            ],
                                          ),
                                        ),
                                      ),

                                      if (viewModel.errorMsg.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(viewModel.errorMsg,
                                            style: const TextStyle(color: Colors.red)),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if(viewModel.addedProductList.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 10, right: 10, top: 8),
                              child: Card(
                                elevation: 0,
                                color: Colors.white,
                                child: Column(
                                  children: [
                                    ListTile(
                                      contentPadding: const EdgeInsets.only(left: 16, right: 5),
                                      title: const Text('STOCK OVERVIEW', style: TextStyle(fontSize: 17, color: Colors.black87)),
                                      trailing: TextButton(
                                        onPressed: (){
                                          if(viewModel.addedProductList.isNotEmpty)
                                          {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text('Confirmation'),
                                                  content: const Text('Are you sure! You want to save the product to Stock list?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => viewModel.addProductStock(viewedCustomer!.id),
                                                      child: const Text('Save'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }else{
                                            //_showAlertDialog('Alert Message', 'Product Empty!');
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                        ),
                                        child: const SizedBox(
                                          width: 120,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(Icons.save_outlined),
                                              SizedBox(width: 8),
                                              Text('SAVE TO STOCK', style: TextStyle(fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      color: Colors.white,
                                      height: (viewModel.addedProductList.length * 45.0) + 40,
                                      child: Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: DataTable2(
                                          columnSpacing: 12,
                                          horizontalMargin: 12,
                                          minWidth: 650,
                                          dataRowHeight: 40.0,
                                          headingRowHeight: 40.0,
                                          headingRowColor: WidgetStateProperty.all<Color>(
                                            Theme.of(context).primaryColorLight.withOpacity(0.1),
                                          ),
                                          columns: const [
                                            DataColumn2(label: Center(child: Text('S.No')), fixedWidth: 32),
                                            DataColumn2(label: Text('Category'), size: ColumnSize.M),
                                            DataColumn2(label: Text('Model Name'), size: ColumnSize.M),
                                            DataColumn2(label: Text('Device Id'), size: ColumnSize.M),
                                            DataColumn2(label: Center(child: Text('M.Date')), fixedWidth: 95),
                                            DataColumn2(label: Center(child: Text('Warranty')), fixedWidth: 80),
                                            DataColumn2(label: Center(child: Text('Action')), fixedWidth: 45),
                                          ],
                                          rows: List<DataRow>.generate(
                                            viewModel.addedProductList.length,
                                                (index) => DataRow(cells: [
                                              DataCell(Center(child: Text('${index + 1}'))),
                                              DataCell(Text(viewModel.addedProductList[index]['categoryName'])),
                                              DataCell(Text(viewModel.addedProductList[index]['modelName'])),
                                              DataCell(Text('${viewModel.addedProductList[index]['deviceId']}')),
                                              DataCell(Center(child: Text(viewModel.addedProductList[index]['dateOfManufacturing']))),
                                              DataCell(Center(child: Text('${viewModel.addedProductList[index]['warrantyMonths']}'))),
                                              DataCell(Center(
                                                child: IconButton(
                                                  tooltip: 'Remove',
                                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                                  onPressed: () => viewModel.removeNewStock(index),
                                                ),
                                              )),
                                            ]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
                            child: Card(
                              elevation: 0,
                              color: Colors.white,
                              child: Column(
                                children: [
                                  const ListTile(
                                      title: Text('ALL MY STOCKS', style: TextStyle(fontSize: 17, color: Colors.black87))),
                                  Container(
                                    color: Colors.white,
                                    height: (viewModel.productStockList.length * 45.0) + 40,
                                    child: viewModel.productStockList.isNotEmpty ? Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: DataTable2(
                                        columnSpacing: 12,
                                        horizontalMargin: 12,
                                        minWidth: 650,
                                        headingRowColor: WidgetStateProperty.all<Color>(
                                          Theme.of(context).primaryColorLight.withOpacity(0.1),
                                        ),
                                        headingRowHeight: 40,
                                        dataRowHeight: 40,
                                        columns: const [
                                          DataColumn2(label: Center(child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold))), fixedWidth: 50),
                                          DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Model', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn2(label: Center(child: Text('IMEI', style: TextStyle(fontWeight: FontWeight.bold))), size: ColumnSize.L),
                                          DataColumn2(label: Center(child: Text('M.Date', style: TextStyle(fontWeight: FontWeight.bold))), fixedWidth: 150),
                                          DataColumn2(label: Center(child: Text('Warranty', style: TextStyle(fontWeight: FontWeight.bold))), fixedWidth: 100),
                                        ],
                                        rows: List<DataRow>.generate(
                                          viewModel.productStockList.length,
                                              (index) => DataRow(cells: [
                                            DataCell(Center(child: Text('${index + 1}'))),
                                            DataCell(Text(viewModel.productStockList[index].categoryName)),
                                            DataCell(Text(viewModel.productStockList[index].model)),
                                            DataCell(Center(child: Text(viewModel.productStockList[index].imeiNo))),
                                            DataCell(Center(child: Text(viewModel.productStockList[index].dtOfMnf))),
                                            DataCell(Center(child: Text('${viewModel.productStockList[index].warranty}'))),
                                          ]),
                                        ),
                                      ),
                                    ):
                                    const Center(child: Text('SOLD OUT', style: TextStyle(fontSize: 16))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return Scaffold(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: MediaQuery.sizeOf(context).width,
                    height: 80,
                    color: Colors.white24,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 220,
                              height: 50,
                              child: DropdownButtonFormField<SimpleCategory>(
                                value: viewModel.selectedCategory,
                                hint: const Text("Select a category",),
                                decoration: const InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black26, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black38, width: 1.5),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: viewModel.categoryList.map((category) {
                                  return DropdownMenuItem<SimpleCategory>(
                                    value: category,
                                    child: Text(
                                      category.name,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (SimpleCategory? newValue) {
                                  viewModel.selectedCategoryId = newValue!.id;
                                  viewModel.modelTextController.clear();
                                  viewModel.selectedModelId = 0;
                                  viewModel.getModelsByCategoryId();
                                  viewModel.selectedCategory = newValue;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownMenu<ProductModel>(
                              controller: viewModel.modelTextController,
                              width: 205,
                              label: const Text('Model'),
                              dropdownMenuEntries: viewModel.modelEntries,
                              inputDecorationTheme: const InputDecorationTheme(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black26, width: 1)
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black26, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black38, width: 1.5),
                                ),
                              ),
                              onSelected: (ProductModel? mdl) {
                                viewModel.selectedModelId = mdl!.modelId;
                                viewModel.modelTextController.clear();
                                viewModel.modelTextController.text = mdl.modelName;
                              },
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 200,
                              child: TextFormField(
                                maxLength: 12,
                                controller: viewModel.imeiController,
                                decoration: const InputDecoration(
                                  counterText: '',
                                  labelText: 'Device ID',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.black26, width: 1)
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black26, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black38, width: 1.5),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please fill out this field';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 125,
                              child: TextFormField(
                                controller: viewModel.warrantyMonthsController,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelText: 'warranty months',
                                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.black26, width: 1)
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black26, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black38, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 120,
                              child: TextFormField(
                                validator: (value){
                                  if(value==null || value.isEmpty){
                                    return 'Please fill out this field';
                                  }
                                  return null;
                                },
                                controller: viewModel.manufacturingDateController,
                                decoration: const InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelText: 'Date',
                                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.black26, width: 1)
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black26, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black38, width: 1.5),
                                  ),
                                ),
                                onTap: ()
                                async {
                                  DateTime? date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime(2100),
                                  );

                                  if (date != null) {
                                    viewModel.manufacturingDateController.text = DateFormat('dd-MM-yyyy').format(date);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: ()  => viewModel.saveStockListToLocal(),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.add),
                                  SizedBox(width: 8),
                                  Text('ADD', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        viewModel.errorMsg!=''? SizedBox(
                            width: 500,
                            child: Center(child: Text(viewModel.errorMsg, style: const TextStyle(color: Colors.red),))
                        ):
                        const SizedBox(),
                      ],
                    )
                ),
                const Divider(height:0, color: Colors.black12),
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height-150,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if(viewModel.addedProductList.isNotEmpty) ...[
                            Padding(
                              padding: widget.isNarrow ? const EdgeInsets.only(left: 3, top: 10) :
                              const EdgeInsets.only(left: 50, top: 10),
                              child: Row(
                                children: [
                                  const Text('STOCK OVERVIEW', style: TextStyle(fontSize: 15, color: Colors.black87)),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: (){
                                      if(viewModel.addedProductList.isNotEmpty)
                                      {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Confirmation'),
                                              content: const Text('Are you sure! You want to save the product to Stock list?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => viewModel.addProductStock(viewedCustomer!.id),
                                                  child: const Text('Save'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }else{
                                        //_showAlertDialog('Alert Message', 'Product Empty!');
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save_outlined),
                                        SizedBox(width: 8),
                                        Text('SAVE TO STOCK', style: TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 50)
                                ],
                              ),
                            ),
                            Padding(
                              padding:widget.isNarrow ?
                              const EdgeInsets.only(left: 3, right: 3, top: 8, bottom: 8) :
                              const EdgeInsets.only(left: 50, right: 50, top: 8, bottom: 8),
                              child: Container(
                                color: Colors.white,
                                height: (viewModel.addedProductList.length * 40.0) + 40,
                                child: DataTable2(
                                  columnSpacing: 12,
                                  horizontalMargin: 12,
                                  minWidth: 600,
                                  dataRowHeight: 40.0,
                                  headingRowHeight: 40.0,
                                  border: TableBorder.all(color: Colors.black12),
                                  headingRowColor: WidgetStateProperty.all<Color>(
                                    Theme.of(context).primaryColorLight.withOpacity(0.1),
                                  ),
                                  columns: const [
                                    DataColumn2(label: Center(child: Text('S.No')), fixedWidth: 32),
                                    DataColumn2(label: Text('Category'), size: ColumnSize.M),
                                    DataColumn2(label: Text('Model Name'), size: ColumnSize.M),
                                    DataColumn2(label: Text('Device Id'), size: ColumnSize.M),
                                    DataColumn2(label: Center(child: Text('M.Date')), fixedWidth: 100),
                                    DataColumn2(label: Center(child: Text('Warranty')), fixedWidth: 100),
                                    DataColumn2(label: Center(child: Text('Action')), fixedWidth: 50),
                                  ],
                                  rows: List<DataRow>.generate(
                                    viewModel.addedProductList.length,
                                        (index) => DataRow(cells: [
                                      DataCell(Center(child: Text('${index + 1}'))),
                                      DataCell(Text(viewModel.addedProductList[index]['categoryName'])),
                                      DataCell(Text(viewModel.addedProductList[index]['modelName'])),
                                      DataCell(Text('${viewModel.addedProductList[index]['deviceId']}')),
                                      DataCell(Center(child: Text(viewModel.addedProductList[index]['dateOfManufacturing']))),
                                      DataCell(Center(child: Text('${viewModel.addedProductList[index]['warrantyMonths']}'))),
                                      DataCell(Center(
                                        child: IconButton(
                                          tooltip: 'Remove',
                                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                                          onPressed: () => viewModel.removeNewStock(index),
                                        ),
                                      )),
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          Padding(
                            padding: widget.isNarrow ?
                            const EdgeInsets.only(left: 5, top: 10):
                            const EdgeInsets.only(left: 50, top: 10),
                            child: const Text('ALL MY STOCKS', style: TextStyle(fontSize: 15, color: Colors.black87)),
                          ),

                          Padding(
                            padding: widget.isNarrow ?
                            const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8):
                            const EdgeInsets.only(left: 50, right: 50, top: 8, bottom: 8),
                            child: Container(
                              color: Colors.white,
                              height: (viewModel.productStockList.length * 40.0) + 40,
                              child: viewModel.productStockList.isNotEmpty ? DataTable2(
                                columnSpacing: 12,
                                horizontalMargin: 12,
                                minWidth: 650,
                                border: TableBorder.all(color: Colors.black12),
                                headingRowColor: WidgetStateProperty.all<Color>(
                                  Theme.of(context).primaryColorLight.withOpacity(0.1),
                                ),
                                headingRowHeight: 40,
                                dataRowHeight: 40,
                                columns: const [
                                  DataColumn2(label: Center(child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold))), fixedWidth: 50),
                                  DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Model', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn2(label: Center(child: Text('IMEI', style: TextStyle(fontWeight: FontWeight.bold))), size: ColumnSize.L),
                                  DataColumn2(label: Center(child: Text('M.Date', style: TextStyle(fontWeight: FontWeight.bold))), fixedWidth: 150),
                                  DataColumn2(label: Center(child: Text('Warranty', style: TextStyle(fontWeight: FontWeight.bold))), fixedWidth: 100),
                                ],
                                rows: List<DataRow>.generate(
                                  viewModel.productStockList.length,
                                      (index) => DataRow(cells: [
                                    DataCell(Center(child: Text('${index + 1}'))),
                                    DataCell(Text(viewModel.productStockList[index].categoryName)),
                                    DataCell(Text(viewModel.productStockList[index].model)),
                                    DataCell(Center(child: Text(viewModel.productStockList[index].imeiNo))),
                                    DataCell(Center(child: Text(viewModel.productStockList[index].dtOfMnf))),
                                    DataCell(Center(child: Text('${viewModel.productStockList[index].warranty}'))),
                                  ]),
                                ),
                              ):
                              const Center(child: Text('SOLD OUT', style: TextStyle(fontSize: 20))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration() => const InputDecoration(
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
  );

  InputDecorationTheme _inputDecorationTheme() => const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(),
  );


  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        return TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLength: maxLength,
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: inputFormatters,
          validator: validator,
          onTap: onTap,
          decoration: InputDecoration(
            labelText: label,
            counterText: '',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,

            suffixIcon: label == "Device ID" ?  controller.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => controller.clear(),
            )
                : null : null,
          ),
        );
      },
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please fill out this field';
    }
    return null;
  }

}
