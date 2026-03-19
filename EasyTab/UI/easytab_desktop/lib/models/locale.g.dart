// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Locale _$LocaleFromJson(Map<String, dynamic> json) => Locale(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  address: json['address'] as String?,
  startOfWorkingHours: _timeOnlyFromJson(
    json['startOfWorkingHours'] as String?,
  ),
  endOfWorkingHours: _timeOnlyFromJson(json['endOfWorkingHours'] as String?),
  lengthOfReservation: (json['lengthOfReservation'] as num?)?.toDouble(),
  logo: json['logo'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  cityName: json['cityName'] as String?,
  categoryId: (json['categoryId'] as num?)?.toInt(),
  categoryName: json['categoryName'] as String?,
  ownerId: (json['ownerId'] as num?)?.toInt(),
  isDeleted: json['isDeleted'] as bool?,
  countryName: json['countryName'] as String?,
  ownerName: json['ownerName'] as String?,
);

Map<String, dynamic> _$LocaleToJson(Locale instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'startOfWorkingHours': _timeOnlyToJson(instance.startOfWorkingHours),
  'endOfWorkingHours': _timeOnlyToJson(instance.endOfWorkingHours),
  'lengthOfReservation': instance.lengthOfReservation,
  'logo': instance.logo,
  'phoneNumber': instance.phoneNumber,
  'cityId': instance.cityId,
  'cityName': instance.cityName,
  'categoryId': instance.categoryId,
  'categoryName': instance.categoryName,
  'ownerId': instance.ownerId,
  'isDeleted': instance.isDeleted,
  'countryName': instance.countryName,
  'ownerName': instance.ownerName,
};
