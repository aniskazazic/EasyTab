import 'package:json_annotation/json_annotation.dart';

part 'locale.g.dart';

@JsonSerializable()
class Locale {
  final int? id;
  final String? name;
  final String? address;
  @JsonKey(fromJson: _timeOnlyFromJson, toJson: _timeOnlyToJson)
  final DateTime? startOfWorkingHours;
  @JsonKey(fromJson: _timeOnlyFromJson, toJson: _timeOnlyToJson)
  final DateTime? endOfWorkingHours;
  final int? lengthOfReservation;
  final String? logo;
  final String? phoneNumber;
  final int? cityId;
  final String? cityName;
  final int? categoryId;
  final String? categoryName;
  final int? ownerId;
  final bool? isDeleted;

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
