import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:easytab_desktop/providers/category_provider.dart';
import 'package:easytab_desktop/providers/city_provider.dart';
import 'package:easytab_desktop/providers/country_provider.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/providers/owner_provider.dart';
import 'package:easytab_desktop/providers/table_provider.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:easytab_desktop/providers/zone_provider.dart';
import 'package:easytab_desktop/screens/admin_categories_list_screen.dart';
import 'package:easytab_desktop/screens/admin_cities_list_screen.dart';
import 'package:easytab_desktop/screens/admin_country_list_screen.dart';
import 'package:easytab_desktop/screens/admin_dashboard_screen.dart';
import 'package:easytab_desktop/screens/admin_user_list_details_screen.dart';
import 'package:easytab_desktop/screens/admin_user_list_screen.dart';
import 'package:easytab_desktop/screens/admin_locale_list_screen.dart';
import 'package:easytab_desktop/providers/file_provider.dart';
import 'package:easytab_desktop/screens/admin_locale_list_screen.dart';
import 'package:easytab_desktop/screens/owner_dashboard_screen.dart';
import 'package:easytab_desktop/screens/owner_locale_details_screen.dart';
import 'package:easytab_desktop/models/locale.dart' as model;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CityProvider()),
        ChangeNotifierProvider(create: (_) => CountryProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
        ChangeNotifierProvider(create: (_) => OwnerProvider()),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => ZoneProvider()),
      ],
      child: const MyLoginApp(),
    ),
  );
}

class MyLoginApp extends StatelessWidget {
  const MyLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyTab Desktop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const AdminDashboardScreen(),
        '/locales': (context) => const LocaleListScreen(),
        '/users': (context) => const AdminUsersListScreen(),
        '/user-details': (context) => const AdminUserDetailsScreen(),
        '/countries': (context) => const AdminCountriesListScreen(),
        '/cities': (context) => const AdminCitiesListScreen(),
        '/categories': (context) => const AdminCategoriesListScreen(),
        '/owner-dashboard': (context) => const OwnerDashboardScreen(),
        '/owner-add-locale': (context) => const OwnerLocaleDetailsScreen(),
        //'/owner-settings'
        '/owner-locale-settings': (context) {
          final locale =
              ModalRoute.of(context)!.settings.arguments as model.Locale?;
          return OwnerLocaleDetailsScreen(locale: locale);
        },
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'EasyTab',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      _showError("Unesite korisničko ime i lozinku!");
      return;
    }

    setState(() => isLoading = true);

    try {
      var userProvider = context.read<UserProvider>();

      var user = await userProvider.authenticate(
        usernameController.text,
        passwordController.text,
      );

      AuthProvider.username = usernameController.text;
      AuthProvider.password = passwordController.text;
      AuthProvider.currentUser = user;

      if (!AuthProvider.isAdmin && !AuthProvider.isOwner) {
        AuthProvider.clear();
        _showError("Nemate dozvolu za pristup ovoj aplikaciji!");
        return;
      }

      if (mounted) {
        if (AuthProvider.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
            ),
          );
        } else if (AuthProvider.isOwner) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const OwnerDashboardScreen(),
            ),
          );
        }
      }
    } catch (e) {
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Greška'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
