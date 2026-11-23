import 'package:easytab_mobile/models/zone.dart';
import 'package:easytab_mobile/providers/base_provider.dart';

class ZoneProvider extends BaseProvider<Zone> {
  ZoneProvider() : super("Zones");

  @override
  Zone fromJson(json) => Zone.fromJson(json);

  Future<List<Zone>> getByLocale(int localeId) async {
    return getLookupItems(filter: {'LocaleId': localeId});
  }
}
