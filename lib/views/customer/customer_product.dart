import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../view_models/customer/customer_product_view_model.dart';

class CustomerProduct extends StatelessWidget {
  const CustomerProduct({super.key, required this.customerId});
  final int customerId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerProductViewModel(Repository(HttpService()))..getCustomerProducts(customerId),
      child: Consumer<CustomerProductViewModel>(
        builder: (context, viewModel, _) {
          return kIsWeb?Padding(
            padding: const EdgeInsets.all(8.0),
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 1000,
              dataRowHeight: 35.0,
              headingRowHeight: 35,
              headingRowColor: WidgetStateProperty.all<Color>(Theme.of(context).primaryColorDark.withOpacity(0.1)),
              border: TableBorder.all(color: Colors.grey.shade100),
              columns: const [
                DataColumn2(
                    label: Center(child: Text('S.No')),
                    fixedWidth: 70
                ),
                DataColumn2(
                    label: Text('Category'),
                    size: ColumnSize.M
                ),
                DataColumn2(
                    label: Text('Model Name'),
                    size: ColumnSize.M
                ),
                DataColumn2(
                  label: Text('Device ID'),
                  fixedWidth: 170,
                ),
                DataColumn2(
                    label: Center(child: Text('Site Name')),
                    size: ColumnSize.M
                ),
                DataColumn2(
                  label: Center(child: Text('Status')),
                  fixedWidth: 90,
                ),
                DataColumn2(
                  label: Center(child: Text('Modify Date')),
                  fixedWidth: 100,
                ),
              ],
              rows: List<DataRow>.generate(viewModel.productInventoryListCus.length, (index) => DataRow(cells: [
                DataCell(Center(child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                DataCell(Text(viewModel.productInventoryListCus[index].categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataCell(Text(viewModel.productInventoryListCus[index].model, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataCell(SelectableText(
                    viewModel.productInventoryListCus[index].deviceId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                )),
                DataCell(Center(child: Text(viewModel.productInventoryListCus[index].productStatus==3? '-' :
                viewModel.productInventoryListCus[index].siteName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                DataCell(Center(child: viewModel.productInventoryListCus[index].productStatus==3? const Row(children: [CircleAvatar(backgroundColor: Colors.orange, radius: 5,), SizedBox(width: 5,),
                  Text('Free', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))],):
                const Row(children: [CircleAvatar(backgroundColor: Colors.green, radius: 5,), SizedBox(width: 5,), Text('Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))],))),
                DataCell(Center(child: Text(viewModel.getDateTime(viewModel.productInventoryListCus[index].modifyDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              ])),
            ),
          ):
          Scaffold(
            appBar: AppBar(title: const Text('All my devices'),),
            body: ListView.builder(
              itemCount: viewModel.productInventoryListCus.length,
              itemBuilder: (context, index) {
                final device = viewModel.productInventoryListCus[index];

                return  Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Device Category', style: TextStyle(fontSize: 13, color: Colors.black54),),
                                  SizedBox(height: 5,),
                                  Text('Model Name', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                  SizedBox(height: 5,),
                                  Text('Device ID', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                  SizedBox(height: 5,),
                                  Text('Site Name', style: TextStyle(fontSize: 13, color: Colors.black54),),
                                  SizedBox(height: 5,),
                                  Text('Status', style: TextStyle(fontSize: 13, color: Colors.black54),),
                                  SizedBox(height: 5,),
                                  Text('Modify Date', style: TextStyle(fontSize: 13, color: Colors.black54),),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: SizedBox(
                                width: 10,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(':'),
                                    SizedBox(height: 5,),
                                    Text(':'),
                                    SizedBox(height: 5,),
                                    Text(':'),
                                    SizedBox(height: 5,),
                                    Text(':'),
                                    SizedBox(height: 5,),
                                    Text(':'),
                                    SizedBox(height: 5,),
                                    Text(':'),
                                  ],
                                ),
                              ),
                            ),
                            Flexible(
                              flex: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(device.categoryName),
                                  const SizedBox(height: 5,),
                                  Text(device.model, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 5,),
                                  Text(device.deviceId, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 5,),
                                  Text(device.siteName, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 5,),
                                  Center(child: device.productStatus==3? const Row(children: [CircleAvatar(backgroundColor: Colors.orange, radius: 5,), SizedBox(width: 5,),
                                    Text('Free', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))],):
                                  const Row(children: [CircleAvatar(backgroundColor: Colors.green, radius: 5,), SizedBox(width: 5,), Text('Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))],)),
                                  const SizedBox(height: 5,),
                                  Text(device.modifyDate, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );

              },
            ),
          );
        },
      ),
    );
  }
}
