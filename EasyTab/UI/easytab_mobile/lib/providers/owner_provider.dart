import 'dart:convert';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:easytab_mobile/models/locale.dart';
import 'package:flutter/material.dart';
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

    // Log svaki response za lakši debug
    for (int i = 0; i < results.length; i++) {
      debugPrint(
        'Request $i — status: ${results[i].statusCode}, body: ${results[i].body}',
      );
    }

    int safeInt(http.Response r) {
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return jsonDecode(r.body) ?? 0;
      }
      debugPrint('Greška na requestu: ${r.statusCode} — ${r.body}');
      return 0;
    }

    List<Map<String, dynamic>> safeList(http.Response r) {
      if (r.statusCode >= 200 && r.statusCode < 300) {
        try {
          final decoded = jsonDecode(r.body);
          if (decoded is List) {
            return List<Map<String, dynamic>>.from(
              decoded.map(
                (item) => {
                  'seats': item['Seats'] ?? item['seats'] ?? 0,
                  'count': item['Count'] ?? item['count'] ?? 0,
                  'percentage':
                      (item['Percentage'] ?? item['percentage'] ?? 0.0)
                          .toDouble(),
                },
              ),
            );
          }
        } catch (e) {
          debugPrint('Greška pri parsiranju table-distribution: $e');
        }
      } else {
        debugPrint('table-distribution greška: ${r.statusCode} — ${r.body}');
      }
      return [];
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
