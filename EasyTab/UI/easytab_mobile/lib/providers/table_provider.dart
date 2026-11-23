import 'package:easytab_mobile/models/table.dart';
import 'package:easytab_mobile/providers/base_provider.dart';

class TableProvider extends BaseProvider<Tables> {
  TableProvider() : super("Tables");

  @override
  Tables fromJson(json) => Tables.fromJson(json);

  Future<List<Tables>> getByLocale(int localeId) async {
    return getLookupItems(filter: {'LocaleId': localeId});
  }
}
