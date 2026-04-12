import 'dart:convert';
import 'package:easytab_mobile/models/reaction.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ReactionProvider extends BaseProvider<Reaction> {
  ReactionProvider() : super('Reactions');

  @override
  Reaction fromJson(json) => Reaction.fromJson(json);

  Future<void> react({
    required int reviewId,
    required int userId,
    required bool isLike,
  }) async {
    await insert({'reviewId': reviewId, 'userId': userId, 'isLike': isLike});
  }

  Future<void> removeReaction(int reactionId) async {
    await delete(reactionId);
  }
}
