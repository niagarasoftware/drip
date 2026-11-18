import 'package:flutter/material.dart';
import '../utils/enums.dart';
import '../utils/helpers/screen_helper.dart';

abstract class ScreenLayoutBuilder extends StatelessWidget {
  const ScreenLayoutBuilder({super.key});

  Widget buildNarrow(BuildContext context);
  Widget buildMiddle(BuildContext context);
  Widget buildWide(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final type = ScreenHelper.getScreenType(width);

    switch (type) {
      case ScreenType.narrow:
        return buildNarrow(context);
      case ScreenType.middle:
        return buildMiddle(context);
      case ScreenType.wide:
        return buildWide(context);
    }
  }
}