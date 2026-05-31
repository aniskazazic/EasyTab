import 'dart:convert';
import 'package:easytab_desktop/models/review.dart';
import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super("Reviews");

  @override
  Review fromJson(json) => Review.fromJson(json);

  Future<List<Review>> getByLocaleId(int localeId) async {
    var url = "${BaseProvider.baseUrl}/Reviews/by-locale/$localeId";
    var uri = Uri.parse(url);
    var response = await http.get(uri, headers: createHeaders());

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body) as List;
      return data.map((item) => fromJson(item)).toList();
    } else {
      throw Exception('Greška pri učitavanju recenzija za lokal');
    }
  }
}
