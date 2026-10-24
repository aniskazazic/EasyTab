import 'dart:convert';
import 'package:easytab_desktop/models/payment_summary.dart';
import 'package:easytab_desktop/models/reservation.dart';
import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ReservationProvider extends BaseProvider<Reservation> {
  ReservationProvider() : super("Reservations");

  Future<PaymentSummary> getPaymentSummary({
    required DateTime from,
    required DateTime to,
    int? localeId,
  }) async {
    String date(DateTime value) => value.toIso8601String().split('T').first;
    final uri =
        Uri.parse(
          '${BaseProvider.baseUrl}/Reservations/payment-summary',
        ).replace(
          queryParameters: {
            'From': date(from),
            'To': date(to),
            if (localeId != null) 'LocaleId': '$localeId',
          },
        );
    final response = await http.get(uri, headers: createHeaders());
    validateResponse(response);
    return PaymentSummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Reservation fromJson(data) =>
      Reservation.fromJson(data as Map<String, dynamic>);

  /// Confirms a reservation through State Machine (transitions to 'Potvrđena').
  Future<Reservation> confirmReservation(int id) async {
    final url = '${BaseProvider.baseUrl}/Reservations/confirm/$id';
    final uri = Uri.parse(url);

    final response = await http.put(uri, headers: createHeaders());
    validateResponse(response);

    final data = jsonDecode(response.body);
    return fromJson(data);
  }

  /// Cancels a reservation through State Machine (transitions to 'Otkazana').
  Future<void> cancelReservation(int id, String reason) async {
    final url = '${BaseProvider.baseUrl}/Reservations/cancel/$id';
    final uri = Uri.parse(url);

    final response = await http.put(
      uri,
      headers: createHeaders(),
      body: jsonEncode({'reason': reason}),
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
