import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:easytab_desktop/models/locale.dart';

class LocaleProvider extends BaseProvider<Locale> {
  LocaleProvider() : super("Locale");

  @override
  Locale fromJson(json) {
    return Locale.fromJson(json);
  }

  Future<List<Locale>> getByOwner(int ownerId) async {
    var result = await get(filter: {"OwnerId": ownerId, "RetrieveAll": true});
    return result.items ?? [];
  }
}
