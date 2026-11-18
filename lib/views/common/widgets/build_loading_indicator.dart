import 'package:flutter/cupertino.dart';
import 'package:loading_indicator/loading_indicator.dart';

Widget buildLoadingIndicator(BuildContext context) {
  return Center(
    child: Container(
      height: 50,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width / 2 - 100,
      ),
      child: const LoadingIndicator(indicatorType: Indicator.ballPulse),
    ),
  );
}