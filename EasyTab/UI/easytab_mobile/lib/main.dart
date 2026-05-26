import 'package:easytab_mobile/layout/master_screen.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/favourite_provider.dart';
import 'package:easytab_mobile/providers/locale_provider.dart';
import 'package:easytab_mobile/providers/localeimage_provider.dart';
import 'package:easytab_mobile/providers/reaction_provider.dart';
import 'package:easytab_mobile/providers/review_provider.dart';
import 'package:easytab_mobile/providers/user_provider.dart';
import 'package:easytab_mobile/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => LocaleImageProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => ReactionProvider()),
        ChangeNotifierProvider(create: (_) => FavouriteProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyTab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
      ),
      // Use Consumer to dynamically respond to auth state changes
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return AuthProvider.isAuthenticated
              ? const MasterScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
