import 'package:json_annotation/json_annotation.dart';

part 'role.g.dart';

@JsonSerializable()
class Role {
  int? id;
  String? name;
  String? description;
  bool? isDeleted;
  DateTime? deletedAt;

  Role({this.id, this.name, this.description, this.isDeleted, this.deletedAt});

  factory Role.fromJson(Map<String, dynamic> json) => _$RoleFromJson(json);
  Map<String, dynamic> toJson() => _$RoleToJson(this);
}
