import 'package:flutter/material.dart';

import '../Constants/properties.dart';

class TitleWithBackButton extends StatelessWidget {
  final double titleWidth;
  final String title;
  final void Function()? onPressed;
  const TitleWithBackButton({
    super.key,
    required this.onPressed,
    required this.title,
    required this.titleWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: onPressed,
        ),
          Text(title, style: AppProperties.titleTextStyle,)
      ],
    );
  }
}
