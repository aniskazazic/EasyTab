import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easytab_mobile/main.dart'; // To access globalNavigatorKey
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/favourite_provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/screens/login_screen.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';

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
      debugPrint("Greška pri dekodiranju tokena u SessionManager: $e");
    }
  }

  Future<bool> triggerSessionExpiredFlow() async {
    if (_isPopupShowing) {
      // Ako se popup već prikazuje, čekamo da se on završi
      return _refreshCompleter!.future;
    }

    _isPopupShowing = true;
    final completer = Completer<bool>();
    _refreshCompleter = completer;
    _expirationTimer?.cancel();

    final success = await _showExpiredDialog();

    if (!completer.isCompleted) completer.complete(success);
    if (identical(_refreshCompleter, completer)) {
      _isPopupShowing = false;
      _refreshCompleter = null;
    }

    return success;
  }

  Future<bool> _showExpiredDialog() async {
    final context = globalNavigatorKey.currentContext;
    if (context == null) return false;
    var isRenewing = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: dialogTitle(context, 'Sesija je istekla'),
            content: const Text(
              'Vaša sesija je istekla. Molimo prijavite se ponovo za nastavak rada.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Na prijavu'),
              ),
              TextButton(
                onPressed: isRenewing
                    ? null
                    : () async {
                        setDialogState(() => isRenewing = true);
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
                child: Text(
                  isRenewing ? 'Obnavljanje sesije…' : 'Obnovi sesiju',
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      return true;
    } else {
      await logoutAndRedirect();
      return false;
    }
  }

  Future<void> logoutAndRedirect() async {
    stopSession();
    final context = globalNavigatorKey.currentContext;
    if (context != null) {
      Provider.of<FavouriteProvider>(context, listen: false).clear();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout(notifyServer: false);
      globalNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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
