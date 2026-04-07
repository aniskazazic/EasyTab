import 'dart:convert';

import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:easytab_mobile/models/search_result.dart';
import 'package:easytab_mobile/models/city.dart';

class CityProvider extends BaseProvider<City> {
  CityProvider() : super("Cities");

  @override
  City fromJson(json) {
    return City.fromJson(json);
  }
}
