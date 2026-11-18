import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';
import '../../../../StateManagement/mqtt_payload_provider.dart';
import '../../../../models/customer/site_model.dart';
import '../../../../modules/IrrigationProgram/view/program_library.dart';
import '../../../../modules/bluetooth_low_energy/state_management/ble_service.dart';
import '../../../../modules/bluetooth_low_energy/view/node_connection_page.dart';
import '../../../../providers/user_provider.dart';
import '../../../../repository/repository.dart';
import '../../../../services/communication_service.dart';
import '../../../../services/http_service.dart';
import '../../../../utils/formatters.dart';
import '../../../../utils/helpers/program_code_helper.dart';
import '../../../../utils/my_function.dart';
import '../../../../utils/snack_bar.dart';
import '../../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../../../../view_models/customer/node_list_view_model.dart';
import '../../../../view_models/customer/current_program_view_model.dart';
import 'package:oro_drip_irrigation/utils/Theme/agritel_theme.dart';

import '../../../customer/widgets/alarm_button.dart';


/// ---------------------------------------------------------------------
/// Design tokens
/// ---------------------------------------------------------------------
class _Tone {
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF7F8FA);
  static const Color surfaceMutedBg = Color(0xFFDAF3BC);
  static const Color border = Color(0xFFE4E6EA);
  static const Color subBorder = Color(0xFFC5C6CA);
  static const Color textPrimary = Color(0xFF1A1D21);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color statusDefault = Color(0xFF9B9D9F);
  static const Color statusRunning = Colors.green;
  static const Color statusRunningBg = Color(0xFFEAF3DE);
  static const Color statusCompleted = Color(0xFF378ADD);
  static const Color statusCompletedBg = Color(0xFFE6F1FB);
  static const Color statusPending = Color(0xFFEF9F27);
  static const Color statusPendingBg = Color(0xFFFAEEDA);
  static const Color statusNotOpen = Color(0xFFD85A30);
  static const Color statusNotOpenBg = Color(0xFFFAECE7);
  static const Color statusNotClosed = Color(0xFFE24B4A);
  static const Color statusNotClosedBg = Color(0xFFFCEBEB);
}

enum ValveDisplayStatus { idle, running, completed, pending, notOpen, notClosed }

class _ValveStatusStyle {
  final Color dot;
  final Color bg;
  final Color fg;
  final String label;
  const _ValveStatusStyle(this.dot, this.bg, this.fg, this.label);
}

_ValveStatusStyle _styleFor(ValveDisplayStatus s) {
  switch (s) {
    case ValveDisplayStatus.running:
      return const _ValveStatusStyle(_Tone.statusRunning, _Tone.statusRunningBg, _Tone.statusRunning, 'Running');
    case ValveDisplayStatus.completed:
      return const _ValveStatusStyle(_Tone.statusCompleted, _Tone.statusCompletedBg, _Tone.statusCompleted, 'Completed');
    case ValveDisplayStatus.pending:
      return const _ValveStatusStyle(_Tone.statusPending, _Tone.statusPendingBg, _Tone.statusPending, 'Pending');
    case ValveDisplayStatus.notOpen:
      return const _ValveStatusStyle(_Tone.statusNotOpen, _Tone.statusNotOpenBg, _Tone.statusNotOpen, 'Not open');
    case ValveDisplayStatus.notClosed:
      return const _ValveStatusStyle(_Tone.statusNotClosed, _Tone.statusNotClosedBg, _Tone.statusNotClosed, 'Not closed');
    case ValveDisplayStatus.idle:
      return const _ValveStatusStyle(_Tone.statusDefault, _Tone.surfaceMuted, _Tone.textSecondary, 'Idle');
  }
}

ValveDisplayStatus _displayStatusFor(int status, int completePercent) {
  if (status == 0 && completePercent == 0) return ValveDisplayStatus.idle;
  if (status == 0 && completePercent == 100) return ValveDisplayStatus.completed;
  if (status == 1) return ValveDisplayStatus.running;
  if (status == 0 && completePercent > 0 && completePercent < 100) return ValveDisplayStatus.pending;
  if (status == 2) return ValveDisplayStatus.notOpen;
  return ValveDisplayStatus.notClosed;
}

/// ---------------------------------------------------------------------
/// Duration lookup — unchanged from original.
/// ---------------------------------------------------------------------
class _ValveDuration {
  final bool isTimeBased;
  final String display;
  final bool isActive;
  const _ValveDuration({required this.isTimeBased, required this.display, required this.isActive});
}

_ValveDuration? _durationForValve(List<String> currentSchedule, String nodeSNo) {
  for (final row in currentSchedule) {
    final values = row.split(',');
    if (values.isEmpty) continue;
    if (values.length <= 11) continue;

    final scheduleNodeSNo = values[0].trim();
    if (scheduleNodeSNo != nodeSNo) continue;

    final programStatus = int.tryParse(values[4].trim()) ?? 0;
    if (programStatus != 1) continue;

    final isTimeBased = values[3].trim() == '1';

    if (isTimeBased) {
      final remTime = values[5].trim();
      if (remTime.isNotEmpty && remTime != '00:00:00') {
        return _ValveDuration(isTimeBased: true, display: remTime, isActive: true);
      }
    } else {
      final remFlow = values[7].trim();
      if (remFlow.isNotEmpty && double.tryParse(remFlow) != null) {
        final flowValue = double.parse(remFlow);
        if (flowValue > 0) {
          return _ValveDuration(isTimeBased: false, display: '${flowValue.toStringAsFixed(2)} L', isActive: true);
        }
      }
    }
  }
  return null;
}

class OmsLine extends StatefulWidget {
  final MasterControllerModel master;
  final int customerId, controllerId, modelId, groupId;
  final String deviceId;
  final bool isNarrow;

