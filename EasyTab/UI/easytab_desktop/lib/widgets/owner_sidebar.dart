import 'package:easytab_desktop/models/locale.dart' as models;
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/screens/owner_locale_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OwnerSidebar extends StatefulWidget {
  final int? activeLocaleId;
  final Function(int localeId, String section)? onSectionTap;
  final VoidCallback? onRefresh;

  const OwnerSidebar({
    super.key,
    this.activeLocaleId,
    this.onSectionTap,
    this.onRefresh,
  });

  @override
  State<OwnerSidebar> createState() => _OwnerSidebarState();
}

class _OwnerSidebarState extends State<OwnerSidebar> {
  List<models.Locale> _locales = [];
  Set<int> expandedLocales = {};

  @override
  void initState() {
    super.initState();
    _loadLocales();
  }

  Future<void> _loadLocales() async {
    try {
      final localeProvider = context.read<LocaleProvider>();
      final ownerId = AuthProvider.currentUser?.id;
      if (ownerId == null) return;

      final locales = await localeProvider.getByOwner(ownerId);
      setState(() {
        _locales = locales;
        /*if (locales.isNotEmpty && expandedLocales.isEmpty) {
          expandedLocales.add(locales.first.id!);
        }*/
      });
    } catch (e) {
      debugPrint('Error loading locales: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF1E40AF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Zdravo, ${AuthProvider.currentUser?.firstName ?? "Owner"}',
                  style: TextStyle(fontSize: 12, color: Colors.blue[100]),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Moji lokali',
              style: TextStyle(
                color: Colors.blue[200],
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._locales.map((locale) => _buildLocaleItem(locale)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Dodaj novi lokal',
                      style: TextStyle(fontSize: 13),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OwnerLocaleDetailsScreen(
                          onSaved: () {
                            _loadLocales(); // Refresh sidebar
                            widget.onRefresh?.call(); // Refresh dashboard
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              _bottomItem(
                icon: Icons.settings,
                label: 'Postavke',
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/owner-settings'),
              ),
              _bottomItem(
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

  Widget _buildLocaleItem(models.Locale locale) {
    final isExpanded = expandedLocales.contains(locale.id);

    return Column(
      children: [
        ListTile(
          dense: true,
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: locale.logo != null && locale.logo!.isNotEmpty
                  ? Image.network(
                      locale.logo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.home, color: Colors.white, size: 16),
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    )
                  : const Icon(Icons.home, color: Colors.white, size: 16),
            ),
          ),
          title: Text(
            locale.name ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.white70,
            size: 18,
          ),
          onTap: () {
            setState(() {
              if (isExpanded) {
                expandedLocales.remove(locale.id);
              } else {
                expandedLocales.add(locale.id!);
              }
            });
          },
        ),

        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                _subItem('Dashboard', locale.id!),
                _subItem('Rezervacije', locale.id!),
                _subItem('Stolovi', locale.id!),
                _subItem('Recenzije', locale.id!),
                _subItem('Radnici', locale.id!),
                _subItem('Postavke', locale.id!),
              ],
            ),
          ),
      ],
    );
  }

  Widget _subItem(String label, int localeId) {
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      hoverColor: const Color(0xFF2563EB).withOpacity(0.35),
      onTap: () => widget.onSectionTap?.call(localeId, label),
    );
  }

  Widget _bottomItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      onTap: onTap,
      hoverColor: const Color(0xFF2563EB).withOpacity(0.35),
    );
  }
}
