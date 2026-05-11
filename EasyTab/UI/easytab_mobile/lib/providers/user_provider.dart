import 'dart:convert';
import 'package:easytab_mobile/models/user.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class UserProvider extends BaseProvider<User> {
  UserProvider() : super("Users");

  @override
  User fromJson(json) {
    return User.fromJson(json);
  }

  Future<dynamic> changePassword(dynamic data) async {
    var url = "${BaseProvider.baseUrl}/${BaseProvider.endpoint}/ChangePassword";

    var uri = Uri.parse(url);
    var jsonRequest = jsonEncode(data);
    var headers = createHeaders();

    http.Response response = await http.put(
      uri,
      headers: headers,
      body: jsonRequest,
    );

    if (isValidResponse(response)) {
    } else {
      throw Exception("Neuspješna promjena passworda");
    }
  }

  Future<List<User>> getOwners() async {
    var result = await get(filter: {});
    return result.items
            ?.where(
              (u) =>
                  u.userRoles?.any((r) => r.role?.name == 'Vlasnik') ?? false,
            )
            .toList() ??
        [];
  }
}
