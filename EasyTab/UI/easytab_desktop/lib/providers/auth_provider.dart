import 'dart:async';
import 'dart:convert';
import 'package:easytab_desktop/config/app_config.dart';
import 'package:easytab_desktop/exceptions/api_exception.dart';
import 'package:easytab_desktop/models/user.dart';
import 'package:easytab_desktop/providers/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  static String? _accessToken;
  static String? _refreshToken;
  static Map<String, dynamic>? _accessTokenDecoded;
  static Future<bool>? _refreshFuture;
  static AuthProvider? _current;
  static int _sessionVersion = 0;
  static bool _isLoggingOut = false;
  Future<void>? _logoutFuture;
  Future<void> Function()? beforeLogout;

  AuthProvider() {
    _current = this;
  }

  bool get isAuthenticated => _isAuthenticated && !_isLoggingOut;
  static String? get accessToken => _isLoggingOut ? null : _accessToken;
  static bool get hasActiveSession => accessToken != null;
  static int get sessionVersion => _sessionVersion;
  String? get refreshToken => _refreshToken;
  static Map<String, dynamic>? get accessTokenDecoded => _accessTokenDecoded;

  static User? currentUser;

  static bool get isAdmin =>
      currentUser?.userRoles?.any((r) => r.role?.name == 'Admin') ?? false;

  static bool get isOwner =>
      currentUser?.userRoles?.any((r) => r.role?.name == 'Vlasnik') ?? false;

  Future login(String username, String password) async {
    await _logoutFuture;
    final version = ++_sessionVersion;
    _refreshFuture = null;
    var url = "${AppConfig.apiBaseUrl}/Access/Login";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var body = jsonEncode({"username": username, "password": password});

    http.Response response = await http.post(uri, headers: headers, body: body);

    validateLoginResponse(response);
    if (version != _sessionVersion) {
      throw ApiClientException('Prijava je prekinuta. Pokušajte ponovo.');
    }

    var data = jsonDecode(response.body);
    _accessToken = data['accessToken'];
    _refreshToken = data['refreshToken'];
    _isAuthenticated = true;
    _accessTokenDecoded = JwtDecoder.decode(_accessToken ?? "");
    notifyListeners();
    SessionManager().startSession(_accessToken!);
  }

  Future<bool> renewSession() async {
    if (!hasActiveSession) return false;
    if (_refreshFuture != null) return _refreshFuture!;
    final pending = _renewSession();
    _refreshFuture = pending;
    try {
      return await pending;
    } finally {
      if (identical(_refreshFuture, pending)) _refreshFuture = null;
    }
  }

  Future<bool> _renewSession() async {
    final sessionRefreshToken = _refreshToken;
    final version = _sessionVersion;
    if (sessionRefreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/Access/LoginWithRefreshToken'),
        headers: createHeaders(),
        body: jsonEncode({'refreshToken': sessionRefreshToken}),
      );

      if (version != _sessionVersion || _refreshToken != sessionRefreshToken) {
        return false;
      }
      if (response.statusCode < 200 || response.statusCode > 299) {
        return false;
      }

      final data = jsonDecode(response.body);
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      _accessTokenDecoded = JwtDecoder.decode(_accessToken ?? '');
      if (!_isLoggingOut) {
        SessionManager().startSession(_accessToken!);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout({bool notifyServer = true}) async {
    if (_logoutFuture != null) return _logoutFuture!;
    final pending = _logout(notifyServer);
    _logoutFuture = pending;
    try {
      await pending;
    } finally {
      if (identical(_logoutFuture, pending)) _logoutFuture = null;
    }
  }

  Future<void> _logout(bool notifyServer) async {
    _isLoggingOut = true;
    SessionManager().stopSession();
    try {
      await beforeLogout?.call();
      await _refreshFuture;
      var sessionAccessToken = _accessToken;
      final sessionRefreshToken = _refreshToken;
      _sessionVersion++;
      if (notifyServer &&
          sessionAccessToken != null &&
          sessionRefreshToken != null &&
          (JwtDecoder.isExpired(sessionAccessToken) ||
              !_accessTokenDecoded!.containsKey('sid'))) {
        final response = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/Access/LoginWithRefreshToken'),
          headers: createHeaders(),
          body: jsonEncode({'refreshToken': sessionRefreshToken}),
        );
        if (response.statusCode == 200) {
          sessionAccessToken =
              jsonDecode(response.body)['accessToken'] as String;
        }
      }
      if (notifyServer && sessionAccessToken != null) {
        await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/Access/Logout'),
          headers: {
            ...createHeaders(),
            'Authorization': 'Bearer $sessionAccessToken',
          },
        );
      }
    } catch (_) {
      // Local logout must complete even when the server is unavailable.
    } finally {
      _accessToken = null;
      _refreshToken = null;
      _isAuthenticated = false;
      _accessTokenDecoded = null;
      currentUser = null;
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  static Future<http.Response> sendAuthorizedRequest(
    Future<http.Response> Function() request,
  ) async {
    final version = _sessionVersion;
    final token = accessToken;
    if (token == null) throw ApiClientException('Sesija nije aktivna.');
    var response = await request();
    if (!hasActiveSession || version != _sessionVersion) {
      throw ApiClientException('Zahtjev je prekinut.');
    }
    if (response.statusCode == 401) {
      if (accessToken == token && !(await _current!.renewSession())) {
        if (hasActiveSession && version == _sessionVersion) {
          unawaited(
            SessionManager().triggerSessionExpiredFlow(tryRefresh: false),
          );
        }
        throw ApiClientException('Niste autorizirani. Prijavite se ponovo.');
      }
      if (!hasActiveSession || version != _sessionVersion) {
        throw ApiClientException('Zahtjev je prekinut.');
      }
      response = await request();
      if (!hasActiveSession || version != _sessionVersion) {
        throw ApiClientException('Zahtjev je prekinut.');
      }
      if (response.statusCode == 401) {
        unawaited(
          SessionManager().triggerSessionExpiredFlow(tryRefresh: false),
        );
      }
    }
    return response;
  }

  /// Login failures must not reveal whether the username exists (username enumeration).
  void validateLoginResponse(http.Response response) {
    if (response.statusCode < 299) {
      return;
    }

    if (response.statusCode == 400 || response.statusCode == 401) {
      throw ApiClientException('Pogrešno korisničko ime ili lozinka.');
    }

    final parsed = ApiErrorParser.messageFromBody(response.body);
    throw ApiClientException(
      parsed ?? 'Nešto se desilo, molimo pokušajte kasnije.',
    );
  }

  /// Throws [ApiClientException] with a message from the API when status is not successful.
  void validateResponse(http.Response response) {
    if (response.statusCode < 299) {
      return;
    }

    final parsed = ApiErrorParser.messageFromBody(response.body);
    if (response.statusCode == 401) {
      throw ApiClientException(
        parsed ?? 'Pogrešno korisničko ime ili lozinka!',
      );
    }
    if (response.statusCode >= 500) {
      throw ApiClientException(
        parsed ?? 'Nešto se desilo, molimo pokušajte kasnije.',
      );
    }

    throw ApiClientException(
      parsed ?? 'Nešto se desilo, molimo pokušajte kasnije.',
    );
  }

  Map<String, String> createHeaders() {
    var headers = {"Content-Type": "application/json"};
    return headers;
  }

  static void clear() {
    currentUser = null;
  }
}
