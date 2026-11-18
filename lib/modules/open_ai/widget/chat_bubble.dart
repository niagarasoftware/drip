import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../model/message_model.dart';

class MessageBubble extends StatefulWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              isUser ? 'You' : 'AI Assistant',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUser
                        ? [Theme.of(context).primaryColor, Colors.blueAccent]
                        : [Colors.grey[200]!, Colors.grey[300]!],
                  ),
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomLeft: Radius.circular(isUser ? 20 : 5),
                    bottomRight: Radius.circular(isUser ? 5 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.isImage)
                      GestureDetector(
                        onTap: () => _showFullImage(context, widget.message.content),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            base64Decode(widget.message.content),
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.error),
                          ),
                        ),
                      ),
                    if (widget.message.text != null || !widget.message.isImage)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: isUser
                            ? Text(
                          widget.message.isImage
                              ? widget.message.text!
                              : widget.message.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        )
                            : AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              widget.message.isImage
                                  ? widget.message.text!
                                  : widget.message.content,
                              textStyle: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              speed: Duration(milliseconds: widget.message.enableAnimation ? 10 : 0),
                            ),
                          ],
                          totalRepeatCount: 1,
                          onFinished: () {
                            setState(() {
                              widget.message.enableAnimation = false;
                            });
                            // widget.onAnimationCompleted?.call(widget.message);
                          },
                        ),
                      ),
                    if (widget.message.source != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Source: ${widget.message.source}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser ? Colors.white70 : Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('h:mm a').format(widget.message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              base64Decode(base64Image),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }
}