// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reservation _$ReservationFromJson(Map<String, dynamic> json) => Reservation(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      tableId: (json['tableId'] as num?)?.toInt(),
      tableName: json['tableName'] as String?,
      numberOfGuests: (json['numberOfGuests'] as num?)?.toInt(),
      reservationDate: json['reservationDate'] == null
          ? null
          : DateTime.parse(json['reservationDate'] as String),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      reservationState: json['reservationState'] as String?,
      approvedById: (json['approvedById'] as num?)?.toInt(),
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
      cancelledById: (json['cancelledById'] as num?)?.toInt(),
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      cancellationReason: json['cancellationReason'] as String?,
      localeId: (json['localeId'] as num?)?.toInt(),
      localeName: json['localeName'] as String?,
      localeAddress: json['localeAddress'] as String?,
      localeLogo: json['localeLogo'] as String?,
    );

Map<String, dynamic> _$ReservationToJson(Reservation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'tableId': instance.tableId,
      'tableName': instance.tableName,
      'numberOfGuests': instance.numberOfGuests,
      'reservationDate': instance.reservationDate?.toIso8601String(),
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'createdAt': instance.createdAt?.toIso8601String(),
      'reservationState': instance.reservationState,
      'approvedById': instance.approvedById,
      'approvedAt': instance.approvedAt?.toIso8601String(),
      'cancelledById': instance.cancelledById,
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
      'cancellationReason': instance.cancellationReason,
      'localeId': instance.localeId,
      'localeName': instance.localeName,
      'localeAddress': instance.localeAddress,
      'localeLogo': instance.localeLogo,
    };
