import 'package:easytab_mobile/models/user.dart';

class AuthProvider {
  static String? username;
  static String? password;
  static User? currentUser;

  static bool get isAdmin =>
      currentUser?.userRoles?.any((r) => r.role?.name == 'Admin') ?? false;

  static bool get isOwner =>
      currentUser?.userRoles?.any((r) => r.role?.name == 'Vlasnik') ?? false;

  static void clear() {
    username = null;
    password = null;
    currentUser = null;
  }
}
