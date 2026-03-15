import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:easytab_desktop/models/search_result.dart';
import 'package:easytab_desktop/models/locale.dart';

class LocaleProvider extends ChangeNotifier {
  static String? _baseUrl;

  LocaleProvider() {
    _baseUrl = const String.fromEnvironment(
      "baseUrl",
      defaultValue: "http://localhost:5241",
    );
  }

  Future<SearchResult<Locale>> getLocale(dynamic filter) async {
    var url = "$_baseUrl/Locale";

    if (filter != null) {
      var querry = getQuerrySting(filter);
      url += "?$querry";
    }

    var uri = Uri.parse(url);
    var response = await http.get(uri, headers: createHeaders());
    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);

      var searchResult = SearchResult<Locale>();

      searchResult.totalCount = data['totalCount'];
      searchResult.items = List<Locale>.from(data['items'].map((item) => Locale.fromJson(item)));

      return searchResult;
    } else {
      throw Exception('Something went wrong, please try again later');
    }
  }

  String getQuerrySting(
    Map params, {
    String prefix = "&",
    bool inRecursion = false,
  }) {
    String querry = '';
    params.forEach((key, value) {
      if (inRecursion) {
        if (key is int) {
          key = "[$key]";
        } else if (value is List || value is Map) {
          key = ".$key";
        } else {
          key = ".$key";
        }
      }
      if (value is String || value is int || value is bool || value is double) {
        var encoded = value;
        if (value is String) {
          encoded = Uri.encodeComponent(value);
        }
        querry += "$prefix$key=$encoded";
      } else if (value is DateTime) {
        querry += "$prefix$key=${(value as DateTime).toIso8601String()}";
      } else if (value is List || value is Map) {
        if (value is List) {
          value = value.asMap();
          value.forEach((k, v) {
            querry += getQuerrySting(
              {k: v},
              prefix: '$prefix$key',
              inRecursion: true,
            );
          });
        }
      }
    });
    return querry;
  }

  bool isValidResponse(http.Response response) {
    if (response.statusCode <= 299) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Something went wrong, please try again later');
    }
  }

  Map<String, String> createHeaders() {
    String basicAuth =
        'Basic ${base64Encode(utf8.encode('${AuthProvider.username}:${AuthProvider.password}'))}';

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };
    return headers;
  }
}
