// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentResponse _$PaymentResponseFromJson(Map<String, dynamic> json) =>
    PaymentResponse(
      id: (json['id'] as num).toInt(),
      reservationId: (json['reservationId'] as num).toInt(),
      amountKm: (json['amountKm'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      payPalOrderId: json['payPalOrderId'] as String,
    );

Map<String, dynamic> _$PaymentResponseToJson(PaymentResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reservationId': instance.reservationId,
      'amountKm': instance.amountKm,
      'amount': instance.amount,
      'currency': instance.currency,
      'status': instance.status,
      'payPalOrderId': instance.payPalOrderId,
    };
