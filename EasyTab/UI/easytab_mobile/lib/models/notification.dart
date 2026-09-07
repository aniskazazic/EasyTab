import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@JsonSerializable()
class AppNotification {
  final int? id;
  final int? userId;
  final String? title;
  final String? message;
  final bool? isRead;
  final DateTime? createdAt;

  AppNotification({
    this.id,
    this.userId,
    this.title,
    this.message,
    this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}
