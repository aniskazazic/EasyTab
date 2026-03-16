import 'dart:convert';

import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:easytab_desktop/models/search_result.dart';
import 'package:easytab_desktop/models/category.dart';

class CategoryProvider extends BaseProvider<Category> {
  CategoryProvider() : super("Categories");

  @override
  Category fromJson(json) {
    return Category.fromJson(json);
  }
}
