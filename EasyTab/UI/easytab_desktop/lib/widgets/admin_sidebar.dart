import 'package:flutter/material.dart';
import 'package:easytab_desktop/providers/auth_provider.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF1E40AF),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  'EasyTab',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Zdravo, ${AuthProvider.currentUser?.firstName ?? "Admin"}',
                  style: TextStyle(fontSize: 12, color: Colors.blue[100]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _item(
                  context: context,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/dashboard'),
                ),
                _item(
                  context: context,
                  icon: Icons.person,
                  label: 'Korisnici',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/users'),
                ),
                _item(
                  context: context,
                  icon: Icons.home,
                  label: 'Lokali',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/locales'),
                ),
                _item(
                  context: context,
                  icon: Icons.calendar_today,
                  label: 'Rezervacije',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/reservations'),
                ),
                _item(
                  context: context,
                  icon: Icons.star,
                  label: 'Recenzije',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/reviews'),
                ),
                _item(
                  context: context,
                  icon: Icons.public,
                  label: 'Države',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/countries'),
                ),
                _item(
                  context: context,
                  icon: Icons.location_city,
                  label: 'Gradovi',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/cities'),
                ),
                _item(
                  context: context,
                  icon: Icons.category,
                  label: 'Kategorije',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/categories'),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _item(
                context: context,
                icon: Icons.logout,
                label: 'Odjava',
                onTap: () => _handleLogout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odjava'),
        content: const Text('Da li ste sigurni da se želite odjaviti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              AuthProvider.clear();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text(
              'Odjavi se',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item({
    required BuildContext context,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      hoverColor: const Color(0xFF2563EB).withOpacity(0.35),
    );
  }
}
