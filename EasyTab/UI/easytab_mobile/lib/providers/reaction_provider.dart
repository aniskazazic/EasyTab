import 'package:easytab_mobile/models/reaction.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ReactionProvider extends BaseProvider<Reaction> {
  ReactionProvider() : super('Reactions');

  final Map<int, int> _userReactionByReviewId = {};
  int? _loadedUserId;

  @override
  Reaction fromJson(json) => Reaction.fromJson(json);

  int? userReactionFor(int reviewId) => _userReactionByReviewId[reviewId];

  void updateUserReaction(int reviewId, int reaction) {
    if (reaction == 0) {
      _userReactionByReviewId.remove(reviewId);
    } else {
      _userReactionByReviewId[reviewId] = reaction;
    }
    notifyListeners();
  }

  void clearUserReactions() {
    _userReactionByReviewId.clear();
    _loadedUserId = null;
  }

  Future<void> loadUserReactions(int userId) async {
    final result = await get(filter: {
      'UserId': userId,
      'Page': 1,
      'PageSize': 1000,
    });

    _userReactionByReviewId.clear();
    for (final reaction in result.items ?? <Reaction>[]) {
      if (reaction.reviewId != null) {
        _userReactionByReviewId[reaction.reviewId!] =
            reaction.isLike == true ? 1 : -1;
      }
    }
    _loadedUserId = userId;
    notifyListeners();
  }

  Future<void> ensureUserReactionsLoaded(int userId) async {
    if (_loadedUserId == userId) return;
    await loadUserReactions(userId);
  }

  Future<void> react({
    required int reviewId,
    required int userId,
    required bool isLike,
  }) async {
    await insert({'reviewId': reviewId, 'userId': userId, 'isLike': isLike});
  }

  /// Backend očekuje DELETE /Reactions?reviewId=X&userId=Y
  Future<void> removeReaction(int reviewId, int userId) async {
    final url =
        '${BaseProvider.baseUrl}/Reactions?reviewId=$reviewId&userId=$userId';
    final response = await http.delete(Uri.parse(url), headers: createHeaders());
    if (!isValidResponse(response)) {
      throw Exception('Greška pri uklanjanju reakcije');
    }
  }
}
