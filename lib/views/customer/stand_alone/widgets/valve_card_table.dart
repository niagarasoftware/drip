import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

class ValveCardTable extends StatelessWidget {
  final String title;
  final bool showSwitch;
  final bool switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final List<DataRow> rows;

  const ValveCardTable({
    super.key,
    required this.title,
    required this.showSwitch,
    required this.switchValue,
    required this.onSwitchChanged,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 5, bottom: 5),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(5),
                  topLeft: Radius.circular(5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 5),
                      child: Text(title),
                    ),
                  ),
                  if (showSwitch) ...[
                    VerticalDivider(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
                    SizedBox(
                      width: 60,
                      child: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: switchValue,
                          activeThumbColor: Colors.teal,
                          hoverColor: Colors.pink.shade100,
                          onChanged: onSwitchChanged,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            SizedBox(
              height: rows.length * 40,
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                minWidth: 150,
                dataRowHeight: 40,
                headingRowHeight: 0,
                dataRowColor: WidgetStateProperty.all(Colors.white),
                columns: const [
                  DataColumn2(label: Center(child: Text('')), fixedWidth: 40),
                  DataColumn2(label: Text('Name'), size: ColumnSize.M),
                  DataColumn2(label: Center(child: Text('Status')), fixedWidth: 60),
                ],
                rows: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}