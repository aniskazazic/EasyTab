import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:easytab_desktop/models/locale.dart';

class LocaleProvider extends BaseProvider<Locale> {
  LocaleProvider() : super("Locale");

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
}
