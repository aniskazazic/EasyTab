import 'dart:convert';
import 'package:easytab_desktop/exceptions/api_exception.dart';
import 'package:easytab_desktop/models/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  static String? _accessToken;
  String? _refreshToken;
  static Map<String, dynamic>? _accessTokenDecoded;

  bool get isAuthenticated => _isAuthenticated;
  static String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  static Map<String, dynamic>? get accessTokenDecoded => _accessTokenDecoded;

  String _baseUrl = "";

  static User? currentUser;

  static bool get isAdmin =>
      currentUser?.userRoles?.any((r) => r.role?.name == 'Admin') ?? false;

  static bool get isOwner =>
      currentUser?.userRoles?.any((r) => r.role?.name == 'Vlasnik') ?? false;

  AuthProvider() {
    _baseUrl = const String.fromEnvironment(
      "BASE_URL",
      defaultValue: "http://localhost:5241",
    );
  }

  Future login(String username, String password) async {
    var url = "$_baseUrl/Access/Login";
    print("Login url: $url");
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var body = jsonEncode({"username": username, "password": password});

    http.Response response = await http.post(uri, headers: headers, body: body);

    validateLoginResponse(response);

    print("Response body: ${response.body}");
    var data = jsonDecode(response.body);
    print("Decoded data: $data");
    _accessToken = data['accessToken'];
    _refreshToken = data['refreshToken'];
    _isAuthenticated = true;
    _accessTokenDecoded = JwtDecoder.decode(_accessToken ?? "");
    print("AccessToken: $_accessToken");
    print("AccessTokenDecoded: $_accessTokenDecoded");
    notifyListeners();
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
    _isAuthenticated = false;
    _accessTokenDecoded = null;
    currentUser = null;
    notifyListeners();
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

/*
  static String? username;
  static String? password;
  static User? currentUser;

  static bool get isAdmin =>
      currentUser?.userRoles?.any((r) => r.role?.name == 'Admin') ?? false;

  static bool get isOwner =>
      currentUser?.userRoles?.any((r) => r.role?.name == 'Vlasnik') ?? false;

  static void clear() {
    username = null;
    password = null;
    currentUser = null;
  }
  */
