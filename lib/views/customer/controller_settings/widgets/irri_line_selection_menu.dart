import 'package:flutter/material.dart';
import '../../../../view_models/customer/condition_library_view_model.dart';

class LineNameSelectionMenu extends StatelessWidget {
  final int index;
  final ConditionLibraryViewModel vm;

  const LineNameSelectionMenu({
    super.key,
    required this.index,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final condition = vm.clData.cnLibrary.condition[index];
    final irrigationLines = vm.clData.defaultData.irrigationLine;

    return Container(
      width: double.infinity,
      height: 27,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          width: 0.5,
          color: Colors.grey.shade400,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 5, top: 3),
        child: PopupMenuButton<String>(
          tooltip: 'Select irrigation line',
          onSelected: (String selectedValue) {
            final selectedLine = irrigationLines.firstWhere((line) => line.name == selectedValue);
            vm.updateLineName(selectedValue, selectedLine.sNo.toString(), index);
          },
          itemBuilder: (BuildContext context) {
            if (irrigationLines.isEmpty) {
              return [
                const PopupMenuItem<String>(
                  value: '',
                  height: 30,
                  child: Text('No irrigation lines available'),
                ),
              ];
            }

            return irrigationLines.map<PopupMenuEntry<String>>((line) {
              return PopupMenuItem<String>(
                value: line.name,
                height: 30,
                child: Text(line.name),
              );
            }).toList();
          },
          child: Text(
            condition.reason,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}