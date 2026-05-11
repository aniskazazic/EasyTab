import 'package:easytab_mobile/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  static String? username;
  static String? password;
  static User? currentUser;
  static bool _isAuthenticated = false;
  static String? _accessToken;
  String? _refreshToken;
  static Map<String, dynamic>? _accessTokenDecoded;
  String _baseUrl = "";

  static bool get isAuthenticated => _isAuthenticated;
  static String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  static Map<String, dynamic>? get accessTokenDecoded => _accessTokenDecoded;

  static bool get isAdmin =>
      currentUser?.userRoles?.any((r) => r.role?.name == 'Admin') ?? false;

  static bool get isOwner =>
      currentUser?.userRoles?.any((r) => r.role?.name == 'Vlasnik') ?? false;

  static bool get isWorker =>
      currentUser?.userRoles?.any((r) => r.role?.name == 'Radnik') ?? false;

  AuthProvider() {
    _baseUrl = const String.fromEnvironment(
      "BASE_URL",
      defaultValue: "http://10.0.2.2:5241",
    );
  }

  Future login(String username, String password) async {
    var url = "$_baseUrl/Access/Login";
    print("Login url: $url");
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var body = jsonEncode({"username": username, "password": password});

    http.Response response = await http.post(uri, headers: headers, body: body);

    if (isValidResponse(response)) {
      print("Response body: ${response.body}");
      var data = jsonDecode(response.body);
      print("Decoded data: $data");
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      _isAuthenticated = true;
      _accessTokenDecoded = JwtDecoder.decode(_accessToken ?? "");
      // Set a placeholder user - the actual user data will be loaded from API if needed

      print("AccessToken: $_accessToken");
      print("AccessTokenDecoded: $_accessTokenDecoded");
      notifyListeners();
    } else {
      throw Exception("Unknown error !");
    }
  }

  bool isValidResponse(http.Response response) {
    if (response.statusCode < 299) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized");
    } else {
      print(response.body);
      throw Exception('Nesto se desilo, molimo pokusajte kasnije');
    }
  }

  Map<String, String> createHeaders() {
    var headers = {"Content-Type": "application/json"};
    return headers;
  }

  static void clear() {
    currentUser = null;
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
    _isAuthenticated = false;
    _accessTokenDecoded = null;
    currentUser = null;
    notifyListeners();
  }
}
