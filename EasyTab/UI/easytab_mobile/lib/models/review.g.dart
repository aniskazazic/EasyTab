// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
  id: (json['id'] as num?)?.toInt(),
  description: json['description'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  userId: (json['userId'] as num?)?.toInt(),
  userFullName: json['userFullName'] as String?,
  localeId: (json['localeId'] as num?)?.toInt(),
  localeName: json['localeName'] as String?,
  dateAdded: json['dateAdded'] == null
      ? null
      : DateTime.parse(json['dateAdded'] as String),
  isDeleted: json['isDeleted'] as bool?,
  likes: (json['likes'] as num?)?.toInt(),
  dislikes: (json['dislikes'] as num?)?.toInt(),
  userReaction: (json['userReaction'] as num?)?.toInt(),
);

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'id': instance.id,
  'description': instance.description,
  'rating': instance.rating,
  'userId': instance.userId,
  'userFullName': instance.userFullName,
  'localeId': instance.localeId,
  'localeName': instance.localeName,
  'dateAdded': instance.dateAdded?.toIso8601String(),
  'isDeleted': instance.isDeleted,
  'likes': instance.likes,
  'dislikes': instance.dislikes,
  'userReaction': instance.userReaction,
};
