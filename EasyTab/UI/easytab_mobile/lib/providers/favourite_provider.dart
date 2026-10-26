import 'dart:convert';
import 'package:easytab_mobile/models/favourite.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class FavouriteProvider extends BaseProvider<Favourite> {
  final void Function()? onInteractionChanged;
  FavouriteProvider({this.onInteractionChanged}) : super('Favourites');
  @override
  Favourite fromJson(json) => Favourite.fromJson(json);
  List<Favourite> myFavourites = [];
  final Set<int> favouriteLocaleIds = {};

  void clear() {
    myFavourites.clear();
    favouriteLocaleIds.clear();
    notifyListeners();
  }

  void setFavouriteStatus(int localeId, bool isFavourite) {
    final changed = isFavourite
        ? favouriteLocaleIds.add(localeId)
        : favouriteLocaleIds.remove(localeId);
    if (changed) notifyListeners();
  }

  Future<List<Favourite>> getMyFavourites() async {
    final uri = Uri.parse('${BaseProvider.baseUrl}/Favourites/by-user/');
    final response = await sendRequestWithRetry(
      () => http.get(uri, headers: createHeaders()),
    );
    validateResponse(response);
    final data = jsonDecode(response.body) as List;
    myFavourites = data.map((json) => Favourite.fromJson(json)).toList();
    favouriteLocaleIds
      ..clear()
      ..addAll(myFavourites.map((f) => f.localeId).whereType<int>());
    notifyListeners();
    return myFavourites;
  }

  Future<Favourite> addFavourite(int localeId) async {
    final uri = Uri.parse(
      '${BaseProvider.baseUrl}/Favourites/add?localeId=$localeId',
    );
    final response = await sendRequestWithRetry(
      () => http.post(uri, headers: createHeaders(), body: jsonEncode({})),
    );
    validateResponse(response);
    final favourite = Favourite.fromJson(jsonDecode(response.body));
    myFavourites.removeWhere((f) => f.localeId == localeId);
    myFavourites.add(favourite);
    favouriteLocaleIds.add(localeId);
    notifyListeners();
    onInteractionChanged?.call();
    return favourite;
  }

  Future<void> removeFavourite(int localeId) async {
    final uri = Uri.parse(
      '${BaseProvider.baseUrl}/Favourites/remove?localeId=$localeId',
    );
    final response = await sendRequestWithRetry(
      () => http.delete(uri, headers: createHeaders()),
    );
    validateResponse(response);
    myFavourites.removeWhere((f) => f.localeId == localeId);
    favouriteLocaleIds.remove(localeId);
    notifyListeners();
    onInteractionChanged?.call();
  }

  Future<bool> isFavourited(int localeId) async {
    final uri = Uri.parse(
      '${BaseProvider.baseUrl}/Favourites/is-favourited?localeId=$localeId',
    );
    final response = await sendRequestWithRetry(
      () => http.get(uri, headers: createHeaders()),
    );
    validateResponse(response);
    return jsonDecode(response.body) as bool;
  }
}
