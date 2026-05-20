import 'package:json_annotation/json_annotation.dart';

part 'review.g.dart';

@JsonSerializable()
class Review {
  int? id;
  String? description;
  int? rating;
  int? userId;
  String? userFullName;
  int? localeId;
  String? localeName;
  DateTime? dateAdded;
  bool? isDeleted;

  Review({
    this.id,
    this.description,
    this.rating,
    this.userId,
    this.userFullName,
    this.localeId,
    this.localeName,
    this.dateAdded,
    this.isDeleted,
  });

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}
