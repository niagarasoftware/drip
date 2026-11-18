import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../utils/enums.dart';
import '../../../../view_models/base_header_view_model.dart';

class MainMenuSegmentWidget extends StatelessWidget {
  final BaseHeaderViewModel viewModel;
  final bool isCentered;

  const MainMenuSegmentWidget({
    super.key,
    required this.viewModel,
    this.isCentered = true,
  });

  @override
  Widget build(BuildContext context) {

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: SegmentedButton<MainMenuSegment>(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            } else {
              return Colors.white60;
            }
          }),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).primaryColorLight;
            } else {
              return Colors.white10;
            }
          }),
          iconColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            } else {
              return Colors.white70;
            }
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          visualDensity: VisualDensity.standard,
          minimumSize: WidgetStateProperty.all(const Size(0, 45)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        segments: List.generate(viewModel.menuTitles.length, (index) {
          final title = viewModel.menuTitles[index];
          final segmentValue = MainMenuSegment.values[index];
          final icon = [
            const Icon(Icons.dashboard_outlined),
            const Icon(Icons.inventory_2_outlined),
            const Icon(Icons.warehouse_outlined),
          ][index];

          return ButtonSegment(value: segmentValue, label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(title),
          ), icon: icon);
        }),
        selected: {viewModel.mainMenuSegmentView},
        onSelectionChanged: (Set<MainMenuSegment> newSelection) {
          if (newSelection.isNotEmpty) {
            context.read<BaseHeaderViewModel>().updateMainMenuSegmentView(newSelection.first);
          }
        },
      ),
    );
  }
}