import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:easytab_mobile/models/country.dart';

class CountryProvider extends BaseProvider<Country> {
  CountryProvider() : super("Countries");

  @override
  Country fromJson(json) {
    return Country.fromJson(json);
  }
}
