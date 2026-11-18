import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../models/sales_data_model.dart';

class MySalesBarChart extends StatefulWidget {
  const MySalesBarChart({super.key, required this.graph});
  final Map<String, List<Category>>? graph;

  @override
  MySalesChartState createState() => MySalesChartState();
}

class MySalesChartState extends State<MySalesBarChart> {
  int? selectedSeriesIndex;

  @override
  void didUpdateWidget(MySalesBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph) {
      selectedSeriesIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<BarSeries<Category, String>> seriesList = [];

    widget.graph?.forEach((month, categories) {
      seriesList.add(
        BarSeries<Category, String>(
          dataSource: categories,
          xValueMapper: (Category category, int index) => (index + 1).toString(),
          yValueMapper: (Category category, _) => category.totalProduct,
          pointColorMapper: (Category category, _) => category.color,
          name: month,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          initialIsVisible: selectedSeriesIndex == null || selectedSeriesIndex == seriesList.length,
        ),
      );
    });

    return SfCartesianChart(
      key: ValueKey(widget.graph.hashCode),
      enableAxisAnimation: false,
      primaryYAxis: const NumericAxis(),
      primaryXAxis: const CategoryAxis(),
      legend: const Legend(
        isVisible: true,
        toggleSeriesVisibility: false,
      ),
      series: seriesList,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
          final category = data as Category;
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '${category.categoryName}(${category.totalProduct})',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        },
      ),
      isTransposed: true,
      onLegendTapped: (LegendTapArgs args) {
        if (!mounted) return;
        setState(() {
          selectedSeriesIndex = selectedSeriesIndex == args.seriesIndex ? null : args.seriesIndex;
        });
      },
    );
  }
}