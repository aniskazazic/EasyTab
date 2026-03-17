import 'package:easytab_desktop/models/userrole.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  int? id;
  String? username;
  String? firstName;
  String? lastName;
  String? email;
  String? phoneNumber;
  DateTime? birthDate;
  String? profilePicture;
  bool? isDeleted;
  DateTime? deletedAt;
  List<UserRole>? userRoles;

  User({
    this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.birthDate,
    this.profilePicture,
    this.isDeleted,
    this.deletedAt,
    this.userRoles,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
