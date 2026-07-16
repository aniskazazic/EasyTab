import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/country.dart';
import 'package:easytab_desktop/providers/country_provider.dart';
import 'package:easytab_desktop/screens/admin_country_details_screen.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminCountriesListScreen extends StatefulWidget {
  const AdminCountriesListScreen({super.key});

  @override
  State<AdminCountriesListScreen> createState() =>
      _AdminCountriesListScreenState();
}

class _AdminCountriesListScreenState extends State<AdminCountriesListScreen> {
  late CountryProvider countryProvider;
  List<Country> _countries = [];
  int _totalCount = 0;
  int _currentPage = 0;
  final int _pageSize = 10;

  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  // Debounce za pretragu
  DateTime? _lastSearchTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    countryProvider = context.read<CountryProvider>();
    _loadCountries();
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final now = DateTime.now();
    _lastSearchTime = now;

    Future.delayed(const Duration(milliseconds: 400), () {
      if (_lastSearchTime == now) {
        setState(() => _currentPage = 0);
        _loadCountries();
      }
    });
  }

  Future<void> _loadCountries() async {
    setState(() => isLoading = true);
    try {
      final filter = {
        "Page": _currentPage + 1,
        "PageSize": _pageSize,
        "IncludeTotalCount": true,
        if (searchController.text.isNotEmpty) "Name": searchController.text,
      };

      var result = await countryProvider.get(filter: filter);
      setState(() {
        _countries = result.items ?? [];
        _totalCount = result.totalCount ?? 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }



  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Greška'),
        content: Text(message.replaceAll("Exception: ", "")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Country country) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje države'),
        content: Text(
          'Da li ste sigurni da želite obrisati državu ${country.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await countryProvider.delete(country.id!);
                await _loadCountries();
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: const Text('Obriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Države',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearch(),
          const SizedBox(height: 16),
          isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _buildTable(),
          if (!isLoading)
            PaginationUtils.buildPageControls(
              currentPage: _currentPage,
              totalCount: _totalCount,
              pageSize: _pageSize,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
                _loadCountries();
              },
              pageButtonSize: 36,
            ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Pretraga po nazivu...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E40AF),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminCountryDetailsScreen(),
            ),
          ).then((_) => _loadCountries()),
          child: const Text('Dodaj', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_countries.isEmpty) {
      return const Expanded(
        child: Center(child: Text('Nema država za prikaz.')),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF1E40AF)),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            columns: const [
              DataColumn(label: Text('Naziv')),
              DataColumn(label: Text('Akcije')),
            ],
            rows: _countries.map((country) {
              return DataRow(
                cells: [
                  DataCell(Text(country.name ?? '')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Uredi',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AdminCountryDetailsScreen(country: country),
                            ),
                          ).then((_) => _loadCountries()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Obriši',
                          onPressed: () => _confirmDelete(country),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }


}
