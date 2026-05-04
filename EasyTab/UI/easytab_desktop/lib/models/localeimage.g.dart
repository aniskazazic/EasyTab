// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'localeimage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocaleImage _$LocaleImageFromJson(Map<String, dynamic> json) => LocaleImage(
  id: (json['id'] as num?)?.toInt(),
  fileName: json['fileName'] as String?,
  contentType: json['contentType'] as String?,
  base64Content: json['base64Content'] as String?,
  localeId: (json['localeId'] as num?)?.toInt(),
);

Map<String, dynamic> _$LocaleImageToJson(LocaleImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'contentType': instance.contentType,
      'base64Content': instance.base64Content,
      'localeId': instance.localeId,
    };
