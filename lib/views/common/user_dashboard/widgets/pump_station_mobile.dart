import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/views/common/user_dashboard/widgets/sensor_widget.dart';
import 'package:provider/provider.dart';

import '../../../../Widgets/pump_widget.dart';
import '../../../../models/customer/site_model.dart';
import '../../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../../../customer/widgets/agitator_widget.dart';
import '../../../customer/widgets/booster_widget.dart';
import '../../../customer/widgets/channel_widget.dart';
import '../../../customer/widgets/filter_builder.dart';
import '../../../customer/widgets/source_column_widget.dart';
import 'fertilizer_live_panel.dart';

class PumpStationMobile extends StatelessWidget {
  final int customerId, controllerId, modelId;
  final String deviceId;
  final List<WaterSourceModel> inletWaterSources;
  final List<WaterSourceModel> outletWaterSources;
  final List<FilterSiteModel> cFilterSite;
  final List<FertilizerSiteModel> cFertilizerSite;
  final List<FilterSiteModel> lFilterSite;
  final List<FertilizerSiteModel> lFertilizerSite;
  final bool isNova;

  PumpStationMobile({
    super.key,
    required this.inletWaterSources,
    required this.outletWaterSources,
    required this.cFilterSite,
    required this.cFertilizerSite,
    required this.lFilterSite,
    required this.lFertilizerSite,
    required this.customerId,
    required this.controllerId,
    required this.deviceId,
    required this.modelId,
    required this.isNova,
  });

