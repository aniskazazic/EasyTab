import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/notification_provider.dart';
import 'package:easytab_mobile/providers/reservation_provider.dart';
import 'package:easytab_mobile/screens/favourite_screen.dart';
import 'package:easytab_mobile/screens/home_screen.dart';
import 'package:easytab_mobile/screens/notifications_screen.dart';
import 'package:easytab_mobile/screens/search_locales_screen.dart';
import 'package:easytab_mobile/screens/settings_user_screen.dart';
import 'package:easytab_mobile/screens/user_reservations_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = AuthProvider.currentUserId;
      if (userId != null) {
        context.read<NotificationProvider>().getNotifications(userId);
      }
    });
  }

  // Lista navigator ključeva – po jedan za svaku karticu
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // Metoda koja vraća trenutni navigator za odabrani indeks
  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: _currentIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => _getScreenForIndex(index),
          );
        },
      ),
    );
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const SearchLocalesScreen();
      case 2:
        return const FavouritesScreen();
      case 3:
        return const UserReservationsScreen();
      case 4:
        return const SettingsUserScreen();
      default:
        return const HomeScreen();
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 3) {
      final userId = AuthProvider.currentUserId;
      if (userId != null) {
        context.read<ReservationProvider>().loadAll(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Stack(
              children: List.generate(_navigatorKeys.length, (index) {
                return _buildOffstageNavigator(index);
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E40AF), // ista boja
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 12,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Početna',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Pretraga',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Omiljeni',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Rezervacije',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Postavke',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Container(
      width: double.infinity,
      color: const Color(0xFF1E40AF),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centrirani naziv i logo
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'EasyTab',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.table_restaurant, color: Colors.white, size: 30),
            ],
          ),
          // Zvončić sa desne strane sa brojačem nepročitanih
          Positioned(
            right: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
