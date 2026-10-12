import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/Constants/properties.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/model/LineDataModel.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/schedule_screen.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/selection_screen.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/widgets/custom_section_title.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../../Screens/planning/valve_group_screen.dart';
import '../../config_maker/model/device_object_model.dart';
import '../state_management/irrigation_program_provider.dart';
import '../widgets/custom_animated_switcher.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import 'irrigation_program_main.dart';

class SequenceScreen extends StatefulWidget {
  final int userId;
  final int modelId;
  final int controllerId;
  final int serialNumber;
  final String deviceId;

  const SequenceScreen({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.serialNumber,
    required this.deviceId,
    required this.modelId,
  });

  @override
  State<SequenceScreen> createState() => _SequenceScreenState();
}

class _SequenceScreenState extends State<SequenceScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textEditingController = TextEditingController();
  late IrrigationProgramMainProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_provider.irrigationLine != null &&
            (_provider.currentIndex < 0 || _provider.currentIndex >= _provider.irrigationLine!.sequence.length)) {
          _provider.assigningCurrentIndex(0);
        }
        _provider.addNext = false;
        if (_scrollController.hasClients && _provider.currentIndex > 0) {
          _scrollController.animateTo(
            (_provider.currentIndex * 100).toDouble(),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _provider = Provider.of<IrrigationProgramMainProvider>(context);

    if (_provider.sampleIrrigationLine == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSequenceHeader(),
          _buildButtonRow(),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: _getResponsiveMargin(context),
                child: Column(
                  children: [
                    ..._buildIrrigationSections(context),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _irrProgram => "Irrigation Program";
  String get _agiProgram => "Agitator Program";
  String get _othProgram => "Other Programs";
  String get _aeratorProgram => "Aerator Program";

  bool get _isIrrigationProgram => _provider.programDetails!.programType == _irrProgram ||
      _provider.selectedProgramType == _irrProgram;

  bool get _isAgitatorProgram => _provider.programDetails!.programType == _agiProgram ||
      _provider.selectedProgramType == _agiProgram;

  bool get _isOtherProgram => _provider.programDetails!.programType == _othProgram ||
      _provider.selectedProgramType == _othProgram;

  bool get _isAeratorProgram => _provider.programDetails!.programType == _aeratorProgram ||
      _provider.selectedProgramType == _aeratorProgram;

  Widget _buildSequenceHeader() {
    final sequence = _provider.irrigationLine!.sequence;
    final margin = MediaQuery.of(context).size.width >= 700
        ? EdgeInsets.symmetric(
      horizontal: MediaQuery.of(context).size.width * 0.05,
      vertical: MediaQuery.of(context).size.width * 0.025,
    )
        : const EdgeInsets.symmetric(horizontal: 15, vertical: 15);

    return Container(
      margin: margin,
      decoration: _boxDecoration(color: Colors.white, border: false),
      height: 60,
      width: double.infinity,
      child: sequence.isNotEmpty
          ? GestureDetector(
        onHorizontalDragUpdate: (details) => _scrollController.jumpTo(_scrollController.offset - details.primaryDelta! / 2),
        child: Center(
          child: ReorderableListView.builder(
            scrollController: sequence.isNotEmpty ? _scrollController : null,
            autoScrollerVelocityScalar: 0.5,
            buildDefaultDragHandles: MediaQuery.of(context).size.width > 600 ? false : true,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            onReorder: _provider.reorderSelectedValves,
            proxyDecorator: (widget, animation, index) => Transform.scale(scale: 1.05, child: widget),
            itemCount: sequence.length,
            itemBuilder: (context, index) => _buildSequenceItem(index),
          ),
        ),
      )
          : const Center(child: Text('Select desired sequence')),
    );
  }

  Widget _buildSequenceItem(int index) {
    final sequence = _provider.irrigationLine!.sequence;
    return Material(
      key: ValueKey('sequence_$index'),
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(
          left: index == 0 ? 10 : 0,
          right: index == sequence.length - 1 ? 5 : 0,
        ),
        child: MediaQuery.of(context).size.width > 600
            ? ReorderableDragStartListener(
          index: index,
          child: _buildSequence(context, index),
        )
            : _buildSequence(context, index),
      ),
    );
  }

  Widget _buildSequence(BuildContext context, int index) {
    final indexToShow = _getIndexToShow;
    return Row(
      children: [
        _buildSequenceItemContainer(context, index, indexToShow),
        CustomAnimatedSwitcher(
          condition: _provider.selectedOption != _provider.deleteSelection[2],
          child: Checkbox(
            value: _provider.irrigationLine!.sequence[index]['selected'] ?? false,
            onChanged: (newValue) => _provider.updateCheckBoxSelection(index: index, newValue: newValue),
          ),
        ),
        const SizedBox(width: 5),
      ],
    );
  }

  Widget _buildSequenceItemContainer(BuildContext context, int index, int indexToShow) {
    return buildListOfContainer(
      context: context,
      onTap: () {
        if (_provider.irrigationLine!.sequence[indexToShow]['valve'].isEmpty) {
          _showValveSelectionAlert();
        } else {
          _provider.addNext = false;
          _provider.assigningCurrentIndex(index);
        }
      },
      selected: index == indexToShow,
      darkColor: Theme.of(context).primaryColorLight,
      textColor: index == indexToShow ? Colors.white : Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      itemName: _provider.irrigationLine!.sequence[index]['name'],
    );
  }

  int get _getIndexToShow => _provider.addNew
      ? _provider.irrigationLine!.sequence.length - 1
      : _provider.addNext
      ? _provider.currentIndex + 1
      : _provider.currentIndex;

  Widget _buildButtonRow() {
    final margin = MediaQuery.of(context).size.width >= 700
        ? EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05)
        : const EdgeInsets.symmetric(horizontal: 15);

    return Container(
      margin: margin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildEditButton(),
          buildButtonBar(context: context),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return FilledButton(
      onPressed: () => _showEditSequencesSheet(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColorLight,
        elevation: 2,
        shadowColor: Theme.of(context).primaryColorLight.withAlpha(30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        minimumSize: const Size(0, 40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_note_rounded, size: 20, color: Colors.white),
          if (MediaQuery.of(context).size.width > 900) ...[
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                "Edit",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditSequencesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text('Edit Sequences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _provider.irrigationLine!.sequence.length,
                  itemBuilder: (context, index) => _buildSequenceListTile(index, setModalState),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSequenceListTile(int index, StateSetter setModalState) {
    final sequence = _provider.irrigationLine!.sequence[index];
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Text('${index + 1}'),
      title: Text(sequence['name']),
      subtitle: Text(
        sequence['valve'].map((e) => e['name']).join(', '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        color: Theme.of(context).primaryColor,
        onPressed: () => _showEditNameDialog(context, index, setModalState),
      ),
      onTap: () => _showEditNameDialog(context, index, setModalState),
    );
  }

  void _showEditNameDialog(BuildContext context, int index, StateSetter setModalState) {
    final sequence = _provider.irrigationLine!.sequence;
    final controller = TextEditingController(text: sequence[index]['name'])
      ..selection = TextSelection(baseOffset: 0, extentOffset: sequence[index]['name'].length);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Sequence Name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            autofocus: true,
            controller: controller,
            inputFormatters: [
              LengthLimitingTextInputFormatter(20),
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.]')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Name cannot be empty';
              if (sequence.any((e) => e['name'] == value && e != sequence[index])) {
                return 'Name already exists';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setModalState(() => sequence[index]['name'] = controller.text);
                Navigator.pop(ctx);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showValveSelectionAlert() {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('At least one valve should be selected!', style: TextStyle(color: Colors.red)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget buildButtonBar({required BuildContext context}) {
    final sequence = _provider.irrigationLine!.sequence;
    final indexToShow = _getIndexToShow;

    return ButtonBar(
      alignment: MainAxisAlignment.end,
      layoutBehavior: ButtonBarLayoutBehavior.constrained,
      children: [
        _buildAddNextButton(context, sequence, indexToShow),
        _buildDeleteButton(context, indexToShow),
        _buildPopupMenuButton(context),
      ],
    );
  }

  Widget _buildAddNextButton(BuildContext context, List sequence, int indexToShow) {
    final icon = indexToShow == sequence.length - 1 ? Icons.add : Icons.skip_next;
    final label = indexToShow == sequence.length - 1 ? "Add new" : "Add next";

    return buildActionButton(
      context: context,
      key: 'addNext',
      labelColor: Theme.of(context).primaryColor,
      icon: icon,
      label: label,
      onPressed: sequence[indexToShow]['valve'].isEmpty
          ? () => _showValveSelectionAlert()
          : () {
        _provider.updateAddNext(
          serialNumber: widget.serialNumber,
          indexToShow: indexToShow,
          modelId: widget.modelId,
        );
        _provider.updateNextButton(indexToShow);
        _scrollController.animateTo(
          indexToShow * 150,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  Widget _buildDeleteButton(BuildContext context, int indexToShow) {
    return buildActionButton(
      context: context,
      key: 'delete',
      icon: Icons.delete,
      label: "Delete",
      labelColor: Colors.red,
      onPressed: _provider.irrigationLine!.sequence.any((element) => element['selected'] == true)
          ? () => _showDeleteConfirmationDialog(indexToShow)
          : null,
    );
  }

  void _showDeleteConfirmationDialog(int indexToShow) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Are you sure to erase the sequence?'),
        actions: [
          TextButton(
            child: const Text("CANCEL", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              _provider.deleteFunction(
                indexToShow: indexToShow,
                serialNumber: widget.serialNumber,
                modelId: widget.modelId,
              );
              Navigator.of(context).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: 'The sequence is erased!'));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenuButton(BuildContext context) {
    return sequenceBuildPopUpMenuButton(
      context: context,
      dataList: _provider.deleteSelection,
      onSelected: (selected) {
        _provider.updateDeleteSelection(newOption: selected);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
        child: Row(
          children: [
            Checkbox(
              value: _provider.selectedOption == _provider.deleteSelection[1],
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (selected) {
                final newValue = selected! ? _provider.deleteSelection[1] : _provider.deleteSelection[2];
                _provider.updateDeleteSelection(newOption: newValue);
              },
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget buildActionButton({
    required BuildContext context,
    required String key,
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    Color? buttonColor,
    Color? labelColor,
  }) {
    final isEnabled = onPressed != null;
    final effectiveButtonColor = buttonColor ?? Colors.white;
    final effectiveLabelColor = labelColor ?? Theme.of(context).primaryColor;
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return AnimatedScale(
      scale: isEnabled ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 150),
      child: ElevatedButton(
        key: Key(key),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveButtonColor,
          foregroundColor: isEnabled ? effectiveLabelColor : Colors.grey.shade50,
          elevation: isEnabled ? 2 : 0,
          shadowColor: effectiveButtonColor.withAlpha(30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: isEnabled ? effectiveLabelColor.withAlpha(100) : Colors.grey.withAlpha(10),
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          minimumSize: const Size(0, 40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isEnabled ? effectiveLabelColor : Colors.grey),
            if (isWideScreen) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? effectiveLabelColor : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  EdgeInsets _getResponsiveMargin(BuildContext context) {
    return MediaQuery.of(context).size.width >= 700
        ? EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05)
        : const EdgeInsets.symmetric(horizontal: 15);
  }

  List<Widget> _buildIrrigationSections(BuildContext context) {
    final sections = <Widget>[];
    final sampleIrrigationLine = _provider.sampleIrrigationLine;

    if (_isIrrigationProgram && sampleIrrigationLine != null) {
      // Main Valves
      final mainValves = sampleIrrigationLine.expand((e) => e.mainValve ?? []).toList();
      // final List<DeviceObjectModel> mainValves =
      // sampleIrrigationLine
      //     .expand<DeviceObjectModel>((e) => e.mainValve ?? [])
      //     .toList();
       if (mainValves.isNotEmpty) {
        sections.add(_buildIrrigationSection(
          context: context,
          title: 'Main valves',
          items: AppConstants.omsGemList.contains(widget.modelId)? mainValves.take(1).toList() : mainValves,
          isMainValve: true,
          leading: _buildLeadingIcon('assets/Images/m_valve.png'),
        ));
      }

      // Valve Groups
      final groups = _provider.irrigationLine?.defaultData.group ?? [];
      if (groups.isNotEmpty) {
        sections.add(_buildIrrigationSection(
          context: context,
          title: 'Valve Groups',
          items: groups,
          isGroup: true,
          trailing: _buildCreateGroupButton(context),
        ));
      }

      // Irrigation Lines
      if (sampleIrrigationLine.isNotEmpty) {
        sections.addAll(sampleIrrigationLine.asMap().entries.map((entry) {
          final index = entry.key;
          final line = entry.value;

          return _buildIrrigationSection(
            context: context,
            title: line.irrigationLine.name ?? 'Unnamed Line',
            items: AppConstants.omsGemList.contains(widget.modelId)? line.valve!.take(6).toList() :  line.valve ?? [],
            lineIndex: index,
          );
        }));
      }
    }

    // Agitators
    if (_isAgitatorProgram && _provider.agitators != null) {
      sections.add(_buildIrrigationSection(
        context: context,
        title: 'Agitators',
        items: _provider.agitators!,
        leading: _buildLeadingIcon('assets/png/dp_agitator_right.png'),
      ));
    }

    // Aerators
    if (_isAeratorProgram && _provider.aerators != null) {
      sections.add(_buildIrrigationSection(
        context: context,
        title: 'Aerators',
        items: _provider.aerators!,
        leading: _buildLeadingIcon('assets/png/dp_agitator_right.png'),
      ));
    }

    // Others
    if(_isOtherProgram && sampleIrrigationLine != null) {
      final fans = sampleIrrigationLine.expand((e) => e.fan ?? []).toList();
      if (fans.isNotEmpty) {
        sections.add(_buildIrrigationSection(
          context: context,
          title: 'Fans',
          items: fans,
          leading: _buildLeadingIcon('assets/Images/Png/objectId_15.png'),
        ));
      }

      final fogger = sampleIrrigationLine.expand((e) => e.fogger ?? []).toList();
      if (fogger.isNotEmpty) {
        sections.add(_buildIrrigationSection(
          context: context,
          title: 'Foggers',
          items: fogger,
          leading: _buildLeadingIcon('assets/Images/Png/objectId_16.png'),
        ));
      }

      final lights = sampleIrrigationLine.expand((e) => e.light ?? []).toList();
      if (lights.isNotEmpty) {
        sections.add(_buildIrrigationSection(
          context: context,
          title: 'Lights',
          items: lights,
          leading: _buildLeadingIcon('assets/Images/Png/objectId_19.png'),
        ));
      }
    }

    return sections;
  }

  Widget _buildIrrigationSection({
    required BuildContext context,
    required String title,
    required List<dynamic> items,
    bool isGroup = false,
    bool isMainValve = false,
    int lineIndex = 0,
    Widget? leading,
    Widget? trailing,
  }) {
     return Column(
      children: [
        buildLineAndValveContainerUpdated(
          context: context,
          title: title,
          leading: leading,
          trailing: trailing,
          children: items.map((item) => buildValveContainer(
            context: context,
            item: item,
            isGroup: isGroup,
            isMainValve: isMainValve,
            dataList: isGroup ? items : null,
            lineIndex: lineIndex,
          )).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLeadingIcon(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(color: cardColor, shape: BoxShape.circle),
      child: Image.asset(assetPath),
    );
  }

  Widget _buildCreateGroupButton(BuildContext context) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupListScreen(
              userId: widget.userId,
              customerId: widget.userId,
              controllerId: widget.controllerId,
              deviceId: widget.deviceId,
            ),
          ),
        ),
        style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 0))),
        child: const Text('Create'),
      ),
    );
  }

  Widget buildValveContainer({
    required BuildContext context,
    required dynamic item,
    bool isGroup = false,
    List<dynamic>? dataList,
    int lineIndex = 0,
    bool isMainValve = false,
  })
  {
    final sequence = _provider.irrigationLine!.sequence;
    final indexToShow = _getIndexToShow;
    final isSelected = sequence.isEmpty || indexToShow >= sequence.length
        ? false
        : isGroup
        ? sequence[indexToShow]['selectedGroup']?.any((e) => e == item.id) ?? false
        : isMainValve
        ? sequence[indexToShow]['mainValve']?.any((e) => e['sNo'] == item.sNo) ?? false
        : sequence[indexToShow]['valve']?.any((e) => e['sNo'] == item.sNo) ?? false;
    for(var i in sequence[indexToShow]['mainValve']){
      print('flow valve => ${i}');
    }
    print("sequence[indexToShow]['selectedGroup'] : ${sequence[indexToShow]['selectedGroup']}");

    print("isSelected:$isSelected");
    print("mainValve:$isMainValve");

    return buildListOfContainer(
      context: context,
      selected: isSelected,
      onTap: () => _handleValveTap(item, isGroup, dataList, lineIndex, isMainValve, indexToShow),
      darkColor: (!isGroup && !isMainValve) ? greenDark : const Color(0xfffdce7f),
      itemName: item.name,
    );
  }

  void _handleValveTap(dynamic item, bool isGroup, List<dynamic>? dataList, int lineIndex, bool isMainValve, int indexToShow) {
    final sequence = _provider.irrigationLine!.sequence;

    final groupId = isGroup ? item.id : '';
    void onConfirm() {
      sequence[indexToShow]['modified'] = true;
      _addValvesToSequence(isGroup, dataList, lineIndex, isMainValve, indexToShow, groupId, item);
    }

    if (sequence[indexToShow]['modified'] ?? false) {
      _showModifySequenceDialog(onConfirm);
    } else {
      if (!sequence[indexToShow].containsKey('selectedGroup')) {
        sequence[indexToShow]['selectedGroup'] = [];
      }
      _addValvesToSequence(isGroup, dataList, lineIndex, isMainValve, indexToShow, groupId, item);
    }
  }

  void _showModifySequenceDialog(VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Warning!"),
        content: const Text(
          "The fertilizer settings will be erased while adding or removing valve in the existing sequence! \n Are you sure modify the sequence?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addValvesToSequence(bool isGroup, List<dynamic>? dataList, int lineIndex, bool isMainValve, int sequenceIndex, String groupId, dynamic item) {
    _provider.addValvesInSequence(
      valves: isGroup ? dataList!.map((e) => e.toJson()).toList() : [item.toJson()],
      lineIndex: lineIndex,
      isMainValve: isMainValve,
      sequenceIndex: sequenceIndex,
      isGroup: isGroup,
      serialNumber: widget.serialNumber == 0 ? _provider.serialNumberCreation : widget.serialNumber,
      sNo: _provider.irrigationLine!.sequence.length + 1,
      groupId: groupId,
      context: context,
      modelId: widget.modelId,
    );
  }

  BoxDecoration _boxDecoration({Color? color, bool border = true}) {
    return BoxDecoration(
      color: color,
      border: border ? Border.all(width: 0.3, color: Theme.of(context).primaryColor) : null,
      borderRadius: BorderRadius.circular(15),
      boxShadow: AppProperties.customBoxShadowLiteTheme,
    );
  }
}

// Helper Widgets
Widget buildListOfContainer({
  required BuildContext context,
  required VoidCallback onTap,
  required bool selected,
  required Color? darkColor,
  Color? textColor,
  required String itemName,
  EdgeInsets padding = const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
}) {
  Color getDarkerColor(Color? color) {
    if (color == null) return Colors.black;
    return Color.fromRGBO(
      (color.red * 0.8).round(),
      (color.green * 0.8).round(),
      (color.blue * 0.8).round(),
      1.0,
    );
  }

  return ChoiceChip(
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected) Icon(Icons.radio_button_checked, color: textColor ?? getDarkerColor(darkColor), size: 20),
        const SizedBox(width: 4),
        Text(itemName, style: TextStyle(color: textColor ?? Colors.black)),
      ],
    ),
    selected: selected,
    showCheckmark: false,
    onSelected: (_) => onTap(),
    selectedColor: darkColor,
    backgroundColor: selected ? darkColor : darkColor!.withAlpha(20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: darkColor!, width: 0.8),
    ),
    elevation: 4,
    shadowColor: darkColor.withAlpha(50),
    labelPadding: EdgeInsets.zero,
    padding: padding,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

Widget buildLineAndValveContainerUpdated({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  Widget? leading,
  Widget? trailing,
  bool isRowLayout = true,
  bool isTitle = false,
}) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.only(
        bottomLeft: const Radius.circular(10),
        bottomRight: const Radius.circular(10),
        topRight: const Radius.circular(10),
        topLeft: isTitle ? const Radius.circular(0) : const Radius.circular(10),
      ),
      color: Colors.white,
      boxShadow: AppProperties.customBoxShadowLiteTheme,
    ),
    child: isRowLayout && MediaQuery.of(context).size.width > 800
        ? Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          buildLeadingTitle(context, title, leading, 40, 22),
          const SizedBox(width: 10),
          const SizedBox(height: 50, child: VerticalDivider(color: Colors.grey)),
          const SizedBox(width: 10),
          Expanded(flex: 5, child: Wrap(spacing: 5, runSpacing: 10, children: children)),
          if (trailing != null) Align(alignment: Alignment.centerRight, child: trailing),
        ],
      ),
    )
        : Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              buildLeadingTitle(context, title, leading, 30, 16),
              if (trailing != null) Expanded(child: Align(alignment: Alignment.centerRight, child: trailing)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 5, runSpacing: 10, children: children),
        ],
      ),
    ),
  );
}

Widget buildLeadingTitle(BuildContext context, String title, Widget? leading, double size, double fontSize) {
  return Expanded(
    child: Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
          child: leading ?? Image.asset('assets/Images/irrigation_line1.png', color: Theme.of(context).primaryColorDark),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
            maxLines: 2,
          ),
        ),
      ],
    ),
  );
}

Widget sequenceBuildPopUpMenuButton({
  required BuildContext context,
  required List<String> dataList,
  required void Function(String) onSelected,
  required Widget child,
}) {
  return PopupMenuButton<String>(
    onSelected: onSelected,
    itemBuilder: (context) => dataList.map((item) => PopupMenuItem(value: item, child: Text(item))).toList(),
    child: child,
  );
}