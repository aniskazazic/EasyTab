import 'package:easytab_mobile/models/user.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/user_provider.dart';
import 'package:easytab_mobile/screens/change_password_screeen.dart';
import 'package:easytab_mobile/screens/profile_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/providers/utils.dart';

class SettingsUserScreen extends StatefulWidget {
  const SettingsUserScreen({super.key});

  @override
  State<SettingsUserScreen> createState() => _SettingsUserScreenState();
}

class _SettingsUserScreenState extends State<SettingsUserScreen> {
  late UserProvider _userProvider;
  late AuthProvider _authProvider;
  late User user;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    _authProvider = context.read<AuthProvider>();
    initData();
  }

  Future<void> initData() async {
    try {
      print(
        "AuthProvider.accessTokenDecoded: ${AuthProvider.accessTokenDecoded}",
      );
      var id = AuthProvider.accessTokenDecoded?['Id'];
      print("User ID: $id");
      if (id == null) {
        throw Exception("User ID not found in token");
      }
      var result = await _userProvider.getById(int.parse(id));

      setState(() {
        user = result;
        isLoading = false;
      });
      print("user: ${user.firstName}, ${user.lastName}, ${user.email}");
    } catch (e) {
      print("Error loading user: $e");
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(child: Text("Greška: $errorMessage"))
            : Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    backgroundImage: user.profilePicture != null
                        ? imageFromBase64WithouthDimensions(
                            user.profilePicture!,
                          )
                        : const AssetImage('assets/images/no-image.png'),
                    radius: 70,
                  ),
                  Text(
                    "${user.firstName} ${user.lastName}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.username ?? "No username",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  _buildProfileMenu(),
                ],
              ),
      ),
    );
  }

  Padding _buildProfileMenu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
      child: Card(
        elevation: 10,
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: Icon(Icons.pending),
              title: Text("Uredi profil"),
              onTap: () async {
                var refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileEditScreen(user: user),
                  ),
                );
                if (refresh == 'reload') {
                  initData();
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text("Promjeni lozinku"),
              onTap: () async {
                var refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordScreen(user: user),
                  ),
                );
                if (refresh == 'reload') {
                  initData();
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Odjava"),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () async {
                final leave = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text("Odjava"),
                    content: Text(
                      "Da li ste sigurni da zelite da se odjavite?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text("Odustani"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text("Odjavi se"),
                        style: ButtonStyle(
                          foregroundColor: MaterialStatePropertyAll(Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (leave != true || !mounted) return;
                context.read<AuthProvider>().logout();
                if (!mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
