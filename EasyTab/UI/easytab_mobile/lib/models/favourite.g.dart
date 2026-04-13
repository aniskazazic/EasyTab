// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favourite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Favourite _$FavouriteFromJson(Map<String, dynamic> json) => Favourite(
  id: (json['id'] as num?)?.toInt(),
  localeId: (json['localeId'] as num?)?.toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  dateAdded: json['dateAdded'] == null
      ? null
      : DateTime.parse(json['dateAdded'] as String),
  isActive: json['isActive'] as bool?,
  localeName: json['localeName'] as String?,
  localeLogo: json['localeLogo'] as String?,
  localeCategoryName: json['localeCategoryName'] as String?,
  localeCityName: json['localeCityName'] as String?,
  localeAddress: json['localeAddress'] as String?,
);

Map<String, dynamic> _$FavouriteToJson(Favourite instance) => <String, dynamic>{
  'id': instance.id,
  'localeId': instance.localeId,
  'userId': instance.userId,
  'dateAdded': instance.dateAdded?.toIso8601String(),
  'isActive': instance.isActive,
  'localeName': instance.localeName,
  'localeLogo': instance.localeLogo,
  'localeCategoryName': instance.localeCategoryName,
  'localeCityName': instance.localeCityName,
  'localeAddress': instance.localeAddress,
};
