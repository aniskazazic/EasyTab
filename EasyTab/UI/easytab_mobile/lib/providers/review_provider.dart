import 'dart:convert';
import 'package:easytab_mobile/models/review.dart';
import 'package:easytab_mobile/models/review_eligibility.dart';
import 'package:easytab_mobile/models/search_result.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ReviewProvider extends BaseProvider<Review> {
  final void Function()? onInteractionChanged;

  ReviewProvider({this.onInteractionChanged}) : super('Reviews');

  @override
  Review fromJson(json) => Review.fromJson(json);

  Future<ReviewEligibility> canReview(int localeId) async {
    final url = '${BaseProvider.baseUrl}/Reviews/can-review?localeId=$localeId';
    final response = await http.get(Uri.parse(url), headers: createHeaders());
    validateResponse(response);
    return ReviewEligibility.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<SearchResult<Review>> getByLocale(
    int localeId, {
    String? sortBy,
    int page = 1,
    int pageSize = 10,
  }) async {
    final filter = <String, dynamic>{
      'LocaleId': localeId,
      'Page': page,
      'PageSize': pageSize,
    };
    if (sortBy != null && sortBy.isNotEmpty) {
      filter['SortBy'] = sortBy;
    }
    return await get(filter: filter);
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
    final review = await insert({
      'localeId': localeId,
      'userId': userId,
      'rating': rating,
      'description': description,
    });
    onInteractionChanged?.call();
    return review;
  }

  Future<Review> editReview({
    required int reviewId,
    required int rating,
    required String description,
  }) async {
    final review = await update(reviewId, {
      'rating': rating,
      'description': description,
    });
    onInteractionChanged?.call();
    return review;
  }

  Future<void> deleteReview(int reviewId) async {
    // Koristi soft-delete endpoint
    final url = '${BaseProvider.baseUrl}/Reviews/soft-delete/$reviewId';
    final response = await http.delete(
      Uri.parse(url),
      headers: createHeaders(),
    );
    if (!isValidResponse(response)) {
      throw Exception('Greška pri brisanju recenzije');
    }
    onInteractionChanged?.call();
  }
}
