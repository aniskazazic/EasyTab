import 'dart:convert';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:easytab_mobile/models/locale.dart';
import 'package:easytab_mobile/models/reservation.dart';
import 'package:easytab_mobile/models/search_result.dart';
import 'package:http/http.dart' as http;

class OwnerProvider extends BaseProvider<Locale> {
  OwnerProvider() : super("Owner");

  @override
  Locale fromJson(json) => Locale.fromJson(json);

  Future<SearchResult<Reservation>> getReservations({
    required DateTime date,
    String query = '',
    String? reservationState,
    int page = 0,
    int pageSize = 5,
  }) async {
    final base = BaseProvider.baseUrl;
    final params = <String, String>{
      'date': date.toIso8601String().split('T').first,
      'page': (page + 1).toString(),
      'pageSize': pageSize.toString(),
    };
    if (query.trim().isNotEmpty) params['q'] = query.trim();
    if (reservationState != null) params['reservationState'] = reservationState;

    final response = await sendRequestWithRetry(
      () => http.get(
        Uri.parse('$base/Owner/reservations').replace(queryParameters: params),
        headers: createHeaders(),
      ),
    );
    validateResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] ?? data['Items'] ?? [];
    final result = SearchResult<Reservation>(
      totalCount: (data['totalCount'] ?? data['TotalCount'] ?? 0) as int,
      items: (items as List)
          .map((item) => Reservation.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return result;
  }
}
