import 'dart:convert';
import 'package:easytab_desktop/models/user.dart';
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class UserProvider extends BaseProvider<User> {
  UserProvider() : super("Users");

  @override
  User fromJson(json) {
    return User.fromJson(json);
  }

  Future<User> login(String username, String password) async {
    var url = "$baseUrl/Users/login";
    var uri = Uri.parse(url);

    var response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return User.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception("Pogrešno korisničko ime ili lozinka!");
    } else {
      throw Exception("Greška na serveru: ${response.statusCode}");
    }
  }
}
