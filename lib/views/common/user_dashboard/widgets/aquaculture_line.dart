import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../../../Widgets/pump_widget.dart';
import '../../../../models/customer/site_model.dart';

class AquacultureLine extends StatefulWidget {
  final IrrigationLineModel irrLine;
  final int customerId, controllerId, modelId;
  final String deviceId;

  const AquacultureLine({super.key, required this.irrLine,
    required this.customerId, required this.controllerId,
    required this.modelId, required this.deviceId});


  @override
  State<AquacultureLine> createState() => _AquacultureLineState();
}

class _AquacultureLineState extends State<AquacultureLine> {

  @override
  Widget build(BuildContext context) {

    final aeratorWaterSources = {
      for (var source in widget.irrLine.aeratorSources) source.sNo: source
    }.values.toList();

    if (aeratorWaterSources.isEmpty) {
      return const SizedBox();
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: isMobile ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: aeratorWaterSources
            .map((source) => _buildWaterSource(source))
            .toList(),
      ) : Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: aeratorWaterSources.map((source) {
              final aerators = source.aeratorPump;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        source.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Divider(
                        color: Colors.black54,
                        thickness: 0.3,
                      ),
                      SizedBox(
                        height: 100,
                        child: ReorderableGridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: aerators.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final item = aerators.removeAt(oldIndex);
                              aerators.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, index) {
                            final aerator = aerators[index];
                            return Container(
                              key: ValueKey(aerator.sNo),
                              color:  Colors.transparent,
                              child: Center(
                                child: AeratorWidget(
                                  pump: aerator,
                                  deviceId: widget.deviceId,
                                  customerId: widget.customerId,
                                  controllerId: widget.controllerId,
                                  isMobile: false,
                                  modelId: widget.modelId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildWaterSource(WaterSourceModel source) {
    final aerators = source.aeratorPump;

    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 16),
      child: Container(
        width: MediaQuery.of(context).size.width < 600
            ? double.infinity
            : 300,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              source.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Divider(
              color: Colors.black54,
              thickness: 0.3,
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: aerators.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final aerator = aerators[index];
                return AeratorWidget(
                  pump: aerator,
                  deviceId: widget.deviceId,
                  customerId: widget.customerId,
                  controllerId: widget.controllerId,
                  isMobile: MediaQuery.of(context).size.width < 600,
                  modelId: widget.modelId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}
