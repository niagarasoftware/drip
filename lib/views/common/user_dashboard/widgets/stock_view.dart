import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../flavors.dart';
import '../../../../utils/enums.dart';
import '../../../../view_models/product_stock_view_model.dart';

class StockView extends StatelessWidget {
  const StockView({super.key, required this.role, required this.isWide});
  final UserRole role;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProductStockViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isWide
          ? buildProductStock(context, viewModel)
          : buildForNarrow(viewModel),
    );
  }

  Widget buildForNarrow(ProductStockViewModel viewModel){
    return GridView.builder(
      itemCount: viewModel.productStockList.length,
      padding: const EdgeInsets.all(5),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) {
        final stock = viewModel.productStockList[index];

        return Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      color: Colors.black12,
                      child: Image.asset(
                        getProductImage(stock.model),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported);
                        },
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        stock.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          children: [
                            const TextSpan(text: "Model : ", style: TextStyle(color: Colors.black45)),
                            TextSpan(
                              text: stock.model,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          children: [
                            const TextSpan(text: "imeiNo : ", style: TextStyle(color: Colors.black45)),
                            TextSpan(
                              text: stock.imeiNo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildProductStock(BuildContext context, ProductStockViewModel viewModel) {
    return Card(
      elevation: 1,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(10),
                topLeft: Radius.circular(10),
              ),
            ),
            child: ListTile(
              title: RichText(
                text: TextSpan(
                  text: 'Product Stock : ',
                  style: const TextStyle(fontSize: 20, color: Colors.black),
                  children: [
                    TextSpan(
                      text: viewModel.productStockList.length.toString().padLeft(2, '0'),
                      style: const TextStyle(fontSize: 20, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Skeletonizer(
                  enabled: viewModel.isLoadingStock,
                  child: viewModel.productStockList.isNotEmpty?
                  DataTable2(
                    horizontalMargin: 12,
                    columnSpacing: 12,
                    minWidth: 700,
                    border: TableBorder.all(
                      color: Colors.black12,
                    ),
                    headingRowHeight: 30,
                    dataRowHeight: 35,
                    columns: const [
                      DataColumn2(label: Center(child: Text("SNo")), fixedWidth: 50),
                      DataColumn(label: Text("Category")),
                      DataColumn2(label: Text("Model"), size: ColumnSize.L),
                      DataColumn2(label: Center(child: Text("IMEI")), fixedWidth: 140),
                      DataColumn2(label: Center(child: Text("MDate")), fixedWidth: 130),
                      DataColumn2(label: Center(child: Text("Warranty")), fixedWidth: 90),
                    ],
                    rows: List<DataRow>.generate(viewModel.productStockList.length, (index) {
                        final stock = viewModel.productStockList[index];
                        return DataRow(
                          cells: [
                            DataCell(Center(child: Text("${index + 1}"))),
                            DataCell(Text(stock.categoryName)),
                            DataCell(Text(stock.model)),
                            DataCell(Center(child: Text(stock.imeiNo))),
                            DataCell(Center(child: Text(stock.dtOfMnf))),
                            DataCell(Center(child: Text("${stock.warranty}"))),
                          ],
                        );
                      },
                    ),
                  ) :
                  const Center(child: Text('No stock available')),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  String getProductImage(String model) {
    final flavorFolder =
    F.appFlavor!.name.contains('oro') ? 'Oro' : 'SmartComm';

    final m = model.toLowerCase();

    if (m.contains('nova')) {
      return "assets/Images/Png/$flavorFolder/oro nova.png";
    } else if (m.contains('gem')) {
      return "assets/Images/Png/$flavorFolder/category_1.png";
    } else if (m.contains('pump')) {
      return "assets/Images/Png/$flavorFolder/category_2.png";
    }else if (m.contains('level')) {
      return "assets/Images/Png/$flavorFolder/category_3.png";
    }else if (m.contains('weather')) {
      return "assets/Images/Png/$flavorFolder/category_4.png";
    }else if (m.contains('smart')) {
      return "assets/Images/Png/$flavorFolder/category_5.png";
    } else if (m.contains('smart+')) {
      return "assets/Images/Png/$flavorFolder/category_6.png";
    } else if (m.contains('rtu')) {
      return "assets/Images/Png/$flavorFolder/category_7.png";
    }else if (m.contains('rtu+')) {
      return "assets/Images/Png/$flavorFolder/category_8.png";
    }else if (m.contains('sense')) {
      return "assets/Images/Png/$flavorFolder/category_9.png";
    }else if (m.contains('shine')) {
      return "assets/Images/Png/$flavorFolder/oro shine.png";
    }else if (m.contains('elite')) {
      return "assets/Images/Png/$flavorFolder/oro elite.png";
    } else {
      return "assets/Images/Png/$flavorFolder/default.png";
    }
  }
}