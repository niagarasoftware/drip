
import 'package:flutter/material.dart';

class SlidingSendButton extends StatefulWidget {
  final Function onSend;

  const SlidingSendButton({Key? key, required this.onSend}) : super(key: key);

  @override
  _SlidingSendButtonState createState() => _SlidingSendButtonState();
}

class _SlidingSendButtonState extends State<SlidingSendButton> {
  double _dragPosition = 0.0;
  final double _maxDragDistance = 200.0;
  IconData icon = Icons.send;
  bool isSent = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          // Update the drag position within bounds
          if (!isSent) {
            _dragPosition += details.delta.dx;
            _dragPosition = _dragPosition.clamp(0.0, _maxDragDistance);
          }
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragPosition == _maxDragDistance) {
          widget.onSend(); // Trigger the send action
          setState(() {
            isSent = true;
            icon = Icons.done; // Change icon to 'done'
          });
          /* Future.delayed(const Duration(seconds: 1), () {
            setState(() {
              // Reset after a delay
              // isSent = false;
              // _dragPosition = 0.0;
              // icon = Icons.send;
            });
          });*/
        } else {
          /* // Reset position if not fully dragged
          setState(() {
            // _dragPosition = 0.0;
          });*/
        }
      },
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Background track
          Container(
            width: _maxDragDistance + 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          // "Slide to Send" text
          Positioned(
            left: isSent ? 100 : 70,
            child: Text(
              isSent ? "Sent!" : "-- Slide to Send -->",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Sliding button with animation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: _dragPosition,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSent ? Colors.green : Theme.of(context).primaryColorLight,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}