import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:easytab_mobile/models/locale.dart';

class LocaleProvider extends BaseProvider<Locale> {
  LocaleProvider() : super("Locale");

  @override
  Locale fromJson(json) {
    return Locale.fromJson(json);
  }
}
