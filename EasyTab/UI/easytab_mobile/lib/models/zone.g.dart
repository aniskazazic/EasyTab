// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Zone _$ZoneFromJson(Map<String, dynamic> json) => Zone(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  localeId: (json['localeId'] as num?)?.toInt(),
  xCoordinate: (json['xCoordinate'] as num?)?.toDouble(),
  yCoordinate: (json['yCoordinate'] as num?)?.toDouble(),
  width: (json['width'] as num?)?.toDouble(),
  height: (json['height'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ZoneToJson(Zone instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'localeId': instance.localeId,
  'xCoordinate': instance.xCoordinate,
  'yCoordinate': instance.yCoordinate,
  'width': instance.width,
  'height': instance.height,
};
