import 'package:json_annotation/json_annotation.dart';
part 'table.g.dart';

@JsonSerializable()
class Tables {
  final int? id;
  final String? name;
  final int? localeId;
  final double? xCoordinate;
  final double? yCoordinate;
  final int? numberOfGuests;

  Tables({
    this.id,
    this.name,
    this.localeId,
    this.xCoordinate,
    this.yCoordinate,
    this.numberOfGuests,
  });

  Tables copyWith({
    int? id,
    String? name,
    int? localeId,
    double? xCoordinate,
    double? yCoordinate,
    int? numberOfGuests,
  }) {
    return Tables(
      id: id ?? this.id,
      name: name ?? this.name,
      localeId: localeId ?? this.localeId,
      xCoordinate: xCoordinate ?? this.xCoordinate,
      yCoordinate: yCoordinate ?? this.yCoordinate,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
    );
  }

  factory Tables.fromJson(Map<String, dynamic> json) => _$TablesFromJson(json);
  Map<String, dynamic> toJson() => _$TablesToJson(this);
}
