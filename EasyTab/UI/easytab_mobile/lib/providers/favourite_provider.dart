import 'dart:convert';
import 'package:easytab_mobile/models/favourite.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class FavouriteProvider extends BaseProvider<Favourite> {
  FavouriteProvider() : super('Favourites');

  @override
  Favourite fromJson(json) => Favourite.fromJson(json);

  List<Favourite> myFavourites = [];

  // GET /Favourites/by-user/{userId}
  Future<List<Favourite>> getMyFavourites(int userId) async {
    final url = '${BaseProvider.baseUrl}/Favourites/by-user/$userId';
    debugPrint('Favourites URL: $url');
    final response = await http.get(Uri.parse(url), headers: createHeaders());
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      myFavourites = data.map((json) => Favourite.fromJson(json)).toList();
      notifyListeners();
      return myFavourites;
    } else {
      throw Exception('Greška pri učitavanju favorita: ${response.statusCode}');
    }
  }

  // POST /Favourites/add?userId=&localeId=
  Future<Favourite> addFavourite(int userId, int localeId) async {
    final url =
        '${BaseProvider.baseUrl}/Favourites/add?userId=$userId&localeId=$localeId';
    final response = await http.post(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode({}),
    );
    if (response.statusCode == 200) {
      final fav = Favourite.fromJson(jsonDecode(response.body));
      myFavourites.add(fav);
      notifyListeners();
      return fav;
    }
    throw Exception('Greška pri dodavanju favorita');
  }

  // DELETE /Favourites/remove?userId=&localeId=
  Future<void> removeFavourite(int userId, int localeId) async {
    final url =
        '${BaseProvider.baseUrl}/Favourites/remove?userId=$userId&localeId=$localeId';
    final response = await http.delete(
      Uri.parse(url),
      headers: createHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Greška pri uklanjanju favorita');
    }
    
    myFavourites.removeWhere((f) => f.localeId == localeId && f.userId == userId);
    notifyListeners();
  }

  // Pomoćna metoda za provjeru da li je favorit
  Future<bool> isFavourited(int userId, int localeId) async {
    final url =
        '${BaseProvider.baseUrl}/Favourites/is-favourited?userId=$userId&localeId=$localeId';
    final response = await http.get(Uri.parse(url), headers: createHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as bool;
    }
    return false;
  }
}
