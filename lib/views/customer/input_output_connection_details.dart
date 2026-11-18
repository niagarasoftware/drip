import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/customer/site_model.dart';

class InputOutputConnectionDetails extends StatelessWidget {
  const InputOutputConnectionDetails({super.key, required this.masterInx, required this.nodes});
  final int masterInx;
  final List<NodeListModel> nodes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('Input/Output connection details'),
      ),
      body: MasonryGridView.count(
        crossAxisCount: kIsWeb ? 4:1,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        itemCount: nodes.length,
        itemBuilder: (context, index) {
          double dynamicHeight = ((int.tryParse(nodes[index].relayOutput) ?? 0) +
              (int.tryParse(nodes[index].latchOutput) ?? 0) +
              (int.tryParse(nodes[index].analogInput) ?? 0) +
              (int.tryParse(nodes[index].digitalInput) ?? 0)) * 35 + 100;
          return Tile(
            index: index,
            masterIndex: masterInx,
            extent: dynamicHeight,
            nodes: nodes,
          );
        },
      ),
    );
  }

}

class Tile extends StatelessWidget {
  final int index, masterIndex;
  final double extent;
  final List<NodeListModel> nodes;

  const Tile({
    Key? key,
    required this.index,
    required this.masterIndex,
    required this.extent,
    required this.nodes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final List<RelayStatus> rlyStatusList = nodes[index].rlyStatus;
    //final List<SensorStatus> sensorStatusList = siteData.master[masterIndex].gemLive[0].nodeList[index].sensor;

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Card(
        elevation: 5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        child: SizedBox(
          height: extent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.maxFinite,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5.0),
                    topRight: Radius.circular(5.0),
                  ),
                ),
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nodes[index].categoryName, style: const TextStyle(fontSize: 13, color: Colors.white),),
                      Text(nodes[index].deviceId, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: rlyStatusList.length*35+30,
                      child: DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 350,
                        dataRowHeight: 35.0,
                        headingRowHeight: 30.0,
                        headingRowColor: WidgetStateProperty.all<Color>(Theme.of(context).primaryColor.withValues(alpha: 0.1)),
                        columns: const [
                          DataColumn2(
                            label: Text('Output', style: TextStyle(fontSize: 13)),
                            fixedWidth: 90,
                          ),
                          DataColumn2(
                              label: Text('Id', style: TextStyle(fontSize: 13),),
                              size: ColumnSize.S
                          ),
                          DataColumn2(
                              label: Text('Name', style: TextStyle(fontSize: 13),),
                              size: ColumnSize.M
                          ),
                        ],
                        rows: List<DataRow>.generate(rlyStatusList.length, (index) {

                          final RelayStatus rly = rlyStatusList.firstWhere(
                                (r) => r.rlyNo == (index + 1),
                            orElse: () => RelayStatus(
                              sNo: -1,
                              name: 'N/A',
                              swName: 'N/A',
                              rlyNo: -1,
                              objType: '',
                            ),
                          );

                          return DataRow(cells: [
                            DataCell(Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(onPressed: () { }, icon: const Icon(Icons.add_circle, color: Colors.black54,),),
                                Text('DO-${index+1}', style: const TextStyle(fontSize: 10),),
                              ],
                            )),
                            DataCell(Text(rly.rlyNo!=-1?'${rly.name}':'--', style: TextStyle(fontSize: 12),)),
                            DataCell(Text(rly.swName!='N/A'?'${rly.swName}':'--', style: TextStyle(fontSize: 12),)),
                          ]);
                        }),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String getOutputInputCount(String cName) {
    switch (cName) {
      case 'ORO PUMP':
        return '5_3';
      case 'ORO PUMP PLUS':
        return '5_12';
      case 'ORO SMART PLUS':
        return '16_14';
      case 'ORO SMART'||'ORO RTU'||'ORO RTU PLUS':
        return '8_4';
      case 'ORO SENSE':
        return '0_7';
      case 'ORO LEVEL':
        return '0_10';
      default:
        return '0_0';
    }
  }

}
