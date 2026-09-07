import 'dart:convert';
import 'package:easytab_mobile/models/notification.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NotificationProvider extends BaseProvider<AppNotification> {
  NotificationProvider() : super("Notifications");

  @override
  AppNotification fromJson(data) =>
      AppNotification.fromJson(data as Map<String, dynamic>);

  List<AppNotification> notifications = [];
  bool isLoading = false;
  String? error;

  int get unreadCount =>
      notifications.where((n) => n.isRead == false).length;

  Future<List<AppNotification>> getNotifications(int userId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final url = '${BaseProvider.baseUrl}/Notifications?userId=$userId';
      final uri = Uri.parse(url);

      final response = await http.get(uri, headers: createHeaders());
      validateResponse(response);

      final List<dynamic> data = jsonDecode(response.body);
      notifications = data
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList();

      isLoading = false;
      notifyListeners();
      return notifications;
    } catch (e) {
      debugPrint('Greška pri učitavanju notifikacija: $e');
      error = 'Greška pri učitavanju notifikacija.';
      isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final url = '${BaseProvider.baseUrl}/Notifications/$notificationId/read';
      final uri = Uri.parse(url);

      final response = await http.put(uri, headers: createHeaders());
      validateResponse(response);

      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final current = notifications[index];
        notifications[index] = AppNotification(
          id: current.id,
          userId: current.userId,
          title: current.title,
          message: current.message,
          isRead: true,
          createdAt: current.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Greška pri označavanju notifikacije: $e');
    }
  }

  Future<void> markAllAsRead(int userId) async {
    try {
      final url = '${BaseProvider.baseUrl}/Notifications/read-all?userId=$userId';
      final uri = Uri.parse(url);

      final response = await http.put(uri, headers: createHeaders());
      validateResponse(response);

      notifications = notifications.map((n) {
        return AppNotification(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Greška pri označavanju svih notifikacija: $e');
    }
  }
}
