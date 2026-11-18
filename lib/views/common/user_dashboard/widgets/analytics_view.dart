import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../Widgets/sales_chip.dart';
import '../../../../utils/enums.dart';
import '../../../../view_models/analytics_view_model.dart';
import 'sales_bar_chart.dart';


class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key, required this.userType, required this.screenType});
  final int userType;
  final String screenType;


  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AnalyticsViewModel>();

    if(screenType=='Narrow'){
      return Container(
        color: Colors.white,
        child: buildContentBody(context, viewModel),
      );
    }
    else{
      return Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        child: buildContentBody(context, viewModel),
      );
    }
  }

  Widget buildHeader(BuildContext context, AnalyticsViewModel viewModel) {

    return ListTile(
      tileColor: Colors.white,
      leading: (screenType=='Narrow' || screenType=='Middle') ? totalSalesText(viewModel.totalSales) :
      const Text(
        'Analytics Overview',
        style: TextStyle(fontSize: 20),
      ),
      title: screenType!='Narrow' && screenType!='Middle' ? Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          totalSalesText(viewModel.totalSales),
        ],
      )  : null,
      trailing: SegmentedButton<MySegment>(
        segments: const [
          ButtonSegment(value: MySegment.all, label: Text('All'), icon: Icon(Icons.calendar_view_day)),
          ButtonSegment(value: MySegment.year, label: Text('Year'), icon: Icon(Icons.calendar_view_month)),
        ],
        selected: {viewModel.segmentView},
        onSelectionChanged: viewModel.isLoadingSalesData
            ? null
            : (Set<MySegment> newSelection) {
          if (newSelection.isNotEmpty) {
            viewModel.getMySalesData(newSelection.first, userType);
          }
        },
      ),
    );
  }

  Widget totalSalesText(int totalSales) {
    return Text.rich(
      TextSpan(
        text: 'Total Sales: ',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        children: [
          TextSpan(
            text: totalSales.toString().padLeft(2, '0'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget buildContentBody(BuildContext context, AnalyticsViewModel viewModel) {

    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Skeletonizer(
        enabled: viewModel.isLoadingSalesData,
        child: Column(
          children: [
            buildHeader(context, viewModel),
            Expanded(
              child: viewModel.isLoadingSalesData ?
              Container(
                margin: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
              ) : MySalesBarChart(graph: viewModel.mySalesData.graph),
            ),
            const SizedBox(height: 6),
            if ((viewModel.mySalesData.total ?? []).isNotEmpty)
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: List.generate(
                  viewModel.mySalesData.total!.length, (index) => SalesChip(
                    index: index, item: viewModel.mySalesData.total![index]),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}