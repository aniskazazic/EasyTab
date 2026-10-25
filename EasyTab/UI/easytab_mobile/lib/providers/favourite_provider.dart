import 'dart:convert';
import 'package:easytab_mobile/models/favourite.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class FavouriteProvider extends BaseProvider<Favourite> {
  final void Function()? onInteractionChanged;

  FavouriteProvider({this.onInteractionChanged}) : super('Favourites');

  @override
  Favourite fromJson(json) => Favourite.fromJson(json);

  List<Favourite> myFavourites = [];
  final Set<int> favouriteLocaleIds = {};

  void clear() {
    favouriteLocaleIds.clear();
    notifyListeners();
  }

  void setFavouriteStatus(int localeId, bool isFavourite) {
    final changed = isFavourite
        ? favouriteLocaleIds.add(localeId)
        : favouriteLocaleIds.remove(localeId);
    if (changed) notifyListeners();
  }

  // GET /Favourites/by-user
  Future<List<Favourite>> getMyFavourites() async {
    final url = '${BaseProvider.baseUrl}/Favourites/by-user/';
    debugPrint('Favourites URL: $url');
    final response = await http.get(Uri.parse(url), headers: createHeaders());
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      myFavourites = data.map((json) => Favourite.fromJson(json)).toList();
      favouriteLocaleIds
        ..clear()
        ..addAll(
          myFavourites.map((favourite) => favourite.localeId).whereType<int>(),
        );
      notifyListeners();
      return myFavourites;
    } else {
      throw Exception('Greška pri učitavanju favorita: ${response.statusCode}');
    }
  }

  // POST /Favourites/add?localeId=
  Future<Favourite> addFavourite(int localeId) async {
    final url = '${BaseProvider.baseUrl}/Favourites/add?localeId=$localeId';
    final response = await http.post(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode({}),
    );
    if (response.statusCode == 200) {
      final fav = Favourite.fromJson(jsonDecode(response.body));
      myFavourites.add(fav);
      favouriteLocaleIds.add(localeId);
      notifyListeners();
      onInteractionChanged?.call();
      return fav;
    }
    throw Exception('Greška pri dodavanju favorita');
  }

  // DELETE /Favourites/remove?localeId=
  Future<void> removeFavourite(int localeId) async {
    final url = '${BaseProvider.baseUrl}/Favourites/remove?localeId=$localeId';
    final response = await http.delete(
      Uri.parse(url),
      headers: createHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Greška pri uklanjanju favorita');
    }

    myFavourites.removeWhere((f) => f.localeId == localeId);
    favouriteLocaleIds.remove(localeId);
    notifyListeners();
    onInteractionChanged?.call();
  }

  // Pomoćna metoda za provjeru da li je favorit
  Future<bool> isFavourited(int localeId) async {
    final url =
        '${BaseProvider.baseUrl}/Favourites/is-favourited?localeId=$localeId';
    final response = await http.get(Uri.parse(url), headers: createHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as bool;
    }
    return false;
  }
}
