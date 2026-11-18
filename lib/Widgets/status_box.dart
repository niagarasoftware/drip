import 'package:flutter/material.dart';

class StatusBox extends StatefulWidget {
  final Color color;
  final Widget child;
  const StatusBox({super.key, required this.color, required this.child});

  @override
  State<StatusBox> createState() => _StatusBoxState();
}

class _StatusBoxState extends State<StatusBox> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: widget.color.withOpacity(0.1),
          border: Border.all(color: widget.color),
          borderRadius: BorderRadius.circular(5)
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10 , vertical: 5),
      child: widget.child,
    );
  }
}
