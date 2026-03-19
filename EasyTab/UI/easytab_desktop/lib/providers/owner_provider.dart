import 'dart:convert';
import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:easytab_desktop/models/locale.dart';
import 'package:http/http.dart' as http;

class OwnerStats {
  final int todayReservations;
  final int activeTables;
  final int totalTables;
  final int todayGuests;
  final List<Map<String, dynamic>> tableDistribution;

  OwnerStats({
    required this.todayReservations,
    required this.activeTables,
    required this.totalTables,
    required this.todayGuests,
    required this.tableDistribution,
  });
}

class OwnerProvider extends BaseProvider<Locale> {
  final String? _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://localhost:5241",
  );
  OwnerProvider() : super("Owner");

  @override
  Locale fromJson(json) => Locale.fromJson(json);

  Future<OwnerStats> getStats(int localeId) async {
    final headers = createHeaders();

    final results = await Future.wait([
      http.get(
        Uri.parse('$_baseUrl/Owner/today-reservations?localeId=$localeId'),
        headers: headers,
      ),
      http.get(
        Uri.parse('$_baseUrl/Owner/active-tables?localeId=$localeId'),
        headers: headers,
      ),
      http.get(
        Uri.parse('$_baseUrl/Owner/total-tables?localeId=$localeId'),
        headers: headers,
      ),
      http.get(
        Uri.parse('$_baseUrl/Owner/today-guests?localeId=$localeId'),
        headers: headers,
      ),
      http.get(
        Uri.parse('$_baseUrl/Owner/table-distribution?localeId=$localeId'),
        headers: headers,
      ),
    ]);

    return OwnerStats(
      todayReservations: jsonDecode(results[0].body) ?? 0,
      activeTables: jsonDecode(results[1].body) ?? 0,
      totalTables: jsonDecode(results[2].body) ?? 0,
      todayGuests: jsonDecode(results[3].body) ?? 0,
      tableDistribution: List<Map<String, dynamic>>.from(
        jsonDecode(results[4].body),
      ),
    );
  }
}
