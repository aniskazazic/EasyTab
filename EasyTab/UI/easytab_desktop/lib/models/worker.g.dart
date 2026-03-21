// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Worker _$WorkerFromJson(Map<String, dynamic> json) => Worker(
  id: (json['id'] as num?)?.toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  username: json['username'] as String?,
  email: json['email'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  hireDate: json['hireDate'] == null
      ? null
      : DateTime.parse(json['hireDate'] as String),
  endDate: json['endDate'] == null
      ? null
      : DateTime.parse(json['endDate'] as String),
  localeId: (json['localeId'] as num?)?.toInt(),
  birthDate: json['birthDate'] == null
      ? null
      : DateTime.parse(json['birthDate'] as String),
  profilePicture: json['profilePicture'] as String?,
);

Map<String, dynamic> _$WorkerToJson(Worker instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'username': instance.username,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'hireDate': instance.hireDate?.toIso8601String(),
  'endDate': instance.endDate?.toIso8601String(),
  'localeId': instance.localeId,
  'birthDate': instance.birthDate?.toIso8601String(),
  'profilePicture': instance.profilePicture,
};
