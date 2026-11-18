class Message {
  final String role;
  final String content;
  final DateTime timestamp;
  final String chatId;
  final bool isImage;
  final String? source;
  final String? text;
  final bool isVoice;
  final String? audioPath;
  bool enableAnimation;

  Message({
    required this.role,
    required this.content,
    required this.timestamp,
    required this.chatId,
    this.isImage = false,
    this.source,
    this.text,
    this.isVoice = false,
    this.audioPath,
    this.enableAnimation = false
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'chatId': chatId,
      'isImage': isImage,
      'source': source,
      'text': text,
      'isVoice': isVoice,
      'audioPath': audioPath,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      chatId: json['chatId'],
      isImage: json['isImage'] ?? false,
      source: json['source'],
      text: json['text'],
      isVoice: json['isVoice'] ?? false,
      audioPath: json['audioPath'],
    );
  }
}