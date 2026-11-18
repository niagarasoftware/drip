import 'package:flutter/material.dart';

Widget buildScale({required List<String> scale}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: scale.map((value) => Text(value, style: const TextStyle(color: Color(0xff9291A5)))).toList(),
  );
}

Widget buildAnimatedContainer({required Color color, required Duration value, required String motor, required Duration highestValue}) {
  final percentage = highestValue.inMilliseconds != 0
      ? (value.inMilliseconds / highestValue.inMilliseconds).clamp(0.0, 1.0)
      : 0.0;
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 10),
    height: 30,
    child: Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: const Color(0xffF5F7F9),
              borderRadius: BorderRadius.circular(2)
          ),
        ),
        AnimatedFractionallySizedBox(
          widthFactor: percentage > 1 ? 1 : percentage,
          duration: const Duration(milliseconds: 1000),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Center(
            child: motor.isNotEmpty
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    motor,
                    style: TextStyle(
                        color: !motor.contains("Motor") ? percentage >= 0.8 ? Colors.white : Colors.black : Colors.black
                    )
                ),
                const SizedBox(width: 5,),
                Text(
                    "${value.inHours.toString().padLeft(2, '0')}:${(value.inMinutes % 60).toString().padLeft(2, '0')}",
                    style: TextStyle(
                        color: !motor.contains("Motor") ? percentage >= 0.8 ? Colors.white : Colors.black : Colors.black
                    )
                ),
              ],
            )
                : Text(
                "${value.inHours.toString().padLeft(2, '0')}:${(value.inMinutes % 60).toString().padLeft(2, '0')}",
                style: TextStyle(
                    color: percentage >= 0.5 ? Colors.white : Colors.black
                )
            )
        )
      ],
    ),
  );
}

Widget buildDayWidget({
  required BuildContext context,
  required String date,
  required String day,
  required String month,
  Color backgroundColor = Colors.white,
  Color textColor = Colors.black,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20)
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(day, style: TextStyle(color: textColor, fontWeight: FontWeight.normal, fontSize: 10),),
        Text(date, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(month, style: TextStyle(color: textColor, fontWeight: FontWeight.normal, fontSize: 10)),
      ],
    ),
  );
}

Widget buildPageItem({
  required BuildContext context,
  required int index,
  required Widget subChild,
  required Widget child,
  required int pageControllerIndex,
  required currPageValue,
  required height,
  required scaleFactor
}) {
  double currentPage = currPageValue[pageControllerIndex];
  // print("_currPageValue"+currPageValue.toString());
  // print("index"+index.toString());
  double currScale;
  double currTrans;
  if (index == currentPage.floor()) {
    currScale = 1 - (currentPage - index) * (1 - scaleFactor);
    currTrans = height * (1 - currScale) / 2;
  } else if (index == currentPage.floor() + 1) {
    currScale = scaleFactor + (currentPage - index + 1) * (1 - scaleFactor);
    currTrans = height * (1 - currScale) / 2;
  } else if (index == currentPage.floor() - 1) {
    currScale = 1 - (currentPage - index) * (1 - scaleFactor);
    currTrans = height * (1 - currScale) / 2;
  } else {
    currScale = 0.8;
    currTrans = height * (1 - currScale) / 2;
  }

  Matrix4 matrix = Matrix4.identity()
    ..setEntry(0, 0, 1)
    ..setEntry(1, 1, currScale)
    ..setEntry(2, 2, 1)
    ..setTranslationRaw(0, currTrans, 0);

  return Transform(
    transform: matrix,
    child: Stack(
      children: [
        Container(
          // height: 200,
          // width: double.maxFinite,
          margin: const EdgeInsets.only(bottom: 20, top: 20, right: 5, left: 5),
          padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
          // decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(15),
          //     boxShadow: neumorphicButtonShadow,
          //     color: Colors.white
          // ),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 5),
              ),
            ],
            borderRadius: BorderRadius.circular(10),
            color: index.isEven
                ? const Color.fromARGB(255, 114, 218, 232)
                : const Color.fromARGB(255, 94, 101, 239),
          ),
          child: Center(
              child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white
                  ),
                  child: child
              )
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            child: subChild,
          ),
        ),
      ],
    ),
  );
}