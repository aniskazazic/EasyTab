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

  Future<void> changePassword(Map<String, dynamic> data) async {
    var url = "${BaseProvider.baseUrl}/$endpoint/ChangePassword";

    var uri = Uri.parse(url);
    var jsonRequest = jsonEncode(data);
    final response = await sendRequestWithRetry(
      () => http.put(uri, headers: createHeaders(), body: jsonRequest),
    );
    validateResponse(response);
  }
}
