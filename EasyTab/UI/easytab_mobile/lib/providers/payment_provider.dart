import 'dart:convert';
import 'package:easytab_mobile/models/create_order_response.dart';
import 'package:easytab_mobile/models/payment_response.dart';
import 'package:easytab_mobile/models/reservation_checkout_request.dart';
import 'package:easytab_mobile/models/search_result.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class PaymentProvider extends BaseProvider<PaymentResponse> {
  PaymentProvider() : super('Payments');

  @override
  PaymentResponse fromJson(data) =>
      PaymentResponse.fromJson(data as Map<String, dynamic>);

  Future<CreateOrderResponse> createOrder(
    ReservationCheckoutRequest request,
  ) async {
    final response = await sendRequestWithRetry(
      () => http.post(
        Uri.parse('${BaseProvider.baseUrl}/Payments/checkout'),
        headers: createHeaders(),
        body: jsonEncode(request.toJson()),
      ),
    );
    validateResponse(response);
    return CreateOrderResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PaymentResponse> capture(String orderId) async {
    final response = await sendRequestWithRetry(
      () => http.post(
        Uri.parse(
          '${BaseProvider.baseUrl}/Payments/checkout/${Uri.encodeComponent(orderId)}/capture',
        ),
        headers: createHeaders(),
      ),
    );
    validateResponse(response);
    return fromJson(jsonDecode(response.body));
  }

  Future<SearchResult<PaymentResponse>> byReservation(
    int reservationId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await sendRequestWithRetry(
      () => http.get(
        Uri.parse(
          '${BaseProvider.baseUrl}/Payments/by-reservation/$reservationId',
        ).replace(
          queryParameters: {
            'Page': page.clamp(1, 2147483647).toString(),
            'PageSize': pageSize.clamp(1, 100).toString(),
          },
        ),
        headers: createHeaders(),
      ),
    );
    validateResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SearchResult<PaymentResponse>()
      ..totalCount = data['totalCount'] as int?
      ..items = (data['items'] as List).map(fromJson).toList();
  }
}
