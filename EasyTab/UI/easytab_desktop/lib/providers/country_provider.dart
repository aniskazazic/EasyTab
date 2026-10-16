import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:easytab_desktop/models/country.dart';

class CountryProvider extends BaseProvider<Country> {
  CountryProvider() : super("Countries");

  @override
  Country fromJson(json) {
    return Country.fromJson(json);
  }
}
