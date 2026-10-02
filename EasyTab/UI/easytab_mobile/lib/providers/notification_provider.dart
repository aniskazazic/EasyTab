import 'dart:async';
import 'dart:convert';
import 'package:easytab_mobile/models/notification.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';

class NotificationProvider extends BaseProvider<AppNotification> {
  NotificationProvider() : super("Notifications");

  @override
  AppNotification fromJson(data) =>
      AppNotification.fromJson(data as Map<String, dynamic>);

  List<AppNotification> notifications = [];
  bool isLoading = false;
  String? error;
  HubConnection? _connection;
  bool _isStarting = false;

  int get unreadCount =>
      notifications.where((n) => n.isRead == false).length;

  void syncSession(bool isAuthenticated) {
    if (isAuthenticated) {
      unawaited(_startConnection());
    } else if (_connection != null ||
        notifications.isNotEmpty ||
        isLoading ||
        error != null) {
      unawaited(stopConnection());
    }
  }

  Future<void> _startConnection() async {
    if (_connection != null || _isStarting) return;

    final baseUrl = BaseProvider.baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) return;

    _isStarting = true;
    final connection = HubConnectionBuilder()
        .withUrl(
          '$baseUrl/notificationHub',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => AuthProvider.accessToken ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection = connection;
    connection.on('NotificationReceived', _handleNotificationReceived);
    connection.onreconnected(({String? connectionId}) {
      unawaited(_reloadNotifications());
    });

    try {
      await connection.start();
      if (!AuthProvider.isAuthenticated || !identical(_connection, connection)) {
        await connection.stop();
      }
    } catch (e) {
      debugPrint('SignalR konekcija nije pokrenuta: $e');
      if (identical(_connection, connection)) {
        _connection = null;
      }
      try {
        await connection.stop();
      } catch (_) {}
    } finally {
      if (!AuthProvider.isAuthenticated && identical(_connection, connection)) {
        _connection = null;
      }
      _isStarting = false;
    }
  }

  Future<void> stopConnection() async {
    final connection = _connection;
    _connection = null;
    _isStarting = false;

    if (connection != null) {
      try {
        await connection.stop();
      } catch (e) {
        debugPrint('SignalR konekcija nije zaustavljena: $e');
      }
    }

    notifications = [];
    isLoading = false;
    error = null;
    notifyListeners();
  }

  void _handleNotificationReceived(List<Object?>? arguments) {
    try {
      final payload = arguments?.isNotEmpty == true ? arguments!.first : null;
      if (payload is! Map) return;

      final notification = AppNotification.fromJson(
        Map<String, dynamic>.from(payload),
      );
      _mergeNotifications([notification]);
      notifyListeners();
    } catch (e) {
      debugPrint('SignalR notifikacija nije obrađena: $e');
    }
  }

  Future<void> _reloadNotifications() async {
    final userId = AuthProvider.currentUserId;
    if (userId != null) {
      await getNotifications(userId);
    }
  }

  void _mergeNotifications(Iterable<AppNotification> incoming) {
    final merged = <int, AppNotification>{};
    final withoutId = <AppNotification>[];

    for (final notification in notifications) {
      if (notification.id == null) {
        withoutId.add(notification);
      } else {
        merged[notification.id!] = notification;
      }
    }

    for (final notification in incoming) {
      if (notification.id == null) {
        withoutId.add(notification);
      } else {
        merged.putIfAbsent(notification.id!, () => notification);
      }
    }

    notifications = [...merged.values, ...withoutId]
      ..sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
  }

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
      _mergeNotifications(data.map(
        (item) => AppNotification.fromJson(item as Map<String, dynamic>),
      ));

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
