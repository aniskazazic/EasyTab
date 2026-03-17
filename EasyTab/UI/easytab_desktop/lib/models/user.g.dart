// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num?)?.toInt(),
  username: json['username'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  email: json['email'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  birthDate: json['birthDate'] == null
      ? null
      : DateTime.parse(json['birthDate'] as String),
  profilePicture: json['profilePicture'] as String?,
  isDeleted: json['isDeleted'] as bool?,
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
  userRoles: (json['userRoles'] as List<dynamic>?)
      ?.map((e) => UserRole.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'birthDate': instance.birthDate?.toIso8601String(),
  'profilePicture': instance.profilePicture,
  'isDeleted': instance.isDeleted,
  'deletedAt': instance.deletedAt?.toIso8601String(),
  'userRoles': instance.userRoles,
};
