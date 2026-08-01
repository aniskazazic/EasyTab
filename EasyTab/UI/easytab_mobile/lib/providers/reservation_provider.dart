import 'dart:convert';

import 'package:easytab_mobile/models/time_slot.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ReservationProvider extends BaseProvider<dynamic> {
  ReservationProvider() : super("Reservations");

  @override
  dynamic fromJson(data) => data;

  /// Returns available time slots from the backend for the given [tableId] and [date].
  Future<List<TimeSlot>> getAvailableSlots(int tableId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first; // yyyy-MM-dd
    final url =
        '${BaseProvider.baseUrl}/Reservations/available-slots?tableId=$tableId&date=$dateStr';
    final uri = Uri.parse(url);

    final response = await http.get(uri, headers: createHeaders());
    validateResponse(response);

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Inserts a new reservation and returns the created object as raw JSON.
  Future<Map<String, dynamic>> insertReservation(
      Map<String, dynamic> request) async {
    final url = '${BaseProvider.baseUrl}/Reservations';
    final uri = Uri.parse(url);

    final response = await http.post(
      uri,
      headers: createHeaders(),
      body: jsonEncode(request),
    );
    validateResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