  const OmsLine({
    super.key,
    required this.customerId,
    required this.controllerId,
    required this.modelId,
    required this.deviceId,
    required this.master,
    required this.groupId,
    required this.isNarrow,
  });

  @override
  State<OmsLine> createState() => _OmsLineState();
}

class _OmsLineState extends State<OmsLine> {
  final Map<int, Set<int>> nodeValveSelections = {};
  final Set<int> expandedNodes = {};
  String searchQuery = '';

  Set<int> fullySelectedNodeIndices(NodeListViewModel vm) {
    return nodeValveSelections.entries
        .where((e) => e.value.isNotEmpty)
        .where((e) => _isNodeFullySelected(vm, e.key, e.value))
        .map((e) => e.key)
        .toSet();
  }

  bool get hasAnyValveSelected {
    return nodeValveSelections.values.any((valves) => valves.isNotEmpty);
  }

  int get selectedValveCount {
    return nodeValveSelections.values.fold(0, (sum, s) => sum + s.length);
  }

  bool _isNodeFullySelected(NodeListViewModel vm, int nodeIndex, Set<int> selectedValveIdx) {
    final node = vm.nodeList[nodeIndex];
    final totalValves = node.rlyStatus.where((rly) {
      final sNo = rly.sNo.toString();
      return sNo.startsWith('13.') || sNo.startsWith('45.');
    }).length;
    return totalValves > 0 && selectedValveIdx.length == totalValves;
  }

  void _onValveSelectionChanged(int nodeIndex, Set<int> selectedValveIdx) {
    setState(() {
      if (selectedValveIdx.isEmpty) {
        nodeValveSelections.remove(nodeIndex);
      } else {
        nodeValveSelections[nodeIndex] = selectedValveIdx;
      }
    });
  }

