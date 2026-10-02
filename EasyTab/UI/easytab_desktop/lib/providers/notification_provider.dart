import 'dart:async';
import 'dart:convert';

import 'package:easytab_desktop/models/notification.dart';
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';

class NotificationProvider extends ChangeNotifier {
  HubConnection? _connection;
  bool _isStarting = false;
  bool _sessionActive = false;
  int? _sessionUserId;
  List<AppNotification> notifications = [];
  int reservationRefreshVersion = 0;
  bool isLoading = false;
  String? error;

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  void syncSession(bool isAuthenticated) {
    final userId = _currentUserId;
    if (isAuthenticated && _sessionUserId != null && _sessionUserId != userId) {
      notifications = [];
      error = null;
      notifyListeners();
    }
    _sessionUserId = isAuthenticated ? userId : null;
    _sessionActive = isAuthenticated;
    if (isAuthenticated) {
      unawaited(_startConnection());
    } else if (_connection != null ||
        notifications.isNotEmpty ||
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
      if (!_sessionActive || !identical(_connection, connection)) {
        await connection.stop();
      }
    } catch (e) {
      debugPrint('SignalR desktop konekcija nije pokrenuta: $e');
      if (identical(_connection, connection)) {
        _connection = null;
      }
      try {
        await connection.stop();
      } catch (_) {}
    } finally {
      if (!_sessionActive && identical(_connection, connection)) {
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
        debugPrint('SignalR desktop konekcija nije zaustavljena: $e');
      }
    }

    notifications = [];
    _sessionUserId = null;
    isLoading = false;
    error = null;
    notifyListeners();
  }

  Future<void> getMyNotifications() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${BaseProvider.baseUrl}/Notifications'),
        headers: _headers(),
      );
      _validateResponse(response);
      final data = jsonDecode(response.body) as List<dynamic>;
      final userId = _currentUserId;
      final ownNotifications = data
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .where((item) => item.userId == userId)
          .toList();
      notifications = notifications
          .where((item) => item.userId == userId)
          .toList();
      _mergeNotifications(ownNotifications);
    } catch (e) {
      debugPrint('Greška pri učitavanju desktop notifikacija: $e');
      error = 'Greška pri učitavanju notifikacija.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<NotificationPage> getAllNotifications({required int page}) async {
    final query = Uri(
      queryParameters: {
        'Page': (page + 1).toString(),
        'PageSize': '10',
        'IncludeTotalCount': 'true',
        'SortBy': 'CreatedAt',
      },
    );
    final response = await http.get(
      Uri.parse('${BaseProvider.baseUrl}/Notifications/All${query.toString()}'),
      headers: _headers(),
    );
    _validateResponse(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
    return NotificationPage(
      items: items,
      totalCount: (data['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/Notifications/$notificationId/read'),
        headers: _headers(),
      );
      _validateResponse(response);
      final index = notifications.indexWhere(
        (item) => item.id == notificationId,
      );
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Greška pri označavanju desktop notifikacije: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/Notifications/read-all'),
        headers: _headers(),
      );
      _validateResponse(response);
      notifications = notifications
          .map((item) => item.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Greška pri označavanju desktop notifikacija: $e');
    }
  }

  void _handleNotificationReceived(List<Object?>? arguments) {
    try {
      final payload = arguments?.isNotEmpty == true ? arguments!.first : null;
      if (payload is! Map) return;
      final notification = AppNotification.fromJson(
        Map<String, dynamic>.from(payload),
      );
      if (notification.userId != _currentUserId) return;
      _mergeNotifications([notification]);
      reservationRefreshVersion++;
      notifyListeners();
    } catch (e) {
      debugPrint('Desktop SignalR notifikacija nije obrađena: $e');
    }
  }

  Future<void> _reloadNotifications() async {
    if (_sessionActive) {
      await getMyNotifications();
    }
  }

  void _mergeNotifications(Iterable<AppNotification> incoming) {
    final byId = <int, AppNotification>{
      for (final item in notifications)
        if (item.id != null) item.id!: item,
    };
    for (final item in incoming) {
      if (item.id != null) byId.putIfAbsent(item.id!, () => item);
    }
    notifications = byId.values.toList()
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AuthProvider.accessToken ?? ''}',
    };
  }

  int? get _currentUserId {
    final value = AuthProvider.accessTokenDecoded?['Id'];
    return int.tryParse(value?.toString() ?? '');
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode < 299) return;
    throw Exception('Notifications request failed: ${response.statusCode}');
  }
}
