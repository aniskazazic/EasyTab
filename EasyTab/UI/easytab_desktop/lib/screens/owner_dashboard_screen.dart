import 'package:easytab_desktop/models/locale.dart' as models;
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/providers/owner_provider.dart';
import 'package:easytab_desktop/screens/owner_locale_details_screen.dart';
import 'package:easytab_desktop/screens/owner_tables_screen.dart';
import 'package:easytab_desktop/screens/owner_workers_screen.dart';
import 'package:easytab_desktop/widgets/owner_sidebar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int? activeLocaleId;
  models.Locale? activeLocale;
  String activeSection = 'Dashboard';

  int todayReservations = 0;
  int activeTables = 0;
  int totalTables = 0;
  int todayGuests = 0;
  List<Map<String, dynamic>> tableDistribution = [];
  bool isLoading = false;

  late OwnerProvider ownerProvider;
  late LocaleProvider localeProvider;

  @override
  void initState() {
    super.initState();
    ownerProvider = context.read<OwnerProvider>();
    localeProvider = context.read<LocaleProvider>();
    _loadFirstLocale();
  }

  Future<void> _loadFirstLocale() async {
    try {
      final ownerId = AuthProvider.currentUser?.id;
      if (ownerId == null) return;

      final locales = await localeProvider.getByOwner(ownerId);
      if (locales.isNotEmpty) {
        setState(() {
          activeLocale = locales.first;
          activeLocaleId = locales.first.id;
        });
        await _loadStats(locales.first.id!);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _refresh() async {
    await _loadFirstLocale();
  }

  Future<void> _loadStats(int localeId) async {
    setState(() => isLoading = true);
    try {
      final stats = await ownerProvider.getStats(localeId);
      setState(() {
        todayReservations = stats.todayReservations;
        activeTables = stats.activeTables;
        totalTables = stats.totalTables;
        todayGuests = stats.todayGuests;
        tableDistribution = stats.tableDistribution;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _onSectionTap(int localeId, String section) async {
    final ownerId = AuthProvider.currentUser?.id;
    if (ownerId == null) return;

    final locales = await localeProvider.getByOwner(ownerId);
    final locale = locales.firstWhere(
      (l) => l.id == localeId,
      orElse: () => locales.first,
    );

    setState(() {
      activeLocaleId = localeId;
      activeLocale = locale;
      activeSection = section;
    });

    switch (section) {
      case 'Dashboard':
        await _loadStats(localeId);
        break;
      case 'Postavke':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerLocaleDetailsScreen(
              locale: locale,
              onSaved: () {
                _refresh(); // Refresh dashboard i sidebar
              },
            ),
          ),
        );
        break;
      case 'Rezervacije':
        // TODO
        break;
      case 'Stolovi':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerTablesScreen(
              localeId: localeId,
              localeName: locale.name ?? '',
            ),
          ),
        );
        break;
      case 'Recenzije':
        // TODO
        break;
      case 'Radnici':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerWorkersScreen(
              localeId: localeId,
              localeName: locale.name ?? '',
              onSectionTap: _onSectionTap,
              onRefresh: _refresh,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          OwnerSidebar(
            activeLocaleId: activeLocaleId,
            onSectionTap: _onSectionTap,
            onRefresh: _refresh,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Pregled današnjih aktivnosti za ${activeLocale?.name ?? ""}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_today,
                    title: 'Današnje rezervacije',
                    value: '$todayReservations',
                    subtitle: 'Broj potvrđenih rezervacija',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.table_restaurant,
                    title: 'Aktivni stolovi',
                    value: '$activeTables / $totalTables',
                    subtitle: totalTables > 0
                        ? '${((activeTables / totalTables) * 100).toStringAsFixed(0)} % popunjenosti'
                        : '0 % popunjenosti',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.person,
                    title: 'Broj gostiju',
                    value: '$todayGuests',
                    subtitle: 'Očekivan danas',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (tableDistribution.isNotEmpty) _buildPieChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    final sections = tableDistribution.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final percentage = (item['percentage'] as num).toDouble();

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: percentage,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 120,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Raspodjela stolova',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Raspodjela po veličini stola',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  height: 250,
                  width: 250,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 0,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tableDistribution.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item['seats']}-seater',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
