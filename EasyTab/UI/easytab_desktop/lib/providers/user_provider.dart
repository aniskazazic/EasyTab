import 'dart:convert';
import 'package:easytab_desktop/models/user.dart';
import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class UserProvider extends BaseProvider<User> {
  UserProvider() : super("Users");

  @override
  User fromJson(json) {
    return User.fromJson(json);
  }

  Future<void> changePassword(Map<String, dynamic> request) async {
    var url = "${BaseProvider.baseUrl}/Users/ChangePassword";
    var uri = Uri.parse(url);
    var response = await sendRequestWithRetry(
      () => http.put(uri, headers: createHeaders(), body: jsonEncode(request)),
    );

    validateResponse(response);
  }
}
