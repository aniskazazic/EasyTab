import 'package:json_annotation/json_annotation.dart';

part 'create_order_response.g.dart';

@JsonSerializable()
class CreateOrderResponse {
  final String orderId;
  final String approvalUrl;
  final double amountKm;
  final double amount;
  final String currency;
  final double exchangeRate;

  CreateOrderResponse({
    required this.orderId,
    required this.approvalUrl,
    required this.amountKm,
    required this.amount,
    required this.currency,
    required this.exchangeRate,
  });
  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CreateOrderResponseToJson(this);
}
