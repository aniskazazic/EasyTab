import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/providers/category_provider.dart';
import 'package:easytab_desktop/providers/city_provider.dart';
import 'package:easytab_desktop/providers/country_provider.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool isLoading = true;

  int countLocales = 0;
  int countCountries = 0;
  int countCities = 0;
  int countCategories = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final localeProvider = context.read<LocaleProvider>();
      final countryProvider = context.read<CountryProvider>();
      final cityProvider = context.read<CityProvider>();
      final categoryProvider = context.read<CategoryProvider>();

      final results = await Future.wait([
        localeProvider.get(
          filter: {"IncludeTotalCount": true, "RetrieveAll": true},
        ),
        countryProvider.get(
          filter: {"IncludeTotalCount": true, "RetrieveAll": true},
        ),
        cityProvider.get(
          filter: {"IncludeTotalCount": true, "RetrieveAll": true},
        ),
        categoryProvider.get(
          filter: {"IncludeTotalCount": true, "RetrieveAll": true},
        ),
      ]);

      setState(() {
        countLocales = results[0].totalCount ?? results[0].items?.length ?? 0;
        countCountries = results[1].totalCount ?? results[1].items?.length ?? 0;
        countCities = results[2].totalCount ?? results[2].items?.length ?? 0;
        countCategories =
            results[3].totalCount ?? results[3].items?.length ?? 0;
        isLoading = false;
      });
    } catch (e) {
      // Ako greška — prikaži 0 za sve
      setState(() {
        countLocales = 0;
        countCountries = 0;
        countCities = 0;
        countCategories = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Dashboard',
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.8,
                  children: [
                    _buildDashboardCard(
                      icon: Icons.home,
                      label: 'Lokali',
                      count: countLocales.toString(),
                    ),
                    _buildDashboardCard(
                      icon: Icons.public,
                      label: 'Države',
                      count: countCountries.toString(),
                    ),
                    _buildDashboardCard(
                      icon: Icons.location_city,
                      label: 'Gradovi',
                      count: countCities.toString(),
                    ),
                    _buildDashboardCard(
                      icon: Icons.category,
                      label: 'Kategorije',
                      count: countCategories.toString(),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required String count,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.grey[700]),
              const SizedBox(height: 12),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
