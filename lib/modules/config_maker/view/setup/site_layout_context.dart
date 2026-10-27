import 'package:flutter/material.dart';

import '../../model/device_object_model.dart';
import '../../model/node_type_model.dart';
import '../../state_management/config_maker_provider.dart';


/// Label used for a freshly created node of [type].
String defaultLabelFor(NodeType type) {
  switch (type) {
    case NodeType.pump:
      return 'New Pump';
    case NodeType.sump:
      return 'New Sump';
    case NodeType.well:
      return 'Open Well';
    case NodeType.overheadTank:
      return 'Overhead Tank';
    case NodeType.naturalSource:
      return 'Natural Source';
    case NodeType.mainFertilizerSource:
      return 'Main Fert Source';
    case NodeType.fertilizerTank:
      return 'Fertilizer Tank';
    case NodeType.multiInjector:
      return 'Multi-Injector Skid';
    case NodeType.multiFilter:
      return 'Multi-Filter Station';
    case NodeType.multiValve:
      return 'Multi-Valve Bank';
    case NodeType.mainValve:
    case NodeType.multiMainValve:
      return 'Multi-Main Valve Bank';
    case NodeType.singleMainValve:
      return 'Main Control Valve';
    case NodeType.singleTankValve:
      return 'Single Tank Valve';
    case NodeType.multiOutletTankValve:
      return 'Multi Outlet Tank Valve';
    case NodeType.multiAgitator:
      return 'Multi-Agitator Station';
    case NodeType.singleAgitator:
      return 'Single Agitator';
    case NodeType.pressureSensor:
      return 'Pressure Sensor';
    case NodeType.moistureSensor:
      return 'Moisture Sensor';
    case NodeType.ecSensor:
      return 'EC Sensor';
    case NodeType.phSensor:
      return 'pH Sensor';
    case NodeType.soilTemperatureSensor:
      return 'Soil Temp Sensor';
    case NodeType.waterMeter:
      return 'Water Meter';
    case NodeType.blower:
      return 'Air Blower';
    case NodeType.multiFogger:
      return 'Multi-Fogger System';
    case NodeType.junction:
      return '';
    default:
      return '';
  }
}

/// Configuration split into the groups every setup file needs.
///
/// Built once from [ConfigMakerProvider] so the individual setup files do not
/// repeat the same filtering / sorting.
class SiteSetupData {
  SiteSetupData(this.configPvd);

  final ConfigMakerProvider configPvd;

  late final sources = configPvd.source;
  late final pumps = configPvd.pump;
  late final fertSites = configPvd.fertilization;
  late final channelConfigs = configPvd.channelConfig;
  late final filtrations = configPvd.filtration;

  /// Nothing configured at all -> nothing to draw.
  bool get isEmpty =>
      sources.isEmpty &&
          pumps.isEmpty &&
          fertSites.isEmpty &&
          channelConfigs.isEmpty &&
          filtrations.isEmpty;

  // Separate water configuration and fertilization configuration
  late final waterSources = sources.where((s) => s.sourceType >= 1 && s.sourceType <= 5).toList();
  late final mainFertSources = sources.where((s) => s.sourceType == 6).toList();

  /// Fertilizer tanks, ordered so their valve pipes never cross.
  late final fertTanks = (() {
    final fertTanks = sources.where((s) => s.sourceType == 7).toList();
    final origTankOrder = List.of(fertTanks);
    double tankKey(dynamic src) {
      double sum = 0;
      int n = 0;
      for (final double v in src.outletTankValve) {
        final p = valveChannelPos(v);
        if (p != null) {
          sum += p;
          n++;
        }
      }
      return n == 0 ? 1000.0 + origTankOrder.indexOf(src) : sum / n;
    }

    fertTanks.sort((a, b) {
      final c = tankKey(a).compareTo(tankKey(b));
      return c != 0 ? c : origTankOrder.indexOf(a).compareTo(origTankOrder.indexOf(b));
    });
    return fertTanks;
  })();

  /// sNos of pumps used by fertilizer sources / sites.
  late final Set<double> fertPumpSNos = (() {
    final fertPumpSNos = <double>{};
    for (final mfs in mainFertSources) {
      fertPumpSNos.addAll(mfs.inletPump);
      fertPumpSNos.addAll(mfs.outletPump);
    }
    for (final ft in fertTanks) {
      fertPumpSNos.addAll(ft.inletPump);
      fertPumpSNos.addAll(ft.outletPump);
    }
    for (final fs in fertSites) {
      fertPumpSNos.addAll(fs.boosterPump);
    }
    return fertPumpSNos;
  })();

  /// sNos of pumps linked to water sources (inletPump or outletPump).
  late final Set<double> waterSourcePumpSNos = (() {
    final set = <double>{};
    for (final src in waterSources) {
      set.addAll(src.inletPump);
      set.addAll(src.outletPump);
    }
    return set;
  })();

