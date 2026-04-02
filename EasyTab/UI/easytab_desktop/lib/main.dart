import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:easytab_desktop/providers/category_provider.dart';
import 'package:easytab_desktop/providers/city_provider.dart';
import 'package:easytab_desktop/providers/country_provider.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/providers/owner_provider.dart';
import 'package:easytab_desktop/providers/table_provider.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:easytab_desktop/providers/worker_provider.dart';
import 'package:easytab_desktop/providers/zone_provider.dart';
import 'package:easytab_desktop/screens/admin_add_user_screen.dart';
import 'package:easytab_desktop/screens/admin_categories_list_screen.dart';
import 'package:easytab_desktop/screens/admin_cities_list_screen.dart';
import 'package:easytab_desktop/screens/admin_country_list_screen.dart';
import 'package:easytab_desktop/screens/admin_dashboard_screen.dart';
import 'package:easytab_desktop/screens/admin_settings_screen.dart';
import 'package:easytab_desktop/screens/admin_user_list_details_screen.dart';
import 'package:easytab_desktop/screens/admin_user_list_screen.dart';
import 'package:easytab_desktop/screens/admin_locale_list_screen.dart';
import 'package:easytab_desktop/providers/file_provider.dart';
import 'package:easytab_desktop/screens/owner_dashboard_screen.dart';
import 'package:easytab_desktop/screens/owner_locale_details_screen.dart';
import 'package:easytab_desktop/models/locale.dart' as model;
import 'package:easytab_desktop/screens/owner_settings_screen.dart';
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
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
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
        '/add-user': (context) => const AdminAddUserScreen(),
        '/admin-settings': (context) => const AdminSettingsScreen(),
        '/owner-settings': (context) => const OwnerSettingsScreen(),
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
  bool _obscurePassword = true;
  bool _isHovering = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Širina kartice: 60% od širine, ali max 520px (ugodno za desktop)
    final cardWidth = MediaQuery.of(context).size.width * 0.6;
    const maxCardWidth = 520.0;
    final finalWidth = cardWidth > maxCardWidth ? maxCardWidth : cardWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // meka sivo-plava pozadina
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: finalWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo i naziv (desno ikona)
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "EasyTab",
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E40AF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.table_restaurant,
                          color: Color(0xFF1E40AF),
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                ),

                // Kartica s prijavom (blagi gradijent i sjena)
                Card(
                  elevation: 12,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  color: Colors.white, // bijela kartica - sigurno i čisto
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Prijava",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Unesite svoje podatke za pristup",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Polje: korisničko ime
                        _buildTextField(
                          controller: usernameController,
                          hint: "Korisničko ime",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 28),

                        // Polje: lozinka
                        _buildTextField(
                          controller: passwordController,
                          hint: "Lozinka",
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                              color: Colors.grey[500],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Gumb za prijavu (veći, sa hover efektom)
                        MouseRegion(
                          onEnter: (_) => setState(() => _isHovering = true),
                          onExit: (_) => setState(() => _isHovering = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _isHovering
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF1E40AF,
                                        ).withOpacity(0.35),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E40AF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: isLoading ? null : _handleLogin,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Prijavi se",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                Text(
                  "© ${DateTime.now().year} EasyTab",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Icon(icon, size: 22, color: Colors.grey[600]),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8FAFC), // blago siva za polja
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.8),
        ),
      ),
    );
  }

  // --- LOGIKA OSTAJE POTPUNO ISTA (NIŠTA NIJE DIRANO) ---
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
        } else {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
