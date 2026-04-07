import 'package:json_annotation/json_annotation.dart';
part 'worker.g.dart';

@JsonSerializable()
class Worker {
  final int? id;
  final int? userId;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final DateTime? hireDate;
  final DateTime? endDate;
  final int? localeId;
  final DateTime? birthDate;
  final String? profilePicture;

  Worker({
    this.id,
    this.userId,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.phoneNumber,
    this.hireDate,
    this.endDate,
    this.localeId,
    this.birthDate,
    this.profilePicture,
  });

  factory Worker.fromJson(Map<String, dynamic> json) => _$WorkerFromJson(json);
  Map<String, dynamic> toJson() => _$WorkerToJson(this);
}
