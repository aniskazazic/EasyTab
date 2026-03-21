import 'package:json_annotation/json_annotation.dart';
part 'zone.g.dart';

@JsonSerializable()
class Zone {
  final int? id;
  final String? name;
  final int? localeId;
  final double? xCoordinate;
  final double? yCoordinate;
  final double? width;
  final double? height;

  Zone({
    this.id,
    this.name,
    this.localeId,
    this.xCoordinate,
    this.yCoordinate,
    this.width,
    this.height,
  });

  Zone copyWith({
    int? id,
    String? name,
    int? localeId,
    double? xCoordinate,
    double? yCoordinate,
    double? width,
    double? height,
  }) {
    return Zone(
      id: id ?? this.id,
      name: name ?? this.name,
      localeId: localeId ?? this.localeId,
      xCoordinate: xCoordinate ?? this.xCoordinate,
      yCoordinate: yCoordinate ?? this.yCoordinate,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  factory Zone.fromJson(Map<String, dynamic> json) => _$ZoneFromJson(json);
  Map<String, dynamic> toJson() => _$ZoneToJson(this);
}
