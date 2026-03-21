// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tables _$TablesFromJson(Map<String, dynamic> json) => Tables(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  localeId: (json['localeId'] as num?)?.toInt(),
  xCoordinate: (json['xCoordinate'] as num?)?.toDouble(),
  yCoordinate: (json['yCoordinate'] as num?)?.toDouble(),
  numberOfGuests: (json['numberOfGuests'] as num?)?.toInt(),
);

Map<String, dynamic> _$TablesToJson(Tables instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'localeId': instance.localeId,
  'xCoordinate': instance.xCoordinate,
  'yCoordinate': instance.yCoordinate,
  'numberOfGuests': instance.numberOfGuests,
};
