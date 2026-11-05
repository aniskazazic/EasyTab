import 'package:easytab_desktop/models/role.dart';
import 'package:easytab_desktop/providers/base_provider.dart';

class RoleProvider extends BaseProvider<Role> {
  RoleProvider() : super('Role');

  static bool isSystemRole(Role role) => const {
    'admin',
    'vlasnik',
    'radnik',
    'korisnik',
  }.contains(role.name?.trim().toLowerCase());

  @override
  Role fromJson(data) => Role.fromJson(data);
}
