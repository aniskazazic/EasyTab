import 'dart:convert';

import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:easytab_desktop/models/search_result.dart';
import 'package:easytab_desktop/models/country.dart';

class CountryProvider extends BaseProvider<Country> {
  CountryProvider() : super("Countries");

  @override
  Country fromJson(json) {
    return Country.fromJson(json);
  }
}
