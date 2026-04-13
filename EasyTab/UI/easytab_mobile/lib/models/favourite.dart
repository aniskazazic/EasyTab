import 'package:json_annotation/json_annotation.dart';

part 'favourite.g.dart';

@JsonSerializable()
class Favourite {
  final int? id;
  final int? localeId;
  final int? userId;
  final DateTime? dateAdded;
  final bool? isActive;
  final String? localeName;
  final String? localeLogo;
  final String? localeCategoryName;
  final String? localeCityName;
  final String? localeAddress;

  Favourite({
    this.id,
    this.localeId,
    this.userId,
    this.dateAdded,
    this.isActive,
    this.localeName,
    this.localeLogo,
    this.localeCategoryName,
    this.localeCityName,
    this.localeAddress,
  });

  factory Favourite.fromJson(Map<String, dynamic> json) =>
      _$FavouriteFromJson(json);

  Map<String, dynamic> toJson() => _$FavouriteToJson(this);
}
