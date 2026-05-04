import 'dart:convert';

import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:easytab_desktop/models/search_result.dart';
import 'package:easytab_desktop/models/localeimage.dart';

class LocaleImageProvider extends BaseProvider<LocaleImage> {
  LocaleImageProvider() : super("LocaleImages");

  @override
  LocaleImage fromJson(json) {
    return LocaleImage.fromJson(json);
  }
}
