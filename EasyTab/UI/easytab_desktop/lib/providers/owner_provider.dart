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
  OwnerProvider() : super("Owner");

  @override
  Locale fromJson(json) => Locale.fromJson(json);

  Future<OwnerStats> getStats(int localeId) async {
    final headers = createHeaders();
    final base = BaseProvider.baseUrl;

    final results = await Future.wait([
      http.get(
        Uri.parse('$base/Owner/today-reservations?localeId=$localeId'),
        headers: headers,
      ),
      http.get(
        Uri.parse('$base/Owner/active-tables?localeId=$localeId'),
        headers: headers,
      ),
      http.get(
        Uri.parse('$base/Owner/total-tables?localeId=$localeId'),
        headers: headers,
      ),
      http.get(
        Uri.parse('$base/Owner/today-guests?localeId=$localeId'),
        headers: headers,
      ),
      http.get(
        Uri.parse('$base/Owner/table-distribution?localeId=$localeId'),
        headers: headers,
      ),
    ]);

    for (final response in results) {
      validateResponse(response);
    }

    int safeInt(http.Response r) {
      return (jsonDecode(r.body) as num).toInt();
    }

    List<Map<String, dynamic>> safeList(http.Response r) {
      final decoded = jsonDecode(r.body) as List;
      return List<Map<String, dynamic>>.from(
        decoded.map(
          (item) => {
            'seats': item['Seats'] ?? item['seats'] ?? 0,
            'count': item['Count'] ?? item['count'] ?? 0,
            'percentage': (item['Percentage'] ?? item['percentage'] ?? 0.0)
                .toDouble(),
          },
        ),
      );
    }

    return OwnerStats(
      todayReservations: safeInt(results[0]),
      activeTables: safeInt(results[1]),
      totalTables: safeInt(results[2]),
      todayGuests: safeInt(results[3]),
      tableDistribution: safeList(results[4]),
    );
  }
}
