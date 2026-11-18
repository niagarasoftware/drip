import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../../StateManagement/mqtt_payload_provider.dart';
import '../../../../models/customer/extensions/program_extensions.dart';
import '../../../../models/customer/fertilizer_site_live_model.dart';
import '../../../../utils/constants.dart';
import '../../../../view_models/customer/customer_screen_controller_view_model.dart';

class FertilizerLivePanel extends StatefulWidget {
  final String deviceId;
  final int controllerId;
  final int customerId;
  final bool isWide;

  const FertilizerLivePanel({
    super.key,
    required this.deviceId,
    required this.controllerId,
    required this.customerId,
    required this.isWide,
  });

  @override
  State<FertilizerLivePanel> createState() => _FertilizerLivePanelState();
}

class _FertilizerLivePanelState extends State<FertilizerLivePanel> {
  bool _isDisposed = false;
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();

    _tooltipBehavior = TooltipBehavior(
      enable: true,
      header: '',
      format: 'point.x : point.y',
    );

    // Initial call
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<CustomerScreenControllerViewModel>()
          .onFertilizerLiveSync();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MqttPayloadProvider>(
      builder: (context, mqtt, _) {
        if (_isDisposed) {
          return const SizedBox.shrink();
        }

        if (mqtt.fertilizerSiteMap.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text("Waiting for live data..."),
            ),
          );
        }