  final ValueNotifier<int> popoverUpdateNotifier = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {

    final wsAndFilterItems = [
      if (inletWaterSources.isNotEmpty)
        ..._buildWaterSource(context, inletWaterSources, true, true),

      if (outletWaterSources.isNotEmpty)
        ..._buildWaterSource(context, outletWaterSources, inletWaterSources.isNotEmpty, false),

      if (cFilterSite.isNotEmpty)
        ...buildFilter(context, cFilterSite, (cFertilizerSite.isNotEmpty || lFertilizerSite.isNotEmpty), true, isNova),

      if (lFilterSite.isNotEmpty)
        ...buildFilter(context, lFilterSite, (cFertilizerSite.isNotEmpty || lFertilizerSite.isNotEmpty), true, isNova),
    ];

    final fertilizerItemsCentral = cFertilizerSite.isNotEmpty
        ? _buildFertilizer(context, cFertilizerSite, isNova).cast<Widget>()
        : <Widget>[];

    final fertilizerItemsLocal = lFertilizerSite.isNotEmpty
        ? _buildFertilizer(context, lFertilizerSite, isNova).cast<Widget>()
        : <Widget>[];

    const double itemWidth = 70;
    const double itemHeight = 90;

    return LayoutBuilder(
      builder: (context, constraints) {
        final int itemsPerRow = (constraints.maxWidth / itemWidth)
            .floor().clamp(1, wsAndFilterItems.length);
        final int rowCount = (wsAndFilterItems.length / itemsPerRow).ceil();

        return Column(
          children: [
            for (int row = 0; row < rowCount; row++)
              SizedBox(
                height: itemHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (int i = 0; i < itemsPerRow; i++)
                      if (row * itemsPerRow + i < wsAndFilterItems.length)
                        wsAndFilterItems[
                        row == 0
                            ? row * itemsPerRow + (itemsPerRow - 1 - i).
                        clamp(0, wsAndFilterItems.length - 1)
                            : row * itemsPerRow + i
                        ],
                  ],
                ),
              ),

            if (cFertilizerSite.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 125,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: IntrinsicWidth(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () {
                          final customerVM = context.read<CustomerScreenControllerViewModel>();
                          showRightSheet(
                            context,
                            ChangeNotifierProvider.value(
                              value: customerVM,
                              child: FertilizerLivePanel(
                                deviceId: deviceId,
                                controllerId: controllerId,
                                customerId: customerId,
                                isWide: false,
                              ),
                            ),
                          );
                        },
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 0,
                          runSpacing: 0,
                          children: fertilizerItemsCentral,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (lFertilizerSite.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 125,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: IntrinsicWidth(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () {
                          final customerVM = context.read<CustomerScreenControllerViewModel>();
                          showRightSheet(
                            context,
                            ChangeNotifierProvider.value(
                              value: customerVM,
                              child: FertilizerLivePanel(
                                deviceId: deviceId,
                                controllerId: controllerId,
                                customerId: customerId,
                                isWide: false,
                              ),
                            ),
                          );
                        },
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 0,
                          runSpacing: 0,
                          children: fertilizerItemsLocal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void showRightSheet(BuildContext context, Widget child) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "LiveData",
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            elevation: 10,
            child: SizedBox(
              width: 600,
              height: double.infinity,
              child: child,
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  List<Widget> _buildWaterSource(BuildContext context, List<WaterSourceModel> waterSources,
      bool isAvailInlet, bool isInlet) {

    final List<Widget> gridItems = [];

    for (int index = 0; index < waterSources.length; index++) {
      final source = waterSources[index];

      // --------------------------------------------------
      // WATER SOURCE
      // --------------------------------------------------
      gridItems.add(
        SourceColumnWidget(
          source: source,
          isInletSource: isInlet,
          isAvailInlet: isAvailInlet,
          index: index,
          total: waterSources.length,
          popoverUpdateNotifier: popoverUpdateNotifier,
          deviceId: deviceId,
          customerId: customerId,
          controllerId: controllerId,
          modelId: modelId,
          isMobile: true,
          isAvailFrtSite:
          (cFertilizerSite.isNotEmpty || lFertilizerSite.isNotEmpty),
        ),
      );

      // --------------------------------------------------
      // PUMP + WATER METER
      // --------------------------------------------------
      for (final pump in source.outletPump) {
        // Pump
        gridItems.add(
          PumpWidget(
            pump: pump,
            isSourcePump: isInlet,
            deviceId: deviceId,
            customerId: customerId,
            controllerId: controllerId,
            isMobile: true,
            modelId: modelId,
            pumpPosition: 'First',
            isAvailFrtSite:
            (cFertilizerSite.isNotEmpty || lFertilizerSite.isNotEmpty),
            isNova: isNova,
          ),
        );

        // Water Meter — only if this pump actually has one
        if (pump.waterMeter.isNotEmpty) {
          gridItems.add(
            SensorWidget(
              sensor: pump.waterMeter.first,
              sensorType: 'Water Meter',
              imagePath: 'assets/png/mobile/m_water_meter_pmp.png',
              customerId: customerId,
              controllerId: controllerId,
            ),
          );
        }
      }
    }


    /*for (int index = 0; index < waterSources.length; index++) {
      final source = waterSources[index];
      gridItems.add(SourceColumnWidget(
        source: source,
        isInletSource: isInlet,
        isAvailInlet: isAvailInlet,
        index: index,
        total: waterSources.length,
        popoverUpdateNotifier: popoverUpdateNotifier,
        deviceId: deviceId,
        customerId: customerId,
        controllerId: controllerId,
        modelId: modelId,
        isMobile: true,
        isAvailFrtSite: (cFertilizerSite.isNotEmpty || lFertilizerSite.isNotEmpty),
      ));

      gridItems.addAll(source.outletPump.map((pump) => PumpWidget(
        pump: pump,
        isSourcePump: isInlet,
        deviceId: deviceId,
        customerId: customerId,
        controllerId: controllerId,
        isMobile: true,
        modelId: modelId,
        pumpPosition: 'First',
        isAvailFrtSite: (cFertilizerSite.isNotEmpty || lFertilizerSite.isNotEmpty),
        isNova: isNova,
      )));
    }*/

    return gridItems;
  }

  List<Widget> _buildFertilizer(BuildContext context,
      List<FertilizerSiteModel> fertilizerSite, bool isNova) {

    return fertilizerSite.map((site) {
      final widgets = <Widget>[];

      final List<Widget> channelWidgets = [];

      for (int channelIndex = 0; channelIndex < site.channel.length; channelIndex++) {
        final channel = site.channel[channelIndex];

        channelWidgets.add(ChannelWidget(
          channel: channel,
          cIndex: channelIndex,
          channelLength: site.channel.length,
          agitator: site.agitator,
          siteSno: site.sNo.toString(),
          isMobile: true,
        ));

        final isLast = channelIndex == site.channel.length - 1;
        if (isLast && site.agitator.isNotEmpty) {
          channelWidgets.add(AgitatorWidget(
            fertilizerSite: site,
            isMobile: true,
          ));
        }
      }
      //

      widgets.add(BoosterWidget(
        fertilizerSite: site,
        isMobile: true,
      ));
      widgets.addAll(channelWidgets);


      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets,
          ),
        ),
      );
    }).toList();
  }
}