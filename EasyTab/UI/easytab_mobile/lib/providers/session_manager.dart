import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easytab_mobile/main.dart'; // To access globalNavigatorKey
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';

class SessionManager with WidgetsBindingObserver {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  Timer? _expirationTimer;
  bool _isPopupShowing = false;
  bool _isObserving = false;
  Completer<bool>? _refreshCompleter;

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
    _isPopupShowing = false;
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      _refreshCompleter!.complete(false);
    }
    _refreshCompleter = null;
  }

  void _scheduleExpirationTimer(String token) {
    _expirationTimer?.cancel();

    try {
      if (JwtDecoder.isExpired(token)) {
        triggerSessionExpiredFlow();
        return;
      }

      final expiration = JwtDecoder.getExpirationDate(token);

      // Dodajemo 3 sekunde kašnjenja (safety buffer)
      final timeUntilExpiration =
          expiration.difference(DateTime.now()) + const Duration(seconds: 3);

      if (timeUntilExpiration.isNegative) {
        triggerSessionExpiredFlow();
      } else {
        _expirationTimer = Timer(timeUntilExpiration, () {
          triggerSessionExpiredFlow();
        });
      }
    } catch (e) {
      // Ako dekodiranje ne uspije, ne radimo nista (fallback na interceptor)
      print("Greška pri dekodiranju tokena u SessionManager: $e");
    }
  }

  Future<bool> triggerSessionExpiredFlow() async {
    if (_isPopupShowing) {
      // Ako se popup već prikazuje, čekamo da se on završi
      return _refreshCompleter!.future;
    }

    _isPopupShowing = true;
    _refreshCompleter = Completer<bool>();
    _expirationTimer?.cancel();

    final success = await _showExpiredDialog();

    _isPopupShowing = false;
    _refreshCompleter!.complete(success);
    _refreshCompleter = null;

    return success;
  }

  Future<bool> _showExpiredDialog() async {
    final context = globalNavigatorKey.currentContext;
    if (context == null) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sesija je istekla'),
          content: const Text(
            'Vaša sesija je istekla. Molimo prijavite se ponovo za nastavak rada.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                try {
                  final success = await authProvider.renewSession();
                  if (success && context.mounted) {
                    Navigator.pop(context, true);
                  } else if (context.mounted) {
                    Navigator.pop(context, false);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context, false);
                  }
                }
              },
              child: const Text('Prijavi se'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      return true;
    } else {
      _forceLogout();
      return false;
    }
  }

  void _forceLogout() {
    stopSession();
    final context = globalNavigatorKey.currentContext;
    if (context != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.logout(); // Očisti tokene
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final currentToken = AuthProvider.accessToken;
      if (currentToken != null && currentToken.isNotEmpty) {
        try {
          if (JwtDecoder.isExpired(currentToken)) {
            triggerSessionExpiredFlow();
          } else {
            _scheduleExpirationTimer(currentToken);
          }
        } catch (_) {}
      }
    } else if (state == AppLifecycleState.paused) {
      _expirationTimer?.cancel();
    }
  }
}
