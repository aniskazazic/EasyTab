import 'package:json_annotation/json_annotation.dart';

part 'review.g.dart';

@JsonSerializable()
class Review {
  final int? id;
  final String? description;
  final double? rating;
  final int? userId;
  final String? userFullName;
  final int? localeId;
  final String? localeName;
  final DateTime? dateAdded;
  final bool? isDeleted;
  final int? likes;
  final int? dislikes;
  final int? userReaction; // 1 = like, -1 = dislike, 0 = none

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
    this.likes,
    this.dislikes,
    this.userReaction,
  });

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}
