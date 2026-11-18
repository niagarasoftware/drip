import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnimatedClouds extends StatefulWidget {
  @override
  _AnimatedCloudsState createState() => _AnimatedCloudsState();
}

class _AnimatedCloudsState extends State<AnimatedClouds> with TickerProviderStateMixin {  // Changed to TickerProviderStateMixin
  late List<AnimationController> _controllers;
  late List<Animation<double>> _cloudAnimations;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _controllers = List.generate(3, (_) => AnimationController(
      duration: const Duration(seconds: 40),
      vsync: this,
    ));

    // Initialize animations with proper directions
    _cloudAnimations = [
      // First cloud: left to right (0.0 to 1.0)
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controllers[0], curve: Curves.linear),
      ),
      // Second cloud: right to left (1.0 to 0.0)
      Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _controllers[1], curve: Curves.linear),
      ),
      // Third cloud: left to right (0.0 to 1.0)
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controllers[2], curve: Curves.linear),
      ),
    ];

    // Start animations
    for (var controller in _controllers) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(  // Added SizedBox to provide proper constraints
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _cloudAnimations[index],
            builder: (context, child) {
              return Positioned(
                top: (index + 1) * 100.0,
                left: _calculateLeftPosition(
                  context,
                  _cloudAnimations[index].value,
                  150 + index * 30.0,
                ),
                child: child!,
              );
            },
            child: Image.asset(
              'assets/mob_dashboard/weatherbgcloud.png',
              width: 150 + index * 30.0,
              color: index == 0 ? Colors.grey[300] : null,
            ),
          );
        }),
      ),
    );
  }

  double _calculateLeftPosition(BuildContext context, double animationValue, double cloudWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    return animationValue * (screenWidth - cloudWidth);
  }
}