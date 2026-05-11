import 'dart:convert';
import 'package:easytab_desktop/models/user.dart';
import 'package:easytab_desktop/providers/base_provider.dart';

class UserProvider extends BaseProvider<User> {
  UserProvider() : super("Users");

  @override
  User fromJson(json) {
    return User.fromJson(json);
  }

  Future<List<User>> getOwners() async {
    var result = await get(filter: {});
    return result.items
            ?.where(
              (u) => u.userRoles?.any((r) => r.role?.name == 'Owner') ?? false,
            )
            .toList() ??
        [];
  }
}
