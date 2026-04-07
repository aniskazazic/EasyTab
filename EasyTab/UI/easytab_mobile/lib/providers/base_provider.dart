import 'dart:convert';
import 'package:easytab_mobile/models/search_result.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

abstract class BaseProvider<T> extends ChangeNotifier {
  static String? baseUrl;
  String _endpoint = "";

  BaseProvider(String endpoint) {
    _endpoint = endpoint;
    baseUrl = const String.fromEnvironment(
      "baseUrl",
      defaultValue: "http://localhost:5241",
    );
  }

  Future<SearchResult<T>> get({dynamic filter}) async {
    var url = "$baseUrl/$_endpoint";

    if (filter != null) {
      var querry = getQueryString(filter);
      url = "$url?$querry";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: createHeaders());

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);

      var result = SearchResult<T>();

      result.totalCount = data['totalCount'];

      result.items = List<T>.from(data['items'].map((item) => fromJson(item)));

      return result;
    } else {
      throw Exception('Something went wrong, please try again later');
    }
  }

  Future<T> insert(dynamic request) async {
    var url = "$baseUrl/$_endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request);
    var response = await http.post(uri, headers: headers, body: jsonRequest);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw new Exception("Unknown error");
    }
  }

  Future<T> update(int id, [dynamic request]) async {
    var url = "$baseUrl/$_endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request);
    var response = await http.put(uri, headers: headers, body: jsonRequest);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw new Exception("Unknown error");
    }
  }

  Future<void> delete(int id) async {
    var url = "$baseUrl/$_endpoint/$id";
    var uri = Uri.parse(url);
    var response = await http.delete(uri, headers: createHeaders());
    if (!isValidResponse(response)) {
      throw Exception("Greška pri brisanju");
    }
  }

  T fromJson(data) {
    throw Exception("Method not implemented");
  }

  Future<T> login(String username, String password) async {
    var url = "$baseUrl/$_endpoint/login";
    var uri = Uri.parse(url);

    var response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      return fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Pogresno korisnicko ime ili lozinka!');
    } else {
      throw Exception('Greska na serveru');
      // throw Exception('Greska na serveru: ${response.statusCode}');
    }
  }

  bool isValidResponse(Response response) {
    if (response.statusCode < 299) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized");
    } else {
      throw Exception(
        'Server greška (${response.statusCode}): ${response.body}',
      );
    }
  }

  Map<String, String> createHeaders() {
    String username = AuthProvider.username ?? "";
    String password = AuthProvider.password ?? "";

    print("passed creds: $username, $password");

    String basicAuth =
        "Basic ${base64Encode(utf8.encode('$username:$password'))}";

    var headers = {
      "Content-Type": "application/json",
      "Authorization": basicAuth,
    };

    return headers;
  }

  String getQueryString(
    Map params, {
    String prefix = '&',
    bool inRecursion = false,
  }) {
    String query = '';
    params.forEach((key, value) {
      if (inRecursion) {
        if (key is int) {
          key = '[$key]';
        } else if (value is List || value is Map) {
          key = '.$key';
        } else {
          key = '.$key';
        }
      }
      if (value is String || value is int || value is double || value is bool) {
        var encoded = value;
        if (value is String) {
          encoded = Uri.encodeComponent(value);
        }
        query += '$prefix$key=$encoded';
      } else if (value is DateTime) {
        query += '$prefix$key=${(value as DateTime).toIso8601String()}';
      } else if (value is List || value is Map) {
        if (value is List) value = value.asMap();
        value.forEach((k, v) {
          query += getQueryString(
            {k: v},
            prefix: '$prefix$key',
            inRecursion: true,
          );
        });
      }
    });
    return query;
  }

  Future<T> getById(int id) async {
    var url = "$baseUrl/$_endpoint/$id";

    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);
    // throw new Exception("Greška");
    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);

      // var result = data as T;
      return fromJson(data);
      // return result;
    } else {
      throw new Exception("Unknown error");
    }
    // print("response: ${response.request} ${response.statusCode}, ${response.body}");
  }
}
