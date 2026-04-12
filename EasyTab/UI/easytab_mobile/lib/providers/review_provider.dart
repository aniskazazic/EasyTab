import 'dart:convert';
import 'package:easytab_mobile/models/review.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super('Reviews');

  @override
  Review fromJson(json) => Review.fromJson(json);

  Future<List<Review>> getByLocale(int localeId) async {
    final result = await get(
      filter: {'LocaleId': localeId, 'RetrieveAll': true},
    );
    return result.items ?? [];
  }

  Future<double> getAverage(int localeId) async {
    final url = '${BaseProvider.baseUrl}/Reviews/average/$localeId';
    final response = await http.get(Uri.parse(url), headers: createHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['averageRating'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  Future<Map<String, int>> getRatingCounts(int localeId) async {
    final url = '${BaseProvider.baseUrl}/Reviews/rating-counts/$localeId';
    final response = await http.get(Uri.parse(url), headers: createHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'Odlično': data['excellent'] ?? 0,
        'Dobro': data['good'] ?? 0,
        'Prosječno': data['average'] ?? 0,
        'Loše': data['poor'] ?? 0,
        'Užasno': data['terrible'] ?? 0,
      };
    }
    return {'Odlično': 0, 'Dobro': 0, 'Prosječno': 0, 'Loše': 0, 'Užasno': 0};
  }

  Future<Review> addReview({
    required int localeId,
    required int userId,
    required int rating,
    required String description,
  }) async {
    return await insert({
      'localeId': localeId,
      'userId': userId,
      'rating': rating,
      'description': description,
    });
  }

  Future<Review> editReview({
    required int reviewId,
    required int rating,
    required String description,
  }) async {
    return await update(reviewId, {
      'rating': rating,
      'description': description,
    });
  }

  Future<void> deleteReview(int reviewId) async {
    await delete(reviewId);
  }
}
