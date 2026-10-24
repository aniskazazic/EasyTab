import 'package:json_annotation/json_annotation.dart';

part 'reservation.g.dart';

@JsonSerializable()
class Reservation {
  final bool isPaid;
  final double? paidAmountKm;
  final double? refundedAmountKm;
  final DateTime? paidAt;
  final DateTime? refundedAt;

  String get paymentLabel => refundedAmountKm != null
      ? 'Refundirano · ${refundedAmountKm!.toStringAsFixed(2)} KM'
      : isPaid
      ? 'Da · ${paidAmountKm?.toStringAsFixed(2) ?? "-"} KM'
      : 'Ne';
  final int? id;
  final int? userId;
  final int? tableId;
  final String? tableName;
  final int? numberOfGuests;
  final DateTime? reservationDate;
  final String? startTime;
  final String? endTime;
  final DateTime? createdAt;
  final String? reservationState;
  final int? approvedById;
  final DateTime? approvedAt;
  final int? cancelledById;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final int? localeId;
  final String? localeName;
  final String? localeAddress;
  final String? localeLogo;

  Reservation({
    this.isPaid = false,
    this.paidAmountKm,
    this.refundedAmountKm,
    this.paidAt,
    this.refundedAt,
    this.id,
    this.userId,
    this.tableId,
    this.tableName,
    this.numberOfGuests,
    this.reservationDate,
    this.startTime,
    this.endTime,
    this.createdAt,
    this.reservationState,
    this.approvedById,
    this.approvedAt,
    this.cancelledById,
    this.cancelledAt,
    this.cancellationReason,
    this.localeId,
    this.localeName,
    this.localeAddress,
    this.localeLogo,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) =>
      _$ReservationFromJson(json);
  Map<String, dynamic> toJson() => _$ReservationToJson(this);
}
