import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/channel_config_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';

import '../../../Constants/dialog_boxes.dart';
import '../../../utils/constants.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/config_template_widgets.dart';
import '../widget/painter/single_injector_channel_painter.dart';

/// Simple holder for progress metrics.
class _Progress {
  final int filled;
  final int total;
  final int sensorFilled;
  const _Progress(this.filled, this.total, this.sensorFilled);

  bool get complete => total > 0 && filled == total;
  double get fraction => total == 0 ? 0 : filled / total;
}

class ChannelConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const ChannelConfiguration({super.key, required this.configPvd});

  @override
  State<ChannelConfiguration> createState() => _ChannelConfigurationState();
}

class _ChannelConfigurationState extends State<ChannelConfiguration> {
  // ── Design tokens (Matching pump_configuration.dart) ──
  static const Color _inletColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _outletColor = Color(0xFF059669); // emerald green
  static const Color _doneColor = Color(0xFF059669); // emerald green

  @override
  void initState() {
    super.initState();
    widget.configPvd.updateFloatForPump();
  }

  // ───────────────────────────────────────────────────────────
  //  PROGRESS CALCULATION
  // ───────────────────────────────────────────────────────────
  _Progress _calcProgress(ChannelConfigModel channel) {
    int total = 2;
    int filled = 0;
    if (channel.dosingMeter != 0.0) filled++;
    if (channel.outletTankValve.isNotEmpty) filled++;

    return _Progress(filled, total, filled);
  }

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final channels = widget.configPvd.channelConfig;

    return Container(
      color: const Color(0xFF0C0F1D),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              ConfigPageHeading(
                title: 'Channel configuration',
                subtitle: 'Configure dosing meters and outlet tank valves for channels',
                totalCount: channels.length,
                countUnitSingular: 'channel',
                countUnitPlural: 'channels',
                primaryColor: primaryColor,
                icon: Icons.alt_route_rounded,
              ),
              const SizedBox(height: 18),
              if (channels.isEmpty)
                ConfigEmptyState(
                  title: 'No Channels Configured',
                  subtitle: 'No channels found in current configuration.',
                  icon: Icons.alt_route_rounded,
                  primaryColor: primaryColor,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: channels.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return _buildChannelCard(channel, primaryColor);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  CHANNEL PAINTER LEADING & HEADER BLOCK
  // ───────────────────────────────────────────────────────────
  Widget _buildChannelPainterBlock() {
    return Container(
      width: double.infinity,
      height: 155,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF12162B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SingleInjectorChannelView(
          isOn: false,
          size: Size(75, 140),
        ),
      ),
    );
  }

  Widget _buildChannelHeaderBlock({
    required ChannelConfigModel channel,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF181C38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: const VisualDensity(vertical: -2),
            title: Text(
              channel.commonDetails.name ?? 'Channel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildChannelPainterBlock(),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  CHANNEL CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildChannelCard(ChannelConfigModel channel, Color primaryColor) {
    final progress = _calcProgress(channel);

    return ConfigCardShell(
      headerBlock: _buildChannelHeaderBlock(
        channel: channel,
        primaryColor: primaryColor,
      ),
      isComplete: progress.complete,
      completeColor: _doneColor,
      body: [
        ConfigFlowSection(
          title: 'Dosing Meter',
          icon: Icons.speed_rounded,
          accent: _inletColor,
          children: [
            _buildDosingMeterTile(channel, _inletColor),
          ],
        ),
        ConfigFlowSection(
          title: 'Tank Valves',
          icon: Icons.vibration_rounded,
          accent: _outletColor,
          children: [
            _buildOutletTankValveTile(channel, _outletColor),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  //  COMPONENT TILES
  // ───────────────────────────────────────────────────────────
  Widget _buildDosingMeterTile(ChannelConfigModel channel, Color accent) {
    int objectId = AppConstants.dosingMeterObjectId;
    bool isAssigned = channel.dosingMeter != 0.0;
    String assignedName = isAssigned
        ? getObjectName(channel.dosingMeter, widget.configPvd).name ?? '-'
        : '';

    return ConfigComponentTile(
      title: 'Dosing Meter',
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      names: isAssigned ? [assignedName] : const [],
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.selectedSno = channel.dosingMeter;
        });
        selectionDialogBox(
          context: context,
          title: 'Select Dosing Meter',
          singleSelection: true,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) => (object.objectId == AppConstants.dosingMeterObjectId))
              .toList(),
          onPressed: () {
            setState(() {
              channel.dosingMeter = widget.configPvd.selectedSno;
              widget.configPvd.selectedSno = 0.0;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildOutletTankValveTile(ChannelConfigModel channel, Color accent) {
    int objectId = AppConstants.tankValveObjectId;
    bool isAssigned = channel.outletTankValve.isNotEmpty;
    List<String> assignedNames = isAssigned
        ? channel.outletTankValve
            .map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-')
            .toList()
        : const [];

    List<DeviceObjectModel> listOfObject =
        widget.configPvd.listOfGeneratedObject.where((e) {
      if (e.objectId == AppConstants.tankValveObjectId) {
        bool available = widget.configPvd.source.where((src) {
          if (src.sourceType == 7) {
            return true;
          } else {
            return false;
          }
        }).any((src) => src.outletTankValve.contains(e.sNo));
        return available;
      } else {
        return false;
      }
    }).toList();

    return ConfigComponentTile(
      title: 'Outlet Tank Valve',
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      names: assignedNames,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(channel.outletTankValve);
        });
        selectionDialogBox(
          context: context,
          title: 'Select Outlet Tank Valve',
          singleSelection: false,
          listOfObject: listOfObject,
          onPressed: () {
            setState(() {
              widget.configPvd.updateSelectionInChannel(
                  channel.commonDetails.sNo!, objectId);
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
