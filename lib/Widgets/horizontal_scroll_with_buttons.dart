import 'package:flutter/material.dart';

class HorizontalScrollWithButtons extends StatefulWidget {
  final Widget child;
  final double scrollAmount;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const HorizontalScrollWithButtons({
    super.key,
    required this.child,
    this.scrollAmount = 150.0,
    this.padding,
    this.controller,
  });

  @override
  State<HorizontalScrollWithButtons> createState() => _HorizontalScrollWithButtonsState();
}

class _HorizontalScrollWithButtonsState extends State<HorizontalScrollWithButtons> {
  late final ScrollController _scrollController;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _scrollController = widget.controller!;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
  }

  void _scrollLeft() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset - widget.scrollAmount,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollRight() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset + widget.scrollAmount,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _scrollLeft,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: widget.padding,
            child: widget.child,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _scrollRight,
        ),
      ],
    );
  }
}
