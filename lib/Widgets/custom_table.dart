import 'package:flutter/material.dart';

import '../Constants/properties.dart';

class CustomTableHeader extends StatelessWidget {
  final String title;
  final double width;
  const CustomTableHeader({
    super.key,
    required this.title,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Color(0xff8FB9BE)
      ),
      width: width,
      height: 40,
      alignment: Alignment.center,
      child: Text(title,style: AppProperties.tableHeaderStyle,),
    );
  }
}

class CustomTableCell extends StatelessWidget {
  final String title;
  final double width;
  const CustomTableCell({
    super.key,
    required this.title,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Color(0xffE0FCFF)
      ),
      width: width,
      height: 40,
      alignment: Alignment.center,
      child: Text(title,style: AppProperties.tableHeaderStyle,),
    );
  }
}

class CustomTableCellPassingWidget extends StatelessWidget {
  final Widget widget;
  final double width;
  const CustomTableCellPassingWidget({
    super.key,
    required this.widget,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Color(0xffE0FCFF)
      ),
      width: width,
      height: 40,
      alignment: Alignment.center,
      child: widget,
    );
  }
}
