// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reaction _$ReactionFromJson(Map<String, dynamic> json) => Reaction(
  id: (json['id'] as num?)?.toInt(),
  reviewId: (json['reviewId'] as num?)?.toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  isLike: json['isLike'] as bool?,
);

Map<String, dynamic> _$ReactionToJson(Reaction instance) => <String, dynamic>{
  'id': instance.id,
  'reviewId': instance.reviewId,
  'userId': instance.userId,
  'isLike': instance.isLike,
};
