import 'dart:convert';

import 'package:easytab_desktop/models/locale_deactivation_preview.dart';
import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:easytab_desktop/models/locale.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:http/http.dart' as http;

class LocaleProvider extends BaseProvider<Locale> {
  LocaleProvider() : super("Locale");

  Future<LocaleDeactivationPreview> getDeactivationPreview(int id) async {
    final response = await http.get(
      Uri.parse('${BaseProvider.baseUrl}/Locale/$id/deactivation-preview'),
      headers: createHeaders(),
    );
    validateResponse(response);
    return LocaleDeactivationPreview.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> reactivate(int id) async {
    final response = await http.put(
      Uri.parse('${BaseProvider.baseUrl}/Admin/locales/$id/reactivate'),
      headers: createHeaders(),
    );
    validateResponse(response);
    notifyListeners();
  }

  @override
  Future<Locale> insert(dynamic request) async {
    final locale = await super.insert(request);
    notifyListeners();
    return locale;
  }

  @override
  Future<Locale> update(int id, [dynamic request]) async {
    final locale = await super.update(id, request);
    notifyListeners();
    return locale;
  }

  @override
  Future<void> delete(int id) async {
    await super.delete(id);
    notifyListeners();
  }

  @override
  Locale fromJson(json) {
    return Locale.fromJson(json);
  }

  Future<List<Locale>> getForCurrentOwner() async {
    const pageSize = 100;
    final locales = <Locale>[];
    for (var page = 1; ; page++) {
      final result = await get(
        filter: {'Page': page, 'PageSize': pageSize, 'SortBy': 'Id'},
      );
      final items = result.items ?? <Locale>[];
      locales.addAll(items);
      if (items.length < pageSize) return locales;
    }
  }

  Future<List<Locale>> getForReservationFilter() => fetchAllPages(
    (filter) => get(filter: {...filter, 'SortBy': 'Id', 'IsDeleted': true}),
  );
}
