class Chat {
  final String id;
  final String title;
  final DateTime lastModified;

  Chat({required this.id, required this.title, required this.lastModified});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lastModified': lastModified.toIso8601String(),
  };

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
    id: json['id'],
    title: json['title'],
    lastModified: DateTime.parse(json['lastModified']),
  );
}