        if (mqtt.fertilizerSiteMap.isEmpty ||
            mqtt.fertilizerSiteMap.values.first.valve.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("No Live Data Available"),),
          );
        }

        final site = mqtt.fertilizerSiteMap.values.first;

        final viewModel = Provider.of<CustomerScreenControllerViewModel>(context);
        final scheduledProgram = viewModel.mySiteList.data[viewModel.sIndex]
            .master[viewModel.mIndex].programList;

        String programName = scheduledProgram.getProgramName(site.programSNo);
        String zoneName = scheduledProgram.getSequenceName(site.programSNo, site.zoneSNo);

        final configObjects = viewModel.mySiteList.data[viewModel.sIndex]
            .master[viewModel.mIndex]
            .configObjects;

        //pump ----------------------------------------------------------------------
        List<double> pumpSerials = site.pump.isNotEmpty
            ? site.pump.split('_').map((e) => double.tryParse(e) ?? 0).toList() : [];
        List<String> pumpNames = pumpSerials
            .map((serial) => configObjects.getObjectName(serial))
            .toList();
        List<String> pumpStatuses = site.pumpStatus.isNotEmpty ? site.pumpStatus.split('_') : [];

        //valve---------------------------------------------------------------
        List<double> valveSerials = site.valve.isNotEmpty ? site.valve.split('_')
            .map((e) => double.tryParse(e) ?? 0).toList() : [];
        List<String> valveNames = valveSerials
            .map((serial) => configObjects.getObjectName(serial))
            .toList();
        List<String> valveStatuses = site.valveStatus.isNotEmpty ?
        site.valveStatus.split('_') : [];


        //booster--------------------------------------------------------------------
        List<double> boosterSerials = site.booster.isNotEmpty ? site.booster.split('_')
            .map((e) => double.tryParse(e) ?? 0).toList() : [];
        List<String> boosterNames = boosterSerials
            .map((serial) => configObjects.getObjectName(serial))
            .toList();
        List<String> boosterStatuses = site.boosterStatus.isNotEmpty ?
        site.boosterStatus.split('_') : [];

        //sensors==================================================================
        List<double> pressureInSerials = site.pressureIn.isNotEmpty ? site.pressureIn.split('_')
            .map((e) => double.tryParse(e) ?? 0).toList() : [];
        List<String> pressureInNames = pressureInSerials
            .map((serial) => configObjects.getObjectName(serial))
            .toList();
        List<String> pressureInValues = site.pressureInValue.isNotEmpty ?
        site.pressureInValue.split('_') : [];


        List<double> pressureOutSerials = site.pressureOut.isNotEmpty ? site.pressureOut.split('_')
            .map((e) => double.tryParse(e) ?? 0).toList() : [];
        List<String> pressureOutNames = pressureOutSerials
            .map((serial) => configObjects.getObjectName(serial))
            .toList();
        List<String> pressureOutValues = site.pressureOutValue.isNotEmpty ?
        site.pressureOutValue.split('_') : [];


        List<double> waterMeterSerials = site.waterMeter.isNotEmpty ? site.waterMeter.split('_')
            .map((e) => double.tryParse(e) ?? 0).toList() : [];
        List<String> waterMeterNames = waterMeterSerials
            .map((serial) => configObjects.getObjectName(serial))
            .toList();
        List<String> waterMeterValues = site.waterMeterValue.isNotEmpty ?
        site.waterMeterValue.split('_') : [];

        //frt channel--------------------------------------------------------
        List<ChannelDurationBarModel> chartData = [];

        List<double> channelSerials = site.fertilizerChannel.isNotEmpty
            ? site.fertilizerChannel.split('_').map((e) => double.tryParse(e) ?? 0).toList() : [];

        for (final serial in channelSerials) {
          final channel = mqtt.fertilizerChannelMap[serial.toString()];
          if (channel == null) continue;
          final channelName = configObjects.getObjectName(serial);
          chartData.add(
            ChannelDurationBarModel(
              channel: channelName,
              total: _parseDuration(channel.fertilizerChannelDuration),
              completed: _parseDuration(channel.fertilizerChannelDurationCompleted),
            ),
          );
        }

        return Container(
            width: widget.isWide ? 600 : MediaQuery.sizeOf(context).width,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [

                        buildMainStatusCard(
                          programName: programName,
                          zoneName: zoneName,
                          pumpNames: pumpNames,
                          pumpStatuses: pumpStatuses,
                          valveNames: valveNames,
                          valveStatuses: valveStatuses,
                          boosterNames: boosterNames,
                          boosterStatus: boosterStatuses,
                        ),

                        buildIrrigationGauge(site),

                        buildLiveChannelChart(chartData),

                        buildGraphRow(site),

                        buildSensorsCard(
                          prsInNames: pressureInNames,
                          prsInValue: pressureInValues,
                          prsOutName: pressureOutNames,
                          prsOutValue: pressureOutValues,
                          wmNames: waterMeterNames,
                          wmValue: waterMeterValues,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
        );
      },
    );
  }

  double _parseDuration(String time) {
    if (time.isEmpty) return 0;

    final parts = time.split(':');
    if (parts.length != 3) return 0;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;

    return (hours * 3600 + minutes * 60 + seconds).toDouble();
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Fertilizer Live Monitoring",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          Row(
            children: [
              IconButton(onPressed: () {
                context
                    .read<CustomerScreenControllerViewModel>()
                    .onFertilizerLiveSync();
              }, icon: const Icon(Icons.refresh)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close_outlined, size: 20, color: Colors.black54),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(String program, String zone) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomLeft: Radius.circular(5),
                ),
                border: Border.all(
                  color: Colors.black12,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 5),
                  const Icon(Icons.event_note, color: Colors.grey),
                  const SizedBox(width: 5),
                  const Text("Program : ", style: TextStyle(color: Colors.grey)),
                  Text(program, style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
        ),
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
              border: Border.all(
                color: Colors.black12,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 5),
                const Icon(Icons.location_on, color: Colors.grey),
                const SizedBox(width: 5),
                const Text("Zone : ", style: TextStyle(color: Colors.grey)),
                Text(zone, style: const TextStyle(color: Colors.black)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildMainStatusCard({
    required String programName,
    required String zoneName,
    required List<String> pumpNames,
    required List<String> pumpStatuses,
    required List<String> valveNames,
    required List<String> valveStatuses,
    required List<String> boosterNames,
    required List<String> boosterStatus,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildInfoRow(programName, zoneName),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child : _buildDeviceRow(
                  title: "Running Pumps",
                  assetType: "pump",
                  itemNames: pumpNames,
                  statuses: pumpStatuses,
                )
              ),
              const SizedBox(width: 8),
              Expanded(
                child : _buildDeviceRow(
                  title: "Opened Valves",
                  assetType: "valve",
                  itemNames: valveNames,
                  statuses: valveStatuses,
                )
              ),
              const SizedBox(width: 8),
              Expanded(
                  child : _buildDeviceRow(
                    title: "Booster pump",
                    assetType: "booster",
                    itemNames: boosterNames,
                    statuses: boosterStatus,
                  )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildLiveChannelChart(List<ChannelDurationBarModel> chartData) {
    return SizedBox(
      height: (chartData.length * 45)+80,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Padding(
          padding: const EdgeInsets.only(right: 5),
          child: SfCartesianChart(
            legend: const Legend(
              isVisible: true,
              position: LegendPosition.top,
              alignment: ChartAlignment.far,
            ),

            primaryXAxis: const CategoryAxis(),
            primaryYAxis: const NumericAxis(),
              series: <BarSeries<ChannelDurationBarModel, String>>[
                BarSeries<ChannelDurationBarModel, String>(
                  name: "Total Duration",
                  dataSource: chartData,
                  color: Colors.indigo,
                  xValueMapper: (data, _) => data.channel,
                  yValueMapper: (data, _) => data.total,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.outer,
                    builder: (dynamic data, dynamic point, dynamic series,
                        int pointIndex, int seriesIndex) {
                      final model = data as ChannelDurationBarModel;
                      return Text(
                        formatSeconds(model.total),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),

                BarSeries<ChannelDurationBarModel, String>(
                  name: "Completed",
                  dataSource: chartData,
                  color: Colors.green,
                  xValueMapper: (data, _) => data.channel,
                  yValueMapper: (data, _) => data.completed,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.outer,
                    builder: (dynamic data, dynamic point, dynamic series,
                        int pointIndex, int seriesIndex) {
                      final model = data as ChannelDurationBarModel;
                      return Text(
                        formatSeconds(model.completed),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ],
          ),
        ),
      ),
    );
  }

  String formatSeconds(double seconds) {
    final int sec = seconds.toInt();

    final int hours = sec ~/ 3600;
    final int minutes = (sec % 3600) ~/ 60;
    final int remainingSeconds = sec % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildDeviceRow({
    required String title,
    required String assetType,
    required List<String> itemNames,
    required List<String> statuses,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(
          color: Colors.black12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 5),
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          const Divider(height: 8, color: Colors.black12),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: List.generate(itemNames.length, (index) {

              final statusValue =
              (index < statuses.length && statuses[index].isNotEmpty)
                  ? int.tryParse(statuses[index]) ?? 0
                  : 0;

              return SizedBox(
                width: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                        height: 60,
                        child: AppConstants.getAssetForFrtLive(assetType, statusValue)
                    ),
                    Text(
                      itemNames[index],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget buildStatusBox(
      String title,
      List<String> numbers,
      List<String> status,
      IconData icon,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(numbers.length, (i) {
                final isOn =
                    i < status.length && status[i] == "1";
                return Column(
                  children: [
                    Icon(icon,
                        color:
                        isOn ? Colors.green : Colors.red),
                    Text(numbers[i]),
                  ],
                );
              }),
            )
          ],
        ),
      ),
    );
  }

  Widget buildGraphRow(FertilizerSiteLiveModel site) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14),
      child: Column(
        children: [
          buildGraphCard("EC", site.ecDataList),
          buildGraphCard("pH", site.phDataList),
        ],
      ),
    );
  }

  Widget buildGraphCard(String title, List<TimeValueModel> data) {
    final latestValue =
    data.isNotEmpty ? data.last.value.toStringAsFixed(2) : "--";

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
              Text(
                latestValue,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 100,
            child: data.isEmpty ? const Center(child: Text("No Data")) :
            SfCartesianChart(
              tooltipBehavior: _tooltipBehavior,
              primaryXAxis: const CategoryAxis(
                labelStyle: TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
              primaryYAxis: const NumericAxis(
                labelStyle: TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                ),
              ),
              series: <LineSeries<TimeValueModel, String>>[
                LineSeries<TimeValueModel, String>(
                  dataSource: data,
                  xValueMapper: (item, _) => item.time,
                  yValueMapper: (item, _) => item.value,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                  ),
                  enableTooltip: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSensorsCard({
    required List<String> prsInNames,
    required List<String> prsInValue,
    required List<String> prsOutName,
    required List<String> prsOutValue,
    required List<String> wmNames,
    required List<String> wmValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child : _buildSensorRow(
                title: "Pressure IN",
                sensorType: "Pressure Sensor",
                sensorNames: prsInNames,
                value: prsInValue,
              )
          ),
          const SizedBox(width: 8),
          Expanded(
              child : _buildSensorRow(
                title: "Pressure OUT",
                sensorType: "Pressure Sensor",
                sensorNames: prsOutName,
                value: prsOutValue,
              )
          ),
          const SizedBox(width: 8),
          Expanded(
              child : _buildSensorRow(
                title: "Water Meter",
                sensorType: "Water Meter",
                sensorNames: wmNames,
                value: wmValue,
              )
          ),
        ],
      ),
    );
  }

  Widget _buildSensorRow({
    required String title,
    required String sensorType,
    required List<String> sensorNames,
    required List<String> value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius:const BorderRadius.all(Radius.circular(5)),
        border: Border.all(
          color: Colors.black12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const Divider(height: 8, color: Colors.black12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(sensorNames.length, (index) {

              final snrValue = (index < value.length && value[index].isNotEmpty)
                  ? double.tryParse(value[index]) ?? 0.0
                  : 0.0;

              return Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: SfRadialGauge(
                    axes: <RadialAxis>[
                      RadialAxis(
                        minimum: 0,
                        maximum: 10,
                        ranges: <GaugeRange>[
                          GaugeRange(startValue: 0, endValue: 2, color: Colors.red),
                          GaugeRange(startValue: 2, endValue: 4, color: Colors.orange),
                          GaugeRange(startValue: 4, endValue: 10, color: Colors.green),
                        ],
                        pointers: <GaugePointer>[
                          NeedlePointer(
                            value: snrValue,
                            needleLength: 0.7,
                            needleStartWidth: 1,
                            needleEndWidth: 5,
                            needleColor: Colors.black87,
                            enableAnimation: true,
                            animationDuration: 800,
                            knobStyle: const KnobStyle(
                              knobRadius: 0.09,
                              color: Colors.black,
                            ),
                          ),
                        ],
                        annotations: <GaugeAnnotation>[
                          GaugeAnnotation(
                            widget: Text(
                              snrValue.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            angle: 90,
                            positionFactor: 0.5,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget buildIrrigationGauge(FertilizerSiteLiveModel site) {
    final method = site.irrigationMethod.toLowerCase();

    final preTime = method == "1"
        ? parseTimeToMinutes(site.preTimeQty)
        : double.tryParse(site.preTimeQty) ?? 0;

    final postTime = method == "1"
        ? parseTimeToMinutes(site.postTimeQty)
        : double.tryParse(site.postTimeQty) ?? 0;

    final durationQty = method == "1"
        ? parseTimeToMinutes(site.irrigationDurationQty)
        : double.tryParse(site.irrigationDurationQty) ?? 0;

    final durationCompleted = method == "1"
        ? parseTimeToMinutes(site.irrigationDurationCompleted)
        : double.tryParse(site.irrigationDurationCompleted) ?? 0;

    final quantityCompleted =
        double.tryParse(site.irrigationQuantityCompleted) ?? 0;

    final currentProgress =
    method == "1" ? durationCompleted : quantityCompleted;
    final totalRange = preTime + durationQty + postTime;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              "Irrigation Progress (${method == "1" ? "Time" : "Quantity"})",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 10),

          SfLinearGauge(
            minimum: 0,
            maximum: totalRange == 0 ? 100 : totalRange,
            showTicks: false,
            showLabels: false,

            axisTrackStyle: const LinearAxisTrackStyle(
              thickness: 25,
              color: Colors.black12,
            ),

            ranges: [
              LinearGaugeRange(
                startValue: 0,
                endValue: preTime,
                color: Colors.blue,
              ),
              LinearGaugeRange(
                startValue: preTime,
                endValue: preTime + durationQty,
                color: Colors.green,
              ),
              LinearGaugeRange(
                startValue: preTime + durationQty,
                endValue: totalRange, // must match maximum
                color: Colors.blue,
              ),
            ],

            markerPointers: [
              LinearShapePointer(
                value: currentProgress,
                shapeType: LinearShapePointerType.invertedTriangle,
                color: Colors.red,
                width: 18,
                height: 18,
              ),

              LinearWidgetPointer(
                value: preTime / 2,
                position: LinearElementPosition.cross,
                child: const Text("Pre water",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ),

              // MAIN Label
              LinearWidgetPointer(
                value: preTime + (durationQty / 2),
                position: LinearElementPosition.cross,
                child: const Text(
                  "Fertilizer",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ),

              // POST Label
              LinearWidgetPointer(
                value: preTime + durationQty + (postTime / 2),
                position: LinearElementPosition.cross,
                child: const Text(
                  "Post water",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          method == "1" ? Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Duration : ",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  "${formatMinutesToHMS(totalRange)} / ${formatMinutesToHMS(currentProgress)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ) : Text(
            "${currentProgress.toStringAsFixed(2)} / "
                "${totalRange.toStringAsFixed(1)} Ltr",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  double parseTimeToMinutes(String value) {
    if (value.contains(":")) {
      final parts = value.split(":");
      if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;

        return (hours * 60) + minutes + (seconds / 60);
      }
    }
    return double.tryParse(value) ?? 0;
  }

  String formatMinutesToHMS(double minutes) {
    final totalSeconds = (minutes * 60).round();

    final hours = totalSeconds ~/ 3600;
    final minutesPart = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutesPart.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

}