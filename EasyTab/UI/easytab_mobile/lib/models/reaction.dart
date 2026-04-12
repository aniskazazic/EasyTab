import 'package:json_annotation/json_annotation.dart';

part 'reaction.g.dart';

@JsonSerializable()
class Reaction {
  final int? id;
  final int? reviewId;
  final int? userId;
  final bool? isLike;

  Reaction({this.id, this.reviewId, this.userId, this.isLike});

  factory Reaction.fromJson(Map<String, dynamic> json) =>
      _$ReactionFromJson(json);
  Map<String, dynamic> toJson() => _$ReactionToJson(this);
}
