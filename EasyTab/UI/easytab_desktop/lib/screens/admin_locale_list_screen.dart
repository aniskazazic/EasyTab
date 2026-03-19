import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/city.dart';
import 'package:easytab_desktop/models/country.dart';
import 'package:easytab_desktop/models/locale.dart';
import 'package:easytab_desktop/models/search_result.dart';
import 'package:easytab_desktop/providers/category_provider.dart';
import 'package:easytab_desktop/providers/city_provider.dart';
import 'package:easytab_desktop/providers/country_provider.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/screens/admin_locale_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LocaleListScreen extends StatefulWidget {
  const LocaleListScreen({super.key});

  @override
  State<LocaleListScreen> createState() => _LocaleListScreenState();
}

class _LocaleListScreenState extends State<LocaleListScreen> {
  late LocaleProvider localeProvider;
  late CountryProvider countryProvider;
  late CityProvider cityProvider;
  late CategoryProvider categoryProvider;

  List<Locale> _allLocales = [];
  List<Locale> _displayLocales = [];

  List<Country> _countries = [];
  List<City> _allCities = [];
  List<City> _filteredCities = [];

  final TextEditingController searchController = TextEditingController();
  int? selectedCountryId;
  int? selectedCityId;
  bool showDeleted = false;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localeProvider = context.read<LocaleProvider>();
    countryProvider = context.read<CountryProvider>();
    cityProvider = context.read<CityProvider>();
    categoryProvider = context.read<CategoryProvider>();
    _loadData();
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final localeFilter = showDeleted
          ? {"RetrieveAll": true}
          : {"RetrieveAll": true, "IsDeleted": false};

      final results = await Future.wait([
        localeProvider.get(filter: localeFilter),
        countryProvider.get(filter: {"RetrieveAll": true}),
        cityProvider.get(filter: {"RetrieveAll": true}),
      ]);

      setState(() {
        _allLocales = (results[0] as SearchResult<Locale>).items ?? [];
        _countries = (results[1] as SearchResult<Country>).items ?? [];
        _allCities = (results[2] as SearchResult<City>).items ?? [];
        _filteredCities = _allCities;
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase();

    setState(() {
      _displayLocales = _allLocales.where((locale) {
        final deletedFilter = showDeleted ? true : !(locale.isDeleted ?? false);

        final searchFilter =
            query.isEmpty ||
            (locale.name?.toLowerCase().contains(query) ?? false) ||
            (locale.address?.toLowerCase().contains(query) ?? false);

        final countryFilter =
            selectedCountryId == null ||
            _allCities
                .where((city) => city.countryId == selectedCountryId)
                .any((city) => city.id == locale.cityId);

        final cityFilter =
            selectedCityId == null || locale.cityId == selectedCityId;

        return deletedFilter && searchFilter && countryFilter && cityFilter;
      }).toList();
    });
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

  Future<void> _deleteLocale(int id) async {
    try {
      await localeProvider.delete(id);
      await _loadData();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _reactivateLocale(Locale locale) async {
    try {
      await localeProvider.update(locale.id!, {
        "name": locale.name,
        "address": locale.address,
        "isDeleted": false,
      });
      await _loadData();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _confirmDelete(Locale locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje lokala'),
        content: Text(
          'Da li ste sigurni da želite obrisati lokal ${locale.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteLocale(locale.id!);
            },
            child: const Text('Obriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmReactivate(Locale locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reaktivacija lokala'),
        content: Text(
          'Da li ste sigurni da želite reaktivirati lokal ${locale.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              _reactivateLocale(locale);
            },
            child: const Text(
              'Reaktiviraj',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Lokali',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearch(),
          _buildShowDeletedCheckbox(),
          const SizedBox(height: 16),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildTable(),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Pretraga',
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
        const SizedBox(width: 12),

        // Dropdown za državu
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            value: selectedCountryId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            hint: const Text('Sve države'),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('Sve države'),
              ),
              ..._countries.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name ?? '')),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectedCountryId = value;
                selectedCityId = null;

                _filteredCities = value == null
                    ? []
                    : _allCities
                          .where((city) => city.countryId == value)
                          .toList();
              });
              _applyFilters();
            },
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            value: selectedCityId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            hint: Text(
              selectedCountryId == null ? 'Odaberite državu' : 'Svi gradovi',
            ),

            onChanged: selectedCountryId == null
                ? null
                : (value) {
                    setState(() => selectedCityId = value);
                    _applyFilters();
                  },
            items: [
              if (selectedCountryId != null)
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Svi gradovi'),
                ),
              ..._filteredCities.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name ?? '')),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E40AF),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LocaleDetailsScreen()),
          ).then((_) => _loadData()),
          child: const Text('Dodaj', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildShowDeletedCheckbox() {
    return Row(
      children: [
        const Text('Prikaži izbrisane : '),
        Checkbox(
          value: showDeleted,
          onChanged: (value) {
            setState(() => showDeleted = value ?? false);
            _loadData(); // reload s backenda s ispravnim filterom
          },
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_displayLocales.isEmpty) {
      return const Expanded(
        child: Center(child: Text('Nema lokala za prikaz.')),
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
              DataColumn(label: Text('Ime')),
              DataColumn(label: Text('Država')),
              DataColumn(label: Text('Grad')),
              DataColumn(label: Text('Adresa')),
              DataColumn(label: Text('Kategorija')),
              DataColumn(label: Text('Vlasnik')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Akcije')),
            ],
            rows: _displayLocales.map((locale) {
              final isDeleted = locale.isDeleted ?? false;

              return DataRow(
                cells: [
                  DataCell(Text(locale.name ?? '')),
                  DataCell(Text(locale.countryName ?? '')),
                  DataCell(Text(locale.cityName ?? '')),
                  DataCell(Text(locale.address ?? '')),
                  DataCell(Text(locale.categoryName ?? '')),
                  DataCell(Text(locale.ownerName ?? '')),
                  DataCell(
                    Text(
                      isDeleted ? 'Izbrisan' : 'Aktivan',
                      style: TextStyle(
                        color: isDeleted ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        if (!isDeleted)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Uredi',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LocaleDetailsScreen(locale: locale),
                              ),
                            ).then((_) => _loadData()),
                          ),
                        IconButton(
                          icon: Icon(
                            isDeleted ? Icons.restore : Icons.delete,
                            color: isDeleted ? Colors.green : Colors.red,
                          ),
                          tooltip: isDeleted ? 'Reaktiviraj' : 'Obriši',
                          onPressed: () => isDeleted
                              ? _confirmReactivate(locale)
                              : _confirmDelete(locale),
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
