class NotificationListModel {
  final int pushNotificationId;
  final String notificationName;
  final String notificationDescription;
  bool pushNotification;   // mutable
  bool sendAndReceive;     // mutable

  NotificationListModel({
    required this.pushNotificationId,
    required this.notificationName,
    required this.notificationDescription,
    required this.pushNotification,
    required this.sendAndReceive,
  });

  factory NotificationListModel.fromJson(Map<String, dynamic> json) {
    return NotificationListModel(
      pushNotificationId: json['pushNotificationId'],
      notificationName: json['notificationName'],
      notificationDescription: json['notificationDescription'],
      pushNotification: json['pushNotification'],
      sendAndReceive: json['sendAndReceive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotificationId': pushNotificationId,
      'notificationName': notificationName,
      'notificationDescription': notificationDescription,
      'pushNotification': pushNotification,
      'sendAndReceive': sendAndReceive,
    };
  }
}