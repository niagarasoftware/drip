import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

class CustomCardTable extends StatelessWidget {
  final String title;
  final List<DataRow> rows;

  const CustomCardTable({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorLight.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5.0),
                topRight: Radius.circular(5.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: Text(title, textAlign: TextAlign.left),
            ),
          ),
          SizedBox(
            height: rows.length * 40.0,
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 150,
              dataRowHeight: 40.0,
              headingRowHeight: 0,
              dataRowColor: WidgetStateProperty.all(Colors.white),
              columns: const [
                DataColumn2(label: Text(''), fixedWidth: 35),
                DataColumn2(label: Text('Name'), size: ColumnSize.M),
                DataColumn2(label: Text(''), fixedWidth: 50),
              ],
              rows: rows,
            ),
          ),
        ],
      ),
    );
  }
}