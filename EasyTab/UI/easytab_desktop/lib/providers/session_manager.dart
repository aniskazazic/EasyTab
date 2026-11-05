import 'dart:async';

import 'package:easytab_desktop/main.dart';
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';

class SessionManager with WidgetsBindingObserver {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  Timer? _expirationTimer;
  bool _isObserving = false;
  Completer<bool>? _expirationCompleter;
  DialogRoute<void>? _dialogRoute;

  void startSession(String accessToken) {
    if (!_isObserving) {
      WidgetsBinding.instance.addObserver(this);
      _isObserving = true;
    }
    _scheduleExpirationTimer(accessToken);
  }

  void stopSession() {
    if (_isObserving) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserving = false;
    }
    _expirationTimer?.cancel();
    final completer = _expirationCompleter;
    _expirationCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
    }
    final route = _dialogRoute;
    _dialogRoute = null;
    if (route != null && route.isActive) {
      route.navigator?.removeRoute(route);
    }
  }

  void _scheduleExpirationTimer(String token) {
    _expirationTimer?.cancel();
    try {
      final delay =
          JwtDecoder.getExpirationDate(token).difference(DateTime.now()) +
          const Duration(seconds: 3);
      _expirationTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
        unawaited(triggerSessionExpiredFlow());
      });
    } catch (_) {
      // Neispravan token se obrađuje kroz 401 odgovor API-ja.
    }
  }

  Future<bool> triggerSessionExpiredFlow({bool tryRefresh = true}) async {
    if (!_isObserving || AuthProvider.accessToken == null) {
      return false;
    }
    final pending = _expirationCompleter;
    if (pending != null) return pending.future;
    final context = globalNavigatorKey.currentContext;
    if (context == null) return false;

    _expirationTimer?.cancel();
    final completer = Completer<bool>();
    _expirationCompleter = completer;
    final version = AuthProvider.sessionVersion;
    var restored = false;
    try {
      if (tryRefresh && await context.read<AuthProvider>().renewSession()) {
        restored =
            _isObserving &&
            AuthProvider.hasActiveSession &&
            version == AuthProvider.sessionVersion;
        return restored;
      }
      if (_isObserving &&
          AuthProvider.hasActiveSession &&
          version == AuthProvider.sessionVersion &&
          context.mounted) {
        await _showExpiredDialog(context, completer);
      }
      return false;
    } finally {
      if (!completer.isCompleted) completer.complete(restored);
      if (identical(_expirationCompleter, completer)) {
        _expirationCompleter = null;
      }
    }
  }

  Future<void> _showExpiredDialog(
    BuildContext context,
    Completer<bool> completer,
  ) async {
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Sesija je istekla')),
            IconButton(
              tooltip: 'Zatvori',
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: const Text(
          'Vaša sesija je istekla. Molimo prijavite se ponovo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Na prijavu'),
          ),
        ],
      ),
    );
    _dialogRoute = route;
    try {
      await globalNavigatorKey.currentState!.push(route);
      if (!identical(_expirationCompleter, completer) ||
          AuthProvider.accessToken == null) {
        return;
      }
      await logoutAndRedirect();
    } finally {
      if (identical(_dialogRoute, route)) _dialogRoute = null;
    }
  }

  Future<void> logoutAndRedirect() async {
    final context = globalNavigatorKey.currentContext;
    if (context == null) {
      stopSession();
      return;
    }
    await context.read<AuthProvider>().logout(notifyServer: false);
    globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final token = AuthProvider.accessToken;
      if (token != null) _scheduleExpirationTimer(token);
    } else if (state == AppLifecycleState.paused) {
      _expirationTimer?.cancel();
    }
  }
}
