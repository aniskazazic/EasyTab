import 'dart:convert';
import 'package:easytab_desktop/models/zone.dart';
import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ZoneProvider extends BaseProvider<Zone> {
  ZoneProvider() : super("Zones");

  @override
  Zone fromJson(json) => Zone.fromJson(json);

  Future<List<Zone>> getByLocale(int localeId) async {
    var result = await get(filter: {"LocaleId": localeId, "RetrieveAll": true});
    return result.items ?? [];
  }

  Future<void> saveLayout(int localeId, List<Zone> zones) async {
    var url = "${BaseProvider.baseUrl}/Zones/save-layout";
    var uri = Uri.parse(url);

    var body = jsonEncode({
      "localeId": localeId,
      "zones": zones.map((z) => z.toJson()).toList(),
    });

    var response = await http.post(uri, headers: createHeaders(), body: body);

    if (!isValidResponse(response)) {
      throw Exception("Greška pri snimanju rasporeda zona");
    }
  }
}
