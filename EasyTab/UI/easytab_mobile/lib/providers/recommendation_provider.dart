import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:easytab_mobile/models/recommended_locale.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class RecommendationProvider extends BaseProvider<RecommendedLocale> {
  static const _requestTimeout = Duration(seconds: 10);
  final http.Client _client;
  List<RecommendedLocale> _items = const [];
  int? _userId;
  int _requestVersion = 0;

  RecommendationProvider({http.Client? client})
    : _client = client ?? http.Client(),
      super('Locale/recommended');

  static bool get isAvailable =>
      AuthProvider.isCustomer && !AuthProvider.isWorker;

  List<RecommendedLocale> get items =>
      isAvailable && _userId == AuthProvider.currentUserId ? _items : const [];

  @override
  RecommendedLocale fromJson(Object? data) =>
      RecommendedLocale.fromJson(data as Map<String, Object?>);

  void invalidate() => unawaited(refresh());

  Future<void> refresh() async {
    final version = ++_requestVersion;
    final userId = AuthProvider.currentUserId;
    if (!isAvailable || userId == null) return;

    List<RecommendedLocale> result;
    try {
      final response = await _client
          .get(
            Uri.parse('${BaseProvider.baseUrl}/$endpoint'),
            headers: createHeaders(),
          )
          .timeout(_requestTimeout);
      validateResponse(response);
      final Object? data = jsonDecode(response.body);
      if (data is! List<Object?>) {
        throw const FormatException('Neispravan odgovor preporuka.');
      }
      result = List.unmodifiable(data.map(fromJson));
    } catch (error, stackTrace) {
      developer.log(
        'Preporuke trenutno nisu dostupne.',
        name: 'RecommendationProvider',
        error: error,
        stackTrace: stackTrace,
      );
      result = const [];
    }

    if (version != _requestVersion ||
        userId != AuthProvider.currentUserId ||
        !isAvailable) {
      return;
    }
    _userId = userId;
    _items = result;
    notifyListeners();
  }

  @override
  void dispose() {
    ++_requestVersion;
    _client.close();
    super.dispose();
  }
}
