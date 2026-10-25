import 'package:easytab_mobile/models/localeimage.dart';
import 'package:easytab_mobile/providers/base_provider.dart';

class LocaleImageProvider extends BaseProvider<LocaleImage> {
  LocaleImageProvider() : super('LocaleImages');

  @override
  LocaleImage fromJson(json) => LocaleImage.fromJson(json);

  Future<List<LocaleImage>> getByLocale(int localeId) async {
    return getLookupItems(filter: {'LocaleId': localeId});
  }
}
