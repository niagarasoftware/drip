import 'package:flutter/material.dart';

import '../../../Constants/properties.dart';

class BlinkingContainer extends StatefulWidget {
  final Widget child;
  BlinkingContainer({
    super.key,
    required this.child
  });

  @override
  _BlinkingContainerState createState() => _BlinkingContainerState();
}

class _BlinkingContainerState extends State<BlinkingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Total duration of 2 blinks
    );

    // Define the color animation
    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.red,
    ).animate(_controller);
    _startBlinking();
  }

  void _startBlinking() async {
    for (int i = 0; i < 3; i++) {
      await _controller.forward(); // Blink to red
      await _controller.reverse(); // Blink back to white
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              // color: Colors.white,
              color: _colorAnimation.value,
              boxShadow: AppProperties.customBoxShadowLiteTheme
          ),
          width: 300,
          child: widget.child,
        );
      },
    );
  }
}
