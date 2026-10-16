import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:easytab_mobile/models/city.dart';

class CityProvider extends BaseProvider<City> {
  CityProvider() : super("Cities");

  @override
  City fromJson(json) {
    return City.fromJson(json);
  }
}
