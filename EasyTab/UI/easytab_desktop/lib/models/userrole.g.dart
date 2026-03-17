// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'userrole.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRole _$UserRoleFromJson(Map<String, dynamic> json) => UserRole(
  id: (json['id'] as num?)?.toInt(),
  roleId: (json['roleId'] as num?)?.toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  role: json['role'] == null
      ? null
      : Role.fromJson(json['role'] as Map<String, dynamic>),
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
  isDeleted: json['isDeleted'] as bool?,
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
);

Map<String, dynamic> _$UserRoleToJson(UserRole instance) => <String, dynamic>{
  'id': instance.id,
  'roleId': instance.roleId,
  'userId': instance.userId,
  'role': instance.role,
  'user': instance.user,
  'isDeleted': instance.isDeleted,
  'deletedAt': instance.deletedAt?.toIso8601String(),
};
