import 'package:easytab_mobile/screens/home_screen.dart';
import 'package:flutter/material.dart';

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    _SearchScreen(),
    _FavouritesScreen(),
    _ReservationsScreen(),
    _SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E40AF),
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        16,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'EasyTab',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              // Po želji dodaj fontFamily: 'Pacifico' ili 'cursive'
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.table_restaurant, color: Colors.white, size: 34),
        ],
      ),
    );
  }
}

// Placeholder ekrani (nepromijenjeni)
class _SearchScreen extends StatelessWidget {
  const _SearchScreen();
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderScreen(label: 'Pretraga', icon: Icons.search_outlined);
}

class _FavouritesScreen extends StatelessWidget {
  const _FavouritesScreen();
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderScreen(label: 'Omiljeni', icon: Icons.favorite_outline);
}

class _ReservationsScreen extends StatelessWidget {
  const _ReservationsScreen();
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
    label: 'Rezervacije',
    icon: Icons.calendar_today_outlined,
  );
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
    label: 'Postavke',
    icon: Icons.settings_outlined,
  );
}

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PlaceholderScreen({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              'Uskoro dostupno',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
