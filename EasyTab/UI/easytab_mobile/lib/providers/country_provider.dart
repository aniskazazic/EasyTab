import 'dart:convert';

import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:easytab_mobile/models/search_result.dart';
import 'package:easytab_mobile/models/country.dart';

class CountryProvider extends BaseProvider<Country> {
  CountryProvider() : super("Countries");

  @override
  Country fromJson(json) {
    return Country.fromJson(json);
  }
}
