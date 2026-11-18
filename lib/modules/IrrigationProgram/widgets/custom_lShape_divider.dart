import 'package:flutter/material.dart';

class LShapeDivider extends CustomPainter{
  BuildContext context;
  double height;
  double? ctrValue;
  LShapeDivider({required this.context,required this.height, this.ctrValue});
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.strokeWidth = 1;
    paint.color = Theme.of(context).primaryColorDark  ;
    canvas.drawLine(const Offset(15, 0), Offset(15+((size.width-15)*ctrValue!), 0), paint);
    canvas.drawLine(const Offset(15, 0), Offset(15, height*ctrValue!), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
}

class AnimatedLShape extends StatefulWidget {
  final double height;
  const AnimatedLShape({super.key, required this.height});

  @override
  State<AnimatedLShape> createState() => _AnimatedLShapeState();
}

class _AnimatedLShapeState extends State<AnimatedLShape> with SingleTickerProviderStateMixin{
  late AnimationController ctrlValue;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ctrlValue = AnimationController(vsync: this,duration: const Duration(seconds: 1));
    ctrlValue.forward();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    ctrlValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 35,
      height: 10,
      child: CustomPaint(
        painter: LShapeDivider(context: context, height: widget.height, ctrValue: ctrlValue.value),
        size: const Size(1,1),
      ),
    );
  }
}