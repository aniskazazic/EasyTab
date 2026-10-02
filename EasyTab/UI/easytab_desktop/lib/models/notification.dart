import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@JsonSerializable()
class AppNotification {
  final int? id;
  final int? userId;
  final String? title;
  final String? message;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    this.id,
    this.userId,
    this.title,
    this.message,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class NotificationPage {
  final List<AppNotification> items;
  final int totalCount;

  const NotificationPage({required this.items, required this.totalCount});
}