  void _toggleExpanded(int nodeIndex) {
    setState(() {
      if (expandedNodes.contains(nodeIndex)) {
        expandedNodes.remove(nodeIndex);
      } else {
        expandedNodes.add(nodeIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NodeListViewModel(context, Repository(HttpService()), widget.master.nodeList),
      child: nodeListBody(context, ),
    );
  }

  Widget nodeListBody(BuildContext context) {

    return Consumer3<NodeListViewModel, MqttPayloadProvider, CurrentProgramViewModel>(
      builder: (context, vm, mqttProvider, programVm, _) {
        final nodeLiveMessage = mqttProvider.nodeLiveMessage;
        final outputOnOffPayload = mqttProvider.outputOnOffPayload;
        final currentSchedule = mqttProvider.currentSchedule;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (vm.shouldUpdate(nodeLiveMessage, outputOnOffPayload)) {
            vm.onLivePayloadReceived(
              List.from(nodeLiveMessage),
              List.from(outputOnOffPayload),
              true,
            );
          }
        });

        if (currentSchedule.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            programVm.updateSchedule(currentSchedule, true);
          });
        }

        final filteredIndices = _filteredNodeIndices(vm);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: widget.isNarrow ? 8 : 0),
              child: _buildTopHeader(vm, widget.master, widget.controllerId,
                  widget.deviceId, widget.customerId, widget.groupId),
            ),
            Padding(
              padding: EdgeInsets.all(widget.isNarrow ? 8 : 12),
              child: widget.isNarrow
                  ? _buildNarrowNodeList(vm, programVm, filteredIndices)
                  : _buildWideNodeTable(vm, programVm, filteredIndices),
            ),
          ],
        );
      },
    );
  }

  /// ---------------------------------------------------------------------
  /// Desktop / wide layout: bordered table with header row.
  /// ---------------------------------------------------------------------
  Widget _buildWideNodeTable(NodeListViewModel vm, CurrentProgramViewModel programVm, List<int> filteredIndices) {
    return Container(
      decoration: BoxDecoration(
        color: _Tone.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Tone.subBorder, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: filteredIndices.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1, color: _Tone.border),
          itemBuilder: (context, i) {
            if (i == 0) return _buildTableHeaderRow();
            final nodeIndex = filteredIndices[i - 1];
            return _buildNodeRow(vm, programVm, nodeIndex);
          },
        ),
      ),
    );
  }

  /// ---------------------------------------------------------------------
  /// Mobile / narrow layout: stacked cards, no table header, no fixed
  /// column widths — everything reflows vertically.
  /// ---------------------------------------------------------------------
  Widget _buildNarrowNodeList(NodeListViewModel vm, CurrentProgramViewModel programVm,
      List<int> filteredIndices) {
    if (filteredIndices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No nodes found', style: TextStyle(fontSize: 15, color: _Tone.textMuted)),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: filteredIndices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final nodeIndex = filteredIndices[i];
        return _buildNodeCard(vm, programVm, nodeIndex);
      },
    );
  }

  List<int> _filteredNodeIndices(NodeListViewModel vm) {
    if (searchQuery.trim().isEmpty) {
      return List.generate(vm.nodeList.length, (i) => i);
    }
    final q = searchQuery.toLowerCase();
    final indices = <int>[];
    for (var i = 0; i < vm.nodeList.length; i++) {
      final node = vm.nodeList[i];
      if (node.deviceName.toLowerCase().contains(q) || node.deviceId.toLowerCase().contains(q)) {
        indices.add(i);
      }
    }
    return indices;
  }

  Widget _buildSearchBar() {
    final fontSize = widget.isNarrow ? 15.0 : 13.0;
    return SearchBar(
      constraints: BoxConstraints(minHeight: widget.isNarrow ? 48 : 42),
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
      hintText: "Search by Zone, Node ID...",
      hintStyle: WidgetStateProperty.all(TextStyle(fontSize: fontSize)),
      textStyle: WidgetStateProperty.all(TextStyle(fontSize: fontSize)),
      leading: Icon(Icons.search_rounded, color: primary, size: 20),
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(Colors.white),
      side: WidgetStateProperty.all(const BorderSide(color: _Tone.border, width: 1)),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      onChanged: (value) => setState(() => searchQuery = value),
    );
  }

  Widget _buildTableHeaderRow() {
    const headerStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _Tone.textSecondary);
    return Container(
      color: _Tone.surfaceMuted,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: const Row(
        children: [
          SizedBox(width: 28),
          SizedBox(width: 42),
          SizedBox(width: 150, child: Text('Node', style: headerStyle)),
          Expanded(flex: 3, child: Text('Zone/Place Name', style: headerStyle)),
          SizedBox(width: 100, child: Text('Battery', style: headerStyle)),
          SizedBox(width: 100, child: Text('Solar', style: headerStyle)),
          Expanded(flex: 3, child: Text('Valves', style: headerStyle)),
          Expanded(flex: 2, child: Text('Running', style: headerStyle)),
          SizedBox(width: 120),
        ],
      ),
    );
  }

  /// Shared helper: extracts the sensors / valves / selection state that
  /// both the wide row and the narrow card need, so the two layouts never
  /// drift out of sync with each other.
  ({
  List<RelayStatus> sensors,
  List<RelayStatus> valves,
  Set<int> selectedValves,
  bool isNodeFullySelected,
  }) _nodeDisplayData(NodeListViewModel vm, int index) {
    final node = vm.nodeList[index];

    final sensors = node.rlyStatus.where((rly) {
      final sNo = rly.sNo.toString();
      return sNo.startsWith('22.') || sNo.startsWith('24.') || sNo.startsWith('46.');
    }).toList();

    final selectedValves = nodeValveSelections[index] ?? <int>{};

    final valves = node.rlyStatus.where((rly) {
      final sNo = rly.sNo.toString();
      return sNo.startsWith('45.') || sNo.startsWith('13.');
    }).toList();

    valves.sort((a, b) {
      final aSNo = a.sNo.toString();
      final bSNo = b.sNo.toString();
      final aIsFlowControl = aSNo.startsWith('45.');
      final bIsFlowControl = bSNo.startsWith('45.');
      if (aIsFlowControl && !bIsFlowControl) return -1;
      if (!aIsFlowControl && bIsFlowControl) return 1;
      return aSNo.compareTo(bSNo);
    });

    final isNodeFullySelected = selectedValves.length == valves.length && valves.isNotEmpty;

    return (
    sensors: sensors,
    valves: valves,
    selectedValves: selectedValves,
    isNodeFullySelected: isNodeFullySelected,
    );
  }

  Widget _buildNodeRow(NodeListViewModel vm, CurrentProgramViewModel programVm, int index) {
    final node = vm.nodeList[index];
    final data = _nodeDisplayData(vm, index);
    final sensors = data.sensors;
    final valves = data.valves;
    final selectedValves = data.selectedValves;
    final isNodeFullySelected = data.isNodeFullySelected;
    final isExpanded = expandedNodes.contains(index);

    return Column(
      children: [
        InkWell(
          onTap: () => _toggleExpanded(index),
          child: Container(
            color: isNodeFullySelected ? primary.withValues(alpha: 0.04) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(Icons.chevron_right, size: 18, color: _Tone.textMuted),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Checkbox(
                    value: isNodeFullySelected,
                    onChanged: (_) => _toggleNodeSelection(vm, index),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.deviceId,
                        style: const TextStyle(fontSize: 11, color: _Tone.textPrimary, fontFamily: 'monospace'),
                      ),
                      Text(
                        Formatters().formatDateDMY(node.lastFeedbackReceivedTime),
                        style: const TextStyle(fontSize: 10, color: _Tone.textMuted, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    node.deviceName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _Tone.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: _MetricChip(
                    label: '${node.batVolt} V',
                    warn: (double.tryParse(node.batVolt.toString()) ?? 0) <= 10,
                  ),
                ),
                SizedBox(width: 100, child: _MetricChip(label: '${node.sVolt} V',
                    warn: (double.tryParse(node.sVolt.toString()) ?? 0) <= 10)),
                Expanded(flex: 3, child: _ValveDotRow(valves: valves)),
                Expanded(flex: 2, child: _RunningSummary(valves: valves, programVm: programVm, nodeSNo: node.serialNumber,)),
                SizedBox(
                  width: 70,
                  child: OutlinedButton(
                    onPressed: () => _toggleExpanded(index),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: _Tone.subBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Details', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: OutlinedButton(
                    onPressed: () => showEditProductDialog(context, node, widget.customerId),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: _Tone.subBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Edit', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          child: isExpanded ? _NodeDetailPanel(
            nodeSNo: node.serialNumber,
            sensors: sensors,
            valves: valves,
            selectedValveIdx: selectedValves,
            programVm: programVm,
            isNarrow: false,
            onValveTap: (valveIndex) {
              final updated = Set<int>.from(selectedValves);
              if (updated.contains(valveIndex)) {
                updated.remove(valveIndex);
              } else {
                updated.add(valveIndex);
              }
              _onValveSelectionChanged(index, updated);
            },
            sensorWidgetBuilder: sensorWidget,
          ) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// ---------------------------------------------------------------------
  /// Mobile card — same data + same tap targets as _buildNodeRow, but
  /// stacked vertically instead of laid out as fixed-width table columns.
  /// ---------------------------------------------------------------------
  Widget _buildNodeCard(
      NodeListViewModel vm,
      CurrentProgramViewModel programVm,
      int index,
      ) {
    final node = vm.nodeList[index];
    final data = _nodeDisplayData(vm, index);

    final sensors = data.sensors;
    final valves = data.valves;
    final selectedValves = data.selectedValves;
    final isNodeFullySelected = data.isNodeFullySelected;
    final isExpanded = expandedNodes.contains(index);

    final batteryVoltage =
        double.tryParse(node.batVolt.toString()) ?? 0;

    final solarVoltage =
        double.tryParse(node.sVolt.toString()) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isNodeFullySelected
            ? primary.withValues(alpha: 0.045)
            : _Tone.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNodeFullySelected
              ? primary.withValues(alpha: 0.35)
              : _Tone.subBorder,
          width: isNodeFullySelected ? 1 : 0.7,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withValues(alpha: 0.035),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // HEADER
          InkWell(
            onTap: () => _toggleExpanded(index),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 34,
                    height: 40,
                    child: Center(
                      child: Checkbox(
                        value: isNodeFullySelected,
                        onChanged: (_) =>
                            _toggleNodeSelection(vm, index),
                        materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                node.deviceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _Tone.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _NodeStatusPill(valves: valves),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          node.deviceId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _Tone.textMuted,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    tooltip: 'More actions',
                    icon: const Icon(Icons.more_vert, size: 20, color: _Tone.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        showEditProductDialog(context, node, widget.customerId);
                      } else if (value == 'bluetooth') {
                        final loggedInUser = context.read<UserProvider>().loggedInUser;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NodeConnectionPage(
                              nodeData: node.toJson(),
                              masterData: {
                                "userId": loggedInUser.id,
                                "customerId": widget.customerId,
                                "controllerId": widget.master.controllerId,
                              },
                              connectMode: ConnectMode.normal,
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 19, color: _Tone.textSecondary),
                            SizedBox(width: 10),
                            Text('Rename node', style: TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                      if (!kIsWeb)
                        const PopupMenuItem(
                          value: 'bluetooth',
                          child: Row(
                            children: [
                              Icon(Icons.bluetooth, size: 19, color: _Tone.textSecondary),
                              SizedBox(width: 10),
                              Text('Connect via Bluetooth', style: TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.chevron_right,
                      size: 22,
                      color: _Tone.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // STATUS
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: _Tone.subBorder,
                ),

                const SizedBox(height: 10),

                // Battery + Solar
                Row(
                  children: [
                    Expanded(
                      child: _MobileStatusChip(
                        icon: Icons.battery_full_rounded,
                        label: 'Battery',
                        value: '${node.batVolt} V',
                        warn: batteryVoltage <= 10,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: _MobileStatusChip(
                        icon: Icons.wb_sunny_outlined,
                        label: 'Solar',
                        value: '${node.sVolt} V',
                        warn: solarVoltage <= 10,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Last feedback
                Row(
                  children: [
                    const Icon(
                      Icons.sync_rounded,
                      size: 14,
                      color: _Tone.textMuted,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Last feedback',
                      style: TextStyle(
                        fontSize: 12,
                        color: _Tone.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Formatters().formatDateDMY(
                        node.lastFeedbackReceivedTime,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _Tone.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // VALVES
                Row(
                  children: [
                    const Icon(
                      Icons.water_drop_outlined,
                      size: 15,
                      color: _Tone.textMuted,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Valves',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _Tone.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${valves.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _Tone.textMuted,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: _ValveDotRow(
                    valves: valves,
                    isNarrow: true,
                  ),
                ),

                const SizedBox(height: 8),

                // RUNNING SUMMARY
                _RunningSummary(
                  valves: valves,
                  programVm: programVm,
                  nodeSNo: node.serialNumber,
                  isNarrow: true,
                ),
              ],
            ),
          ),

          // EXPANDED DETAILS
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.025),
                border: const Border(
                  top: BorderSide(
                    color: _Tone.subBorder,
                    width: 0.7,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                12,
                12,
                12,
                14,
              ),
              child: _NodeDetailPanel(
                nodeSNo: node.serialNumber,
                sensors: sensors,
                valves: valves,
                selectedValveIdx: selectedValves,
                programVm: programVm,
                isNarrow: true,
                onValveTap: (valveIndex) {
                  final updated =
                  Set<int>.from(selectedValves);

                  if (updated.contains(valveIndex)) {
                    updated.remove(valveIndex);
                  } else {
                    updated.add(valveIndex);
                  }

                  _onValveSelectionChanged(
                    index,
                    updated,
                  );
                },
                sensorWidgetBuilder: sensorWidget,
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(NodeListViewModel vm, MasterControllerModel cMaster,
      int controllerId, String deviceId, int customerId, int groupId) {

    final scVm = context.watch<CustomerScreenControllerViewModel>();
    final mqttVm = context.watch<MqttPayloadProvider>();

    final anyValveSelected = hasAnyValveSelected;
    final totalNodes = vm.nodeList.length;
    final valveCount = selectedValveCount;
    final programList = cMaster.programList ?? [];



    final countText = Text(
      valveCount > 0
          ? '$valveCount valve${valveCount == 1 ? '' : 's'} selected · $totalNodes nodes total'
          : '$totalNodes nodes available',
      style: TextStyle(
        fontSize: widget.isNarrow ? 15 : 13,
        fontWeight: FontWeight.w600,
        color: valveCount > 0 ? _Tone.textPrimary : _Tone.textSecondary,
      ),
    );

    final actionButtons = [
      _buildActionButton(
        label: 'Open',
        icon: Icons.play_arrow,
        onPressed: anyValveSelected ? () => _onStartAll(vm) : null,
        color: _Tone.statusRunning,
      ),
      _buildActionButton(
        label: 'Close',
        icon: Icons.stop,
        onPressed: anyValveSelected ? () => _onStopAll(vm) : null,
        color: _Tone.statusNotClosed,
      ),
      _buildProgramsPopoverButton(programList),
      _buildActionButton(
        label: 'New program',
        icon: Icons.add,
        onPressed: () => _openNewProgram(vm, cMaster, controllerId, deviceId, customerId, groupId),
        color: primary,
        filled: true,
      ),

      AlarmButton(
        alarmPayload: mqttVm.alarmDL,
        deviceID: cMaster.deviceId,
        customerId: scVm.mySiteList.data[scVm.sIndex].customerId,
        controllerId: cMaster.controllerId,
        irrigationLine: cMaster.irrigationLine,
        isNarrow: false,
        isOMS: true,
      ),
    ];

    final container = BoxDecoration(
      color: _Tone.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _Tone.subBorder, width: 0.5),
    );

    if (widget.isNarrow) {
      // Stacked layout: count + alarm bell share the top line (the bell is
      // a small icon-only affordance, not another full-width button), then
      // a full-width search bar, then a predictable 2x2 grid of equal-width
      // action buttons. A Wrap of five differently-sized buttons used to
      // reflow unpredictably depending on label length; Expanded rows give
      // every button the same width and a full 48px-tall touch target, and
      // guarantee "Open"/"Close" (the most-used actions) always sit first.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: container,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: countText),
                AlarmButton(
                  alarmPayload: mqttVm.alarmDL,
                  deviceID: cMaster.deviceId,
                  customerId: scVm.mySiteList.data[scVm.sIndex].customerId,
                  controllerId: cMaster.controllerId,
                  irrigationLine: cMaster.irrigationLine,
                  isNarrow: true,
                  isOMS: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildSearchBar(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: actionButtons[0]), // Open
                const SizedBox(width: 8),
                Expanded(child: actionButtons[1]), // Close
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: actionButtons[2]), // Programs
                const SizedBox(width: 8),
                Expanded(child: actionButtons[3]), // New program
              ],
            ),
          ],
        ),
      );
    }

    // Wide layout: everything in one row, as before.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: container,
      child: Row(
        children: [
          Expanded(child: countText),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: SizedBox(width: 250, child: _buildSearchBar()),
          ),
          Row(
            children: [
              actionButtons[0],
              const SizedBox(width: 8),
              actionButtons[1],
              const SizedBox(width: 8),
              actionButtons[2],
              const SizedBox(width: 8),
              actionButtons[3],
              const SizedBox(width: 8),
              actionButtons[4],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramsPopoverButton(List programList) {
    return Builder(
      builder: (buttonContext) {
        return OutlinedButton.icon(
          onPressed: () {
            showPopover(
              context: buttonContext,
              bodyBuilder: (context) => Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: programList.length,
                  itemBuilder: (context, index) {
                    final program = programList[index];

                    return ListTile(
                      dense: true,
                      leading: Text('${index + 1}', style: TextStyle(fontSize: widget.isNarrow ? 14 : 13)),
                      title: Text(program.programName, style: TextStyle(fontSize: widget.isNarrow ? 14 : 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final commService = context.read<CommunicationService>();
                              try {
                                final payLoadFinal = jsonEncode({
                                  "8400": {"8401": '${program.serialNumber},0'},
                                });

                                await Future.delayed(const Duration(milliseconds: 100));

                                await commService.sendCommand(
                                  serverMsg: '${program.programName} ${ProgramCodeHelper.getDescription(0)}',
                                  payload: payLoadFinal,
                                );

                                if (!mounted) return;
                                GlobalSnackBar.show(context, 'Program stopped successfully', 200);
                                Navigator.pop(context);
                              } catch (e) {
                                GlobalSnackBar.show(context, 'Error sending command: $e', 500);
                              }
                            },
                            label: Text(
                              "Stop",
                              style: TextStyle(fontSize: widget.isNarrow ? 14 : 12, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: _Tone.subBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final commService = context.read<CommunicationService>();
                              try {
                                final payLoadFinal = jsonEncode({
                                  "8400": {"8401": '${program.serialNumber},1'},
                                });

                                await Future.delayed(const Duration(milliseconds: 100));

                                await commService.sendCommand(
                                  serverMsg: '${program.programName} ${ProgramCodeHelper.getDescription(1)}',
                                  payload: payLoadFinal,
                                );

                                if (!mounted) return;
                                GlobalSnackBar.show(context, 'Program started successfully', 200);
                                Navigator.pop(context);
                              } catch (e) {
                                GlobalSnackBar.show(context, 'Error sending command: $e', 500);
                              }
                            },
                            label: Text(
                              "Start",
                              style: TextStyle(fontSize: widget.isNarrow ? 14 : 12, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: _Tone.subBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              direction: PopoverDirection.bottom,
              width: widget.isNarrow ? MediaQuery.of(buttonContext).size.width * 0.85 : 400,
              height: (programList.length * 40) + 16,
              arrowHeight: 10,
              arrowWidth: 20,
            );
          },
          icon: const Icon(Icons.playlist_play, size: 16, color: Colors.white),
          label: Text(
            'Programs',
            style: TextStyle(fontSize: widget.isNarrow ? 14 : 12, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: _Tone.subBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
    );
  }

  void _openNewProgram(NodeListViewModel vm, MasterControllerModel cMaster,
      int controllerId, String deviceId, int customerId, int groupId) {
    final loggedInUser = context.read<UserProvider>().loggedInUser;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramLibraryScreenNew(
          customerId: customerId,
          controllerId: controllerId,
          deviceId: deviceId,
          userId: loggedInUser.id,
          groupId: groupId,
          categoryId: cMaster.categoryId,
          modelId: cMaster.modelId,
          deviceName: cMaster.deviceName,
          categoryName: cMaster.categoryName,
          callbackFunction: callbackFunction,
          nodeList: vm.nodeList,
        ),
      ),
    );
  }

  Widget sensorWidget(RelayStatus sensor) {
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getSensorUpdatedValve(sensor.sNo.toString()),
      builder: (_, status, __) {
        String sensorVal = '0';
        final statusParts = status?.split(',') ?? [];
        if (statusParts.isNotEmpty) sensorVal = statusParts[1];

        final sNo = sensor.sNo?.toString() ?? '';
        String sensorType = sNo.startsWith('24.') ? 'Pressure Sensor' : 'Water Meter';
        String imagePath = sNo.startsWith('24.') ? 'assets/png/pressure_sensor.png' : 'assets/png/water_meter.png';

        return Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: _Tone.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _Tone.subBorder, width: 0.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(imagePath, width: 28, height: 28),
                  Positioned(top: 18, right: -8, child: _unitBox(context, sensorVal, sensorType)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                sensor.name.toString(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _Tone.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _unitBox(BuildContext context, String sensorVal, String sensorType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: _Tone.statusPendingBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _Tone.statusPending.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        MyFunction().getUnitByParameter(context, sensorType, sensorVal.toString()) ?? '',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _Tone.statusPending),
      ),
    );
  }

  void callbackFunction(String status) {
    if (status == 'Program created' && mounted) debugPrint(status);
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    bool filled = false,
  }) {
    final enabled = onPressed != null;
    final labelFontSize = widget.isNarrow ? 14.0 : 12.0;
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 5,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: enabled ? color : _Tone.textMuted),
      label: Text(
        label,
        style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w600, color: enabled ? _Tone.textPrimary : _Tone.textMuted),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: enabled ? _Tone.subBorder : _Tone.subBorder.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _toggleNodeSelection(NodeListViewModel vm, int nodeIndex) {
    final node = vm.nodeList[nodeIndex];
    final valves = node.rlyStatus.where((rly) {
      final sNo = rly.sNo.toString();
      return sNo.startsWith('13.') || sNo.startsWith('45.');
    }).toList();

    final currentSelection = nodeValveSelections[nodeIndex] ?? <int>{};
    final isFullySelected = currentSelection.length == valves.length && valves.isNotEmpty;

    if (isFullySelected) {
      _onValveSelectionChanged(nodeIndex, <int>{});
    } else {
      _onValveSelectionChanged(nodeIndex, valves.asMap().keys.toSet());
    }
  }

  List<Map<String, dynamic>> _collectSelectedNodeValveIds(NodeListViewModel vm) {
    final List<Map<String, dynamic>> result = [];
    nodeValveSelections.forEach((nodeIndex, valveIdxSet) {
      if (valveIdxSet.isEmpty) return;
      final node = vm.nodeList[nodeIndex];
      final valves = node.rlyStatus.where((rly) => rly.sNo.toString().startsWith('13.')).toList();
      for (final valveIdx in valveIdxSet) {
        if (valveIdx < 0 || valveIdx >= valves.length) continue;
        final valve = valves[valveIdx];
        result.add({'nodeId': node.deviceId, 'valveId': valve.sNo});
      }
    });
    return result;
  }

  Future<void> _onStartAll(NodeListViewModel vm) async {
    final nodeIds = <String>[];
    final nodeNames = <String>[];

    nodeValveSelections.forEach((nodeIndex, valveIdxSet) {
      if (valveIdxSet.isEmpty) return;
      final node = vm.nodeList[nodeIndex];
      nodeIds.add(node.serialNumber.toString());
      nodeNames.add(node.deviceName);
    });

    final nodeIdString = nodeIds.join('_');
    final nodeNameString = nodeNames.join('_');

    final commService = context.read<CommunicationService>();
    try {
      final payLoadFinal = jsonEncode({
        "8300": {"8301": '$nodeIdString,1'},
      });

      await Future.delayed(const Duration(milliseconds: 100));

      await commService.sendCommand(
        serverMsg: '$nodeNameString ${ProgramCodeHelper.getDescription(1)}',
        payload: payLoadFinal,
      );

      if (!mounted) return;
      GlobalSnackBar.show(context, 'Node started successfully', 200);
    } catch (e) {
      GlobalSnackBar.show(context, 'Error sending command: $e', 500);
    }
  }

  Future<void> _onStopAll(NodeListViewModel vm) async {
    final nodeIds = <String>[];
    final nodeNames = <String>[];

    nodeValveSelections.forEach((nodeIndex, valveIdxSet) {
      if (valveIdxSet.isEmpty) return;
      final node = vm.nodeList[nodeIndex];
      nodeIds.add(node.serialNumber.toString());
      nodeNames.add(node.deviceName);
    });

    final nodeIdString = nodeIds.join('_');
    final nodeNameString = nodeNames.join('_');

    final commService = context.read<CommunicationService>();
    try {
      final payLoadFinal = jsonEncode({
        "8300": {"8301": '$nodeIdString,0'},
      });

      await Future.delayed(const Duration(milliseconds: 100));

      await commService.sendCommand(
        serverMsg: '$nodeNameString ${ProgramCodeHelper.getDescription(0)}',
        payload: payLoadFinal,
      );

      if (!mounted) return;
      GlobalSnackBar.show(context, 'Node stopped successfully', 200);
    } catch (e) {
      GlobalSnackBar.show(context, 'Error sending command: $e', 500);
    }
  }

  void _onApplyProgram(NodeListViewModel vm) {
    final targets = fullySelectedNodeIndices(vm).map((i) => vm.nodeList[i].deviceId).toList();
    debugPrint('Apply program to fully-selected node ids: $targets');
  }

  Future<void> showEditProductDialog(BuildContext context, NodeListModel node, int userId) async {
    final TextEditingController nodeNameController = TextEditingController(text: node.deviceName);
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Node Name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nodeNameController,
              maxLength: 30,
              decoration: const InputDecoration(hintText: "Enter node name"),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Node name cannot be empty';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Map<String, Object> body = {"userId": widget.customerId, "controllerId": widget.controllerId,
                    "nodeControllerId": node.controllerId, "deviceName": nodeNameController.text, "modifyUser": userId};

                  try {
                    var response = await Repository(HttpService()).updateUserNodeDetails(body);
                    if (response.statusCode == 200) {
                      final jsonData = jsonDecode(response.body);
                      if (jsonData["code"] == 200) {
                        setState(() {
                          node.deviceName = nodeNameController.text;
                        });
                        GlobalSnackBar.show(context, 'Node name updated successfully', 200);
                        Navigator.of(context).pop();
                      }
                    }
                  } catch (error) {
                    debugPrint('Error fetching category list: $error');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------
/// Small metric chip
/// ---------------------------------------------------------------------
class _MetricChip extends StatelessWidget {
  final String label;
  final bool warn;
  const _MetricChip({required this.label, this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: warn ? _Tone.statusPendingBg : _Tone.surfaceMutedBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: warn ? _Tone.statusPending : _Tone.textSecondary),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Tiny "N active" / "Idle" pill shown right next to the node name so a
/// user scanning a long list of cards can tell what's running without
/// expanding every card.
/// ---------------------------------------------------------------------
class _NodeStatusPill extends StatelessWidget {
  final List<RelayStatus> valves;
  const _NodeStatusPill({required this.valves});

  @override
  Widget build(BuildContext context) {
    return Consumer<MqttPayloadProvider>(
      builder: (_, mqtt, __) {
        int runningCount = 0;
        for (final v in valves) {
          final status = mqtt.getValveOnOffStatus(double.parse(v.sNo.toString()).toStringAsFixed(3));
          final parts = status?.split(',') ?? [];
          final currentStatus = parts.isNotEmpty ? (int.tryParse(parts[1]) ?? v.status) : v.status;
          final percent = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
          if (_displayStatusFor(currentStatus, percent) == ValveDisplayStatus.running) runningCount++;
        }

        if (runningCount == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: _Tone.statusRunningBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: _Tone.statusRunning, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                '$runningCount',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _Tone.statusRunning),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------
/// Compact dot row used in both the wide row and the narrow card
/// ---------------------------------------------------------------------
class _ValveDotRow extends StatelessWidget {
  final List<RelayStatus> valves;
  final bool isNarrow;
  const _ValveDotRow({required this.valves, this.isNarrow = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<MqttPayloadProvider>(
      builder: (_, mqtt, __) {
        final shown = valves.take(8).toList();
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...shown.map((v) {
              final status = mqtt.getValveOnOffStatus(double.parse(v.sNo.toString()).toStringAsFixed(3));
              final parts = status?.split(',') ?? [];
              final currentStatus = parts.isNotEmpty ? (int.tryParse(parts[1]) ?? v.status) : v.status;
              final percent = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
              final display = _displayStatusFor(currentStatus, percent);
              final style = _styleFor(display);
              final dot = Container(
                width: isNarrow ? 18 : 15,
                height: isNarrow ? 18 : 15,
                decoration: BoxDecoration(color: style.dot, borderRadius: BorderRadius.circular(4)),
              );

              // Tooltip needs a long-press to appear, which most mobile
              // users never discover. On narrow layouts, a plain tap shows
              // the same info via SnackBar instead.
              if (isNarrow) {
                return InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${v.name}: ${style.label}'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: dot,
                );
              }

              return Tooltip(message: '${v.name}: ${style.label}', child: dot);
            }),
            if (valves.length > 8)
              Text('+${valves.length - 8}', style: const TextStyle(fontSize: 10, color: _Tone.textMuted)),
          ],
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------
/// "Running" summary — soonest-finishing valve's live countdown.
/// ---------------------------------------------------------------------
class _RunningSummary extends StatelessWidget {
  final int nodeSNo;
  final List<RelayStatus> valves;
  final CurrentProgramViewModel programVm;
  final bool isNarrow;
  const _RunningSummary({required this.valves, required this.programVm, required this.nodeSNo, this.isNarrow = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: programVm,
      builder: (_, __) {
        return Consumer<MqttPayloadProvider>(
          builder: (_, mqtt, ___) {
            int runningCount = 0;
            String? soonestDisplay;
            String? currentSequenceNumber;

            for (final v in valves) {
              final status = mqtt.getValveOnOffStatus(double.parse(v.sNo.toString()).toStringAsFixed(3));
              final parts = status?.split(',') ?? [];
              final currentStatus = parts.isNotEmpty ? (int.tryParse(parts[1]) ?? v.status) : v.status;
              final percent = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
              final display = _displayStatusFor(currentStatus, percent);

              if (display == ValveDisplayStatus.running) {
                runningCount++;
                final dur = _durationForValve(programVm.currentSchedule, nodeSNo.toString());

                if (dur != null && dur.isActive) {
                  soonestDisplay ??= dur.display;
                }

                final sequenceNum = _getSequenceNumberForValve(programVm.currentSchedule, nodeSNo.toString());
                if (sequenceNum != null) {
                  currentSequenceNumber = sequenceNum;
                }
              }
            }

            if (runningCount == 0) {
              return Text('—', style: TextStyle(fontSize: isNarrow ? 14 : 12, color: _Tone.textMuted));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(soonestDisplay != null && soonestDisplay.contains(":") ? Icons.timer_outlined : Icons.water_drop_outlined, size: isNarrow ? 15 : 13, color: _Tone.statusRunning),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        soonestDisplay != null ? '$runningCount active · $soonestDisplay' : '$runningCount active',
                        style: TextStyle(fontSize: isNarrow ? 13 : 11, fontWeight: FontWeight.w600, color: _Tone.statusRunning),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 17),
                  child: Text(
                    currentSequenceNumber != null ? 'Current Seq: $currentSequenceNumber' : 'No sequence',
                    style: TextStyle(color: Colors.black38, fontSize: isNarrow ? 12 : 10),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _getSequenceNumberForValve(List<String> currentSchedule, String nodeSNo) {
    for (final row in currentSchedule) {
      final values = row.split(',');
      if (values.isEmpty || values.length <= 11) continue;

      final scheduleNodeSNo = values[0].trim();
      if (scheduleNodeSNo != nodeSNo) continue;

      final programStatus = int.tryParse(values[4].trim()) ?? 0;
      if (programStatus != 1) continue;

      if (values.length > 1) {
        final sequenceTot = values[9].trim();
        final currentSequence = values[2].trim();
        if (sequenceTot.isNotEmpty && int.tryParse(sequenceTot) != null) {
          return '$currentSequence/$sequenceTot';
        }
      }
    }
    return null;
  }
}

/// ---------------------------------------------------------------------
/// Expanded node detail panel — `isNarrow` trims the left indent (which
/// on desktop lines the valves up under the "Zone/Place Name" column,
/// but on a phone would just eat width for no reason) and lets the
/// valve-card grid shrink to fit.
/// ---------------------------------------------------------------------
class _NodeDetailPanel extends StatelessWidget {
  final int nodeSNo;
  final List<RelayStatus> sensors;
  final List<RelayStatus> valves;
  final Set<int> selectedValveIdx;
  final CurrentProgramViewModel programVm;
  final bool isNarrow;
  final void Function(int valveIndex) onValveTap;
  final Widget Function(RelayStatus) sensorWidgetBuilder;

  const _NodeDetailPanel({
    required this.nodeSNo,
    required this.sensors,
    required this.valves,
    required this.selectedValveIdx,
    required this.programVm,
    required this.onValveTap,
    required this.sensorWidgetBuilder,
    this.isNarrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _Tone.surface,
      padding: EdgeInsets.fromLTRB(isNarrow ? 12 : 48, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sensors.isNotEmpty) ...[
            Text('Sensors', style: TextStyle(fontSize: isNarrow ? 13 : 11, fontWeight: FontWeight.w600, color: _Tone.textMuted)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: sensors.map(sensorWidgetBuilder).toList()),
            const SizedBox(height: 14),
          ],
          Text('Valves', style: TextStyle(fontSize: isNarrow ? 13 : 11, fontWeight: FontWeight.w600, color: _Tone.textMuted)),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              // On narrow screens, size each card off the *actual* space this
              // Wrap has (constraints.maxWidth), not a guessed screen-width
              // minus assumed padding. The old calc's assumed padding total
              // didn't match the real padding stack (card padding + panel
              // padding), so two cards never quite fit and the 2nd wrapped
              // to its own line, leaving a big empty gap on the right.
              final double? narrowCardWidth =
              isNarrow ? (constraints.maxWidth - 8) / 2 : null;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: valves.asMap().entries.map((entry) {
                  final i = entry.key;
                  final valve = entry.value;
                  return _ValveDetailCard(
                    nodeSNo: nodeSNo,
                    valve: valve,
                    isSelected: selectedValveIdx.contains(i),
                    programVm: programVm,
                    isNarrow: isNarrow,
                    width: narrowCardWidth,
                    onTap: () => onValveTap(i),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Full valve card — on narrow screens it grows to fill the row (via
/// LayoutBuilder against the parent Wrap) instead of a fixed 178px so it
/// doesn't leave awkward gutters on a phone width.
/// ---------------------------------------------------------------------
class _ValveDetailCard extends StatelessWidget {
  final int nodeSNo;
  final RelayStatus valve;
  final bool isSelected;
  final CurrentProgramViewModel programVm;
  final bool isNarrow;
  final double? width;
  final VoidCallback onTap;

  const _ValveDetailCard({
    required this.nodeSNo,
    required this.valve,
    required this.isSelected,
    required this.programVm,
    required this.onTap,
    this.isNarrow = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: programVm,
      builder: (_, __) {
        return Selector<MqttPayloadProvider, String?>(
          selector: (_, provider) => provider.getValveOnOffStatus(
            double.parse(valve.sNo.toString()).toStringAsFixed(3),
          ),
          builder: (_, status, ___) {
            int currentStatus = valve.status;
            int completePercent = 0;

            final statusParts = status?.split(',') ?? [];
            if (statusParts.isNotEmpty) {
              currentStatus = int.tryParse(statusParts[1]) ?? valve.status;
              completePercent = statusParts.length > 2 ? int.parse(statusParts[2]) : 0;
            }

            final display = _displayStatusFor(currentStatus, completePercent);
            final style = _styleFor(display);
            final isFlowControl = valve.sNo.toString().startsWith('45.');

            return GestureDetector(
              onTap: onTap,
              child: Container(
                width: isNarrow ? width : 178,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _Tone.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? primary : _Tone.subBorder,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: isFlowControl
                          ? Image.asset('assets/png/m_flow_control_valve.png', color: style.dot)
                          : Image.asset(
                        currentStatus == 1 ? 'assets/gif/m_valve_green.gif' : 'assets/png/m_valve_grey.png',
                        color: currentStatus == 1 ? null : style.dot,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  valve.name.toString(),
                                  style: TextStyle(fontSize: isNarrow ? 14 : 12, fontWeight: FontWeight.w600, color: _Tone.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isSelected ? primary : Colors.transparent,
                                  border: Border.all(color: isSelected ? primary : _Tone.border, width: 1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: isSelected ? const Icon(Icons.check, size: 9, color: Colors.white) : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(style.label, style: TextStyle(fontSize: isNarrow ? 12 : 10, color: style.fg, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}


class _MobileStatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool warn;

  const _MobileStatusChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.warn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: warn
            ? Colors.orange.withValues(alpha: 0.07)
            : _Tone.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: warn
              ? Colors.orange.withValues(alpha: 0.35)
              : _Tone.subBorder,
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: warn
                ? Colors.orange.shade700
                : _Tone.textMuted,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _Tone.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: warn
                        ? Colors.orange.shade800
                        : _Tone.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