  late final waterPumps = pumps
      .where((p) => !fertPumpSNos.contains(p.commonDetails.sNo) && waterSourcePumpSNos.contains(p.commonDetails.sNo))
      .toList();
  late final fertPumps = pumps.where((p) => fertPumpSNos.contains(p.commonDetails.sNo)).toList();

  late final bool hasFertData = mainFertSources.isNotEmpty ||
      fertTanks.isNotEmpty ||
      fertSites.isNotEmpty ||
      channelConfigs.isNotEmpty ||
      fertPumps.isNotEmpty;

  /// Where (left -> right) on the injector skid does a tank valve end up?
  /// Used to order the tanks / valve outlets so the pipes never cross.
  double? valveChannelPos(double vSNo) {
    double sum = 0;
    int n = 0;
    for (int s = 0; s < fertSites.length; s++) {
      final site = fertSites[s];
      for (int c = 0; c < site.channel.length; c++) {
        final inj = site.channel[c];
        for (final ch in channelConfigs) {
          if (ch.commonDetails.sNo == inj.sNo && ch.outletTankValve.contains(vSNo)) {
            sum += s * 10.0 + c;
            n++;
          }
        }
      }
    }
    return n == 0 ? null : sum / n;
  }
}

/// Shared state handed to every setup file: the node / pipe lists being built
/// and the helpers that create ids, junctions and clean pipe paths.
class SiteLayoutContext {
  SiteLayoutContext({
    required this.nodes,
    required this.pipes,
    required this.configPvd,
    required this.globalHideJoints,
    this.idCounter = 0,
  }) : data = SiteSetupData(configPvd);

  final List<NodeObject> nodes;
  final List<PipeConnection> pipes;
  final ConfigMakerProvider configPvd;
  final SiteSetupData data;
  final bool globalHideJoints;
  int idCounter;

  String nextId(String prefix) => '${prefix}_${idCounter++}';

  DeviceObjectModel getObjectName(double sNo, ConfigMakerProvider configPvd) {
    return configPvd.listOfGeneratedObject.firstWhere(
          (object) => object.sNo == sNo,
      orElse: () => DeviceObjectModel(
        objectId: 0,
        sNo: sNo,
        name: '-',
        objectName: '',
        type: '',
        assignObject: [],
      ),
    );
  }

  NodeObject newJunction(Offset p) {
    final j = NodeObject(
      id: nextId('junction'),
      position: p - const Offset(7, 7),
      size: const Size(14, 14),
      type: NodeType.junction,
      label: '',
      showJoints: !globalHideJoints,
    );
    nodes.add(j);
    return j;
  }

  /// Removes duplicate and collinear bend points so pipes have only real corners.
  List<Offset> cleanWaypoints(Offset s, List<Offset> wps, Offset e) {
    bool same(Offset a, Offset b) => (a - b).distance < 0.5;
    final out = <Offset>[s];
    for (final p in [...wps, e]) {
      if (!same(out.last, p)) out.add(p);
    }
    final interior = out.sublist(1);
    if (interior.isNotEmpty && same(interior.last, e)) interior.removeLast();

    final full = <Offset>[s, ...interior, e];
    final res = <Offset>[];
    for (int i = 1; i < full.length - 1; i++) {
      final a = full[i - 1], b = full[i], c = full[i + 1];
      final vertical = (a.dx - b.dx).abs() < 0.5 && (b.dx - c.dx).abs() < 0.5;
      final horizontal = (a.dy - b.dy).abs() < 0.5 && (b.dy - c.dy).abs() < 0.5;
      if (!vertical && !horizontal) res.add(b);
    }
    return res;
  }
}

/// Base class of every setup file (water source, filtration, ...). It only
/// forwards to the shared [SiteLayoutContext] so the layout code reads the same
/// in every file.
abstract class SiteSetupBase {
  SiteSetupBase(this.ctx);

  final SiteLayoutContext ctx;

  SiteSetupData get data => ctx.data;
  List<NodeObject> get nodes => ctx.nodes;
  List<PipeConnection> get pipes => ctx.pipes;
  bool get globalHideJoints => ctx.globalHideJoints;

  String nextId(String prefix) => ctx.nextId(prefix);
  NodeObject newJunction(Offset p) => ctx.newJunction(p);
  List<Offset> cleanWaypoints(Offset s, List<Offset> wps, Offset e) => ctx.cleanWaypoints(s, wps, e);
  Offset portPosition(NodeObject node, String? portId, {bool isInput = false}) =>
      node.getPort(portId, isInput: isInput);
  DeviceObjectModel getObjectName(double sNo, ConfigMakerProvider configPvd) =>
      ctx.getObjectName(sNo, configPvd);
}