import 'package:json_annotation/json_annotation.dart';

part 'create_order_response.g.dart';

@JsonSerializable()
class CreateOrderResponse {
  final String orderId;
  final String approvalUrl;

  CreateOrderResponse({required this.orderId, required this.approvalUrl});
  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CreateOrderResponseToJson(this);
}
