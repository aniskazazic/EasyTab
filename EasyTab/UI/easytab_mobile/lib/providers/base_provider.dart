import 'dart:convert';

import 'package:easytab_mobile/exceptions/api_exception.dart';
import 'package:easytab_mobile/models/search_result.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

abstract class BaseProvider<T> extends ChangeNotifier {
  static String? _baseUrl;
  String _endpoint = "";

  BaseProvider(String endpoint) {
    _endpoint = endpoint;
    _baseUrl = const String.fromEnvironment(
      "baseUrl",
      defaultValue: "http://10.0.2.2:5241",
    );
  }

  static String? get baseUrl => _baseUrl;
  String get endpoint => _endpoint;

  Future<SearchResult<T>> get({dynamic filter}) async {
    var url = "$baseUrl/$_endpoint";

    if (filter != null) {
      var querry = getQueryString(filter);
      url = "$url?$querry";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    validateResponse(response);

    var data = jsonDecode(response.body);

    var result = SearchResult<T>();

    result.totalCount = data['totalCount'];

    result.items = List<T>.from(data['items'].map((item) => fromJson(item)));

    return result;
  }

  Future<T> insert(dynamic request) async {
    var url = "$baseUrl/$_endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request);
    var response = await http.post(uri, headers: headers, body: jsonRequest);

    validateResponse(response);

    var data = jsonDecode(response.body);
    return fromJson(data);
  }

  Future<T> update(int id, [dynamic request]) async {
    var url = "$baseUrl/$_endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request);
    var response = await http.put(uri, headers: headers, body: jsonRequest);

    validateResponse(response);

    var data = jsonDecode(response.body);
    return fromJson(data);
  }

  Future<void> delete(int id) async {
    var url = "$baseUrl/$_endpoint/$id";
    var uri = Uri.parse(url);
    var response = await http.delete(uri, headers: createHeaders());
    validateResponse(response);
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

    validateResponse(response);
    return fromJson(jsonDecode(response.body));
  }

  /// Throws [ApiClientException] with a message from the API when status is not successful.
  void validateResponse(Response response) {
    if (response.statusCode < 299) {
      return;
    }
    if (response.statusCode == 401) {
      throw ApiClientException(
        ApiErrorParser.messageFromBody(response.body) ??
            'Niste autorizirani. Prijavite se ponovo.',
      );
    }

    final parsed = ApiErrorParser.messageFromBody(response.body);
    if (response.statusCode >= 500) {
      throw ApiClientException(
        parsed ?? 'Nešto se desilo, molimo pokušajte kasnije.',
      );
    }

    throw ApiClientException(
      parsed ?? 'Nešto se desilo, molimo pokušajte kasnije.',
    );
  }

  bool isValidResponse(Response response) {
    validateResponse(response);
    return true;
  }

  Map<String, String> createHeaders() {
    String accessToken = AuthProvider.accessToken ?? "";

    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
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
    validateResponse(response);

    var data = jsonDecode(response.body);

    return fromJson(data);
  }
}
