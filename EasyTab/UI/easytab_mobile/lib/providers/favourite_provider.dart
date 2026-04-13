import 'dart:convert';
import 'package:easytab_mobile/models/favourite.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class FavouriteProvider extends BaseProvider<Favourite> {
  FavouriteProvider() : super('Favourites');

  @override
  Favourite fromJson(json) => Favourite.fromJson(json);

  // GET /Favourites/by-user/{userId}
  Future<List<Favourite>> getMyFavourites(int userId) async {
    final url = '${BaseProvider.baseUrl}/Favourites/by-user/$userId';
    debugPrint('Favourites URL: $url');
    final response = await http.get(Uri.parse(url), headers: createHeaders());
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Favourite.fromJson(json)).toList();
    } else {
      throw Exception('Greška pri učitavanju favorita: ${response.statusCode}');
    }
  }

  // POST /Favourites/add?userId=&localeId=
  Future<Favourite> addFavourite(int userId, int localeId) async {
    final url =
        '${BaseProvider.baseUrl}/Favourites/add?userId=$userId&localeId=$localeId';
    final response = await http.post(Uri.parse(url), headers: createHeaders());
    if (response.statusCode == 200) {
      return Favourite.fromJson(jsonDecode(response.body));
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
  }

  // Pomoćna metoda za provjeru da li je favorit (ako ti treba)
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





/*import 'package:easytab_mobile/models/favourite.dart';
import 'package:easytab_mobile/providers/base_provider.dart';

class FavouriteProvider extends BaseProvider<Favourite> {
  FavouriteProvider() : super('Favourites');

  @override
  Favourite fromJson(json) => Favourite.fromJson(json);

  Future<List<Favourite>> getMyFavourites(int userId) async {
    final result = await get(
      filter: {'UserId': userId, 'IsActive': true, 'RetrieveAll': true},
    );
    return result.items ?? [];
  }

  Future<Favourite?> getFavourite(int userId, int localeId) async {
    final result = await get(
      filter: {'UserId': userId, 'LocaleId': localeId, 'RetrieveAll': true},
    );
    final items = result.items ?? [];
    return items.isNotEmpty ? items.first : null;
  }

  Future<Favourite> addFavourite(int userId, int localeId) async {
    return await insert({
      'userId': userId,
      'localeId': localeId,
      'isActive': true,
    });
  }

  Future<Favourite> removeFavourite(int favouriteId) async {
    return await update(favouriteId, {'isActive': false});
  }
}

import 'package:easytab_mobile/models/favourite.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FavouriteProvider extends BaseProvider<Favourite> {
  FavouriteProvider() : super('Favourites');

  @override
  Favourite fromJson(json) => Favourite.fromJson(json);

  Future getMyFavourites(int userId) async {
    var url = '${BaseProvider.baseUrl}/Favourites/by-user/$userId';

    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);
  }

  Future<Favourite?> getFavourite(int userId, int localeId) async {
    var url =
        '${BaseProvider.baseUrl}/Favourites/is-favourited?$userId&l$localeId';

    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);
  }

  Future addFavourite(int userId, int localeId) async {
    var url = '${BaseProvider.baseUrl}/Favourites/add/$userId&$localeId';

    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.post(uri, headers: headers);
  }

  Future<Favourite> removeFavourite(int favouriteId) async {
    return await update(favouriteId, {'isActive': false});
  }
}
*/