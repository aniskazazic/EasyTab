import 'package:easytab_mobile/models/role.dart';
import 'package:easytab_mobile/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'userrole.g.dart';

@JsonSerializable()
class UserRole {
  int? id;
  int? roleId;
  int? userId;
  Role? role;
  User? user;
  bool? isDeleted;
  DateTime? deletedAt;

  UserRole({
    this.id,
    this.roleId,
    this.userId,
    this.role,
    this.user,
    this.isDeleted,
    this.deletedAt,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) =>
      _$UserRoleFromJson(json);
  Map<String, dynamic> toJson() => _$UserRoleToJson(this);
}
