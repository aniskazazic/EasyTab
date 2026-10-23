import 'package:json_annotation/json_annotation.dart';

part 'reservation.g.dart';

@JsonSerializable()
class Reservation {
  final int? id;
  final bool isPaid;
  final double? paidAmountKm;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
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
    this.id,
    this.isPaid = false,
    this.paidAmountKm,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
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

  bool get isActive => const [
    'pending',
    'confirmed',
    'na čekanju',
    'potvrđena',
    'potvrdena',
  ].contains(reservationState?.toLowerCase());

  String get customerName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory Reservation.fromJson(Map<String, dynamic> json) =>
      _$ReservationFromJson(json);
  Map<String, dynamic> toJson() => _$ReservationToJson(this);
}
