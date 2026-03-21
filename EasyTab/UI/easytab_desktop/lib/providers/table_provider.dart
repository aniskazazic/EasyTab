import 'dart:convert';
import 'package:easytab_desktop/models/table.dart';
import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class TableProvider extends BaseProvider<Tables> {
  TableProvider() : super("Tables");

  @override
  Tables fromJson(json) => Tables.fromJson(json);

  Future<List<Tables>> getByLocale(int localeId) async {
    var result = await get(filter: {"LocaleId": localeId, "RetrieveAll": true});
    return result.items ?? [];
  }

  Future<void> saveLayout(int localeId, List<Tables> tables) async {
    var url = "${BaseProvider.baseUrl}/Tables/save-layout";
    var uri = Uri.parse(url);

    var body = jsonEncode({
      "localeId": localeId,
      "tables": tables.map((t) => t.toJson()).toList(),
    });

    var response = await http.post(uri, headers: createHeaders(), body: body);

    if (!isValidResponse(response)) {
      throw Exception("Greška pri snimanju rasporeda stolova");
    }
  }
}
