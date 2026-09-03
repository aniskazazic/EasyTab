import 'dart:convert';
import 'package:easytab_desktop/models/reservation.dart';
import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ReservationProvider extends BaseProvider<Reservation> {
  ReservationProvider() : super("Reservations");

  @override
  Reservation fromJson(data) =>
      Reservation.fromJson(data as Map<String, dynamic>);

  /// Confirms a reservation through State Machine (transitions to 'Potvrđena').
  Future<Reservation> confirmReservation(int id, int approvedById) async {
    final url =
        '${BaseProvider.baseUrl}/Reservations/confirm/$id?approvedById=$approvedById';
    final uri = Uri.parse(url);

    final response = await http.put(uri, headers: createHeaders());
    validateResponse(response);

    final data = jsonDecode(response.body);
    return fromJson(data);
  }

  /// Cancels a reservation through State Machine (transitions to 'Otkazana').
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
  }

  /// Completes a reservation through State Machine (transitions to 'Završena').
  Future<Reservation> completeReservation(int id) async {
    final url = '${BaseProvider.baseUrl}/Reservations/complete/$id';
    final uri = Uri.parse(url);

    final response = await http.put(uri, headers: createHeaders());
    validateResponse(response);

    final data = jsonDecode(response.body);
    return fromJson(data);
  }
}
