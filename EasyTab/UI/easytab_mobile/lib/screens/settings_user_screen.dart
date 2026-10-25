import 'package:easytab_mobile/models/user.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/favourite_provider.dart';
import 'package:easytab_mobile/providers/user_provider.dart';
import 'package:easytab_mobile/screens/change_password_screen.dart';
import 'package:easytab_mobile/screens/login_screen.dart';
import 'package:easytab_mobile/screens/profile_edit_screen.dart';
import 'package:easytab_mobile/screens/user_reviews_screen.dart';
import 'package:easytab_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';

class SettingsUserScreen extends StatefulWidget {
  const SettingsUserScreen({super.key});

  @override
  State<SettingsUserScreen> createState() => _SettingsUserScreenState();
}

class _SettingsUserScreenState extends State<SettingsUserScreen> {
  late UserProvider _userProvider;
  late User user;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    initData();
  }

  Future<void> initData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final id = AuthProvider.currentUserId;
      if (id == null) {
        setState(() {
          errorMessage = 'Prijavite se ponovo za pregled profila.';
          isLoading = false;
        });
        return;
      }
      var result = await _userProvider.getById(id);

      if (!mounted) return;
      setState(() {
        user = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = userError(e);
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
            ? Center(
                child: Column(
                  children: [
                    Text(errorMessage!),
                    TextButton(
                      onPressed: initData,
                      child: const Text('Pokušaj ponovo'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    backgroundImage:
                        ImageUtils.imageProvider(user.profilePicture) ??
                        const AssetImage('assets/images/no-image.png'),
                    radius: 70,
                  ),
                  Text(
                    "${user.firstName} ${user.lastName}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.username ?? 'Korisničko ime nije dostupno',
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
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (!AuthProvider.isWorker)
              ListTile(
                leading: Icon(Icons.reviews),
                title: Text("Moje recenzije"),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserReviewsScreen(),
                    ),
                  );
                },
              ),
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
              title: Text("Promijeni lozinku"),
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
                    title: dialogTitle(ctx, 'Odjava'),
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
                context.read<FavouriteProvider>().clear();
                await context.read<AuthProvider>().logout();
                globalNavigatorKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
