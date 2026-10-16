import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:easytab_desktop/models/city.dart';

class CityProvider extends BaseProvider<City> {
  CityProvider() : super("Cities");

  @override
  City fromJson(json) {
    return City.fromJson(json);
  }
}
