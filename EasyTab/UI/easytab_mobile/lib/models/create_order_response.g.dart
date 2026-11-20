// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_order_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateOrderResponse _$CreateOrderResponseFromJson(Map<String, dynamic> json) =>
    CreateOrderResponse(
      orderId: json['orderId'] as String,
      approvalUrl: json['approvalUrl'] as String,
      amountKm: (json['amountKm'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      exchangeRate: (json['exchangeRate'] as num).toDouble(),
    );

Map<String, dynamic> _$CreateOrderResponseToJson(
  CreateOrderResponse instance,
) => <String, dynamic>{
  'orderId': instance.orderId,
  'approvalUrl': instance.approvalUrl,
  'amountKm': instance.amountKm,
  'amount': instance.amount,
  'currency': instance.currency,
  'exchangeRate': instance.exchangeRate,
};
