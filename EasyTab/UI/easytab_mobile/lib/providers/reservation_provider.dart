import 'dart:convert';

import 'package:easytab_mobile/models/reservation.dart';
import 'package:easytab_mobile/models/search_result.dart';
import 'package:easytab_mobile/models/time_slot.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ReservationProvider extends BaseProvider<Reservation> {
  ReservationProvider() : super("Reservations");

  @override
  Reservation fromJson(data) =>
      Reservation.fromJson(data as Map<String, dynamic>);

  List<Reservation> upcomingReservations = [];
  List<Reservation> pastReservations = [];
  bool isLoadingUpcoming = false;
  bool isLoadingPast = false;
  String? errorUpcoming;
  String? errorPast;

  Future<void> loadAll(int userId) async {
    await Future.wait([
      loadUpcoming(userId),
      loadPast(userId),
    ]);
  }

  Future<List<Reservation>> loadUpcoming(int userId) async {
    isLoadingUpcoming = true;
    errorUpcoming = null;
    notifyListeners();

    try {
      final result = await get(filter: {'UserId': userId, 'IsUpcoming': true});
      upcomingReservations = result.items ?? [];
      isLoadingUpcoming = false;
      notifyListeners();
      return upcomingReservations;
    } catch (e) {
      errorUpcoming = 'Greška pri učitavanju aktivnih rezervacija.';
      isLoadingUpcoming = false;
      notifyListeners();
      return [];
    }
  }

  Future<List<Reservation>> loadPast(int userId) async {
    isLoadingPast = true;
    errorPast = null;
    notifyListeners();

    try {
      final result = await get(filter: {'UserId': userId, 'IsUpcoming': false});
      pastReservations = result.items ?? [];
      isLoadingPast = false;
      notifyListeners();
      return pastReservations;
    } catch (e) {
      errorPast = 'Greška pri učitavanju prošlih rezervacija.';
      isLoadingPast = false;
      notifyListeners();
      return [];
    }
  }

  /// Returns available time slots from the backend for the given [tableId] and [date].
  Future<List<TimeSlot>> getAvailableSlots(int tableId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first; // yyyy-MM-dd
    final url =
        '${BaseProvider.baseUrl}/Reservations/available-slots?tableId=$tableId&date=$dateStr';
    final uri = Uri.parse(url);

    final response = await http.get(uri, headers: createHeaders());
    validateResponse(response);

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Inserts a new reservation, refreshes the user's reservations, and returns raw JSON.
  Future<Map<String, dynamic>> insertReservation(
    Map<String, dynamic> request,
  ) async {
    final url = '${BaseProvider.baseUrl}/Reservations';
    final uri = Uri.parse(url);

    final response = await http.post(
      uri,
      headers: createHeaders(),
      body: jsonEncode(request),
    );
    validateResponse(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (request['userId'] != null) {
      final uid = int.tryParse(request['userId'].toString());
      if (uid != null) {
        // Asinhrono osvježi stanje rezervacija u memoriji
        loadAll(uid);
      }
    }

    return data;
  }

  /// Cancels a reservation through the state machine.
  Future<void> cancelReservation(
    int id,
    String reason,
    int cancelledById,
  ) async {
    final url = '${BaseProvider.baseUrl}/Reservations/cancel/$id';
    final uri = Uri.parse(url);

    final response = await http.put(
      uri,
      headers: createHeaders(),
      body: jsonEncode({'reason': reason, 'cancelledById': cancelledById}),
    );
    validateResponse(response);

    await loadAll(cancelledById);
  }
}
