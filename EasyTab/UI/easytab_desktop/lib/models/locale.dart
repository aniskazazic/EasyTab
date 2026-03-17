import 'package:json_annotation/json_annotation.dart';

part 'locale.g.dart';

@JsonSerializable()
class Locale {
  int? id;
  String? name;
  String? address;
  @JsonKey(fromJson: _timeOnlyFromJson, toJson: _timeOnlyToJson)
  DateTime? startOfWorkingHours;
  @JsonKey(fromJson: _timeOnlyFromJson, toJson: _timeOnlyToJson)
  DateTime? endOfWorkingHours;
  int? lengthOfReservation;
  String? logo;
  String? phoneNumber;
  int? cityId;
  String? cityName;
  int? categoryId;
  String? categoryName;
  int? ownerId;
  bool? isDeleted;
  String? countryName;
  String? ownerName;

  Locale({
    this.id,
    this.name,
    this.address,
    this.startOfWorkingHours,
    this.endOfWorkingHours,
    this.lengthOfReservation,
    this.logo,
    this.phoneNumber,
    this.cityId,
    this.cityName,
    this.categoryId,
    this.categoryName,
    this.ownerId,
    this.isDeleted,
    this.countryName,
    this.ownerName,
  });

  factory Locale.fromJson(Map<String, dynamic> json) => _$LocaleFromJson(json);
}

// Helper functions to handle C# TimeOnly ("HH:mm:ss") values.
DateTime? _timeOnlyFromJson(String? value) {
  if (value == null || value.isEmpty) return null;
  // Expect format "HH:mm:ss"
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute, second);
}

String? _timeOnlyToJson(DateTime? value) {
  if (value == null) return null;
  final twoDigits = (int n) => n.toString().padLeft(2, '0');
  final h = twoDigits(value.hour);
  final m = twoDigits(value.minute);
  final s = twoDigits(value.second);
  return '$h:$m:$s';
}
