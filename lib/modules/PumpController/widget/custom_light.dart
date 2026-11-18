import 'package:flutter/material.dart';

class LightToggle extends StatefulWidget {
  const LightToggle({
    super.key,
    required this.isLightOn,
    this.onToggle,
  });

  final bool isLightOn;
  final ValueChanged<bool>? onToggle;

  @override
  State<LightToggle> createState() => _LightToggleState();
}

class _LightToggleState extends State<LightToggle> with SingleTickerProviderStateMixin {
  late bool _isLightOn;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLightOn = widget.isLightOn;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant LightToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLightOn != widget.isLightOn) {
      setState(() {
        _isLightOn = widget.isLightOn;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleLight() {
    setState(() {
      _isLightOn = !_isLightOn;
    });
    widget.onToggle?.call(_isLightOn);
    if (_isLightOn) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleLight,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLightOn ? Colors.yellow.shade100 : Colors.grey.shade200,
                border: Border.all(color: _isLightOn ? Colors.yellow : Colors.grey),
                boxShadow: [
                  BoxShadow(
                    color: _isLightOn ? Colors.yellow.shade300.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
                    spreadRadius: _isLightOn ? 10 : 5,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _isLightOn ? Icons.lightbulb : Icons.lightbulb_outlined,
                color: _isLightOn ? Colors.yellow.shade700 : Colors.grey.shade600,
                size: 40,
                semanticLabel: _isLightOn ? 'Light On' : 'Light Off',
              ),
            ),
          );
        },
      ),
    );
  }
}