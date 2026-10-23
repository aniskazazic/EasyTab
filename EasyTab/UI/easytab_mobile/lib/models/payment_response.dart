import 'package:json_annotation/json_annotation.dart';

part 'payment_response.g.dart';

@JsonSerializable()
class PaymentResponse {
  final int id;
  final int reservationId;
  final double amountKm;
  final String status;
  final String payPalOrderId;

  PaymentResponse({
    required this.id,
    required this.reservationId,
    required this.amountKm,
    required this.status,
    required this.payPalOrderId,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';
  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentResponseToJson(this);
}
