import 'package:flutter/material.dart';

class BounceEffectButton extends StatefulWidget {
  final String label;
  final Color textColor;
  final void Function()? onTap;

  const BounceEffectButton({
    super.key,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<BounceEffectButton> createState() => _BounceEffectButtonState();
}

class _BounceEffectButtonState extends State<BounceEffectButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    )); // Rotates 90 degrees (0.25 * 360)
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      _controller.forward().then((_) {
        _controller.reverse();
        widget.onTap!();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: RotationTransition(
        turns: _rotationAnimation,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          color: widget.onTap != null ? widget.textColor : Colors.grey,
          elevation: widget.onTap != null ? 10 : 0,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Icon(
                Icons.power_settings_new_rounded,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: const Offset(2, 2),
                    blurRadius: 6,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}