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

  // Lokali — server-side
  List<Locale> _locales = [];
  int _totalCount = 0;
  int _currentPage = 0;
  final int _pageSize = 10;

  // Dropdownovi — učitaj jednom, čuvaj lokalno
  List<Country> _countries = [];
  List<City> _allCities = [];
  List<City> _filteredCities = [];

  final TextEditingController searchController = TextEditingController();
  int? selectedCountryId;
  int? selectedCityId;
  bool showDeleted = false;
  bool isLoading = false;

  // Debounce za pretragu
  DateTime? _lastSearchTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localeProvider = context.read<LocaleProvider>();
    countryProvider = context.read<CountryProvider>();
    cityProvider = context.read<CityProvider>();
    categoryProvider = context.read<CategoryProvider>();
    _loadDropdowns();
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
        _loadLocales();
      }
    });
  }

  // Učitaj dropdownove samo jednom
  Future<void> _loadDropdowns() async {
    try {
      final results = await Future.wait([
        countryProvider.get(filter: {"RetrieveAll": true}),
        cityProvider.get(filter: {"RetrieveAll": true}),
      ]);

      setState(() {
        _countries = (results[0] as SearchResult<Country>).items ?? [];
        _allCities = (results[1] as SearchResult<City>).items ?? [];
        _filteredCities = _allCities;
      });

      await _loadLocales();
    } catch (e) {
      _showError(e.toString());
    }
  }

  // Učitaj lokale sa server-side paginacijom i filterima
  Future<void> _loadLocales() async {
    setState(() => isLoading = true);
    try {
      final filter = <String, dynamic>{
        "Page": _currentPage,
        "PageSize": _pageSize,
        "IncludeTotalCount": true,
        if (showDeleted) "IsDeleted": true,
        if (searchController.text.isNotEmpty) "Name": searchController.text,
        if (selectedCityId != null) "CityId": selectedCityId,
        if (selectedCountryId != null && selectedCityId == null)
          "CountryId": selectedCountryId,
      };

      final result = await localeProvider.get(filter: filter);

      setState(() {
        _locales = result.items ?? [];
        _totalCount = result.totalCount ?? 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  int get _totalPages =>
      _totalCount == 0 ? 1 : (_totalCount / _pageSize).ceil();

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;
    setState(() => _currentPage = page);
    _loadLocales();
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
      await _loadLocales();
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
      await _loadLocales();
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
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _buildTable(),
          if (!isLoading && _totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        // Tekstualna pretraga
        Expanded(
          flex: 3,
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Pretraga',
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
                _currentPage = 0;
              });
              _loadLocales();
            },
          ),
        ),
        const SizedBox(width: 12),

        // Dropdown za grad
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
                    setState(() {
                      selectedCityId = value;
                      _currentPage = 0;
                    });
                    _loadLocales();
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
          ).then((_) => _loadLocales()),
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
            setState(() {
              showDeleted = value ?? false;
              _currentPage = 0;
            });
            _loadLocales();
          },
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_locales.isEmpty) {
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
            rows: _locales.map((locale) {
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
                            ).then((_) => _loadLocales()),
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

  Widget _buildPagination() {
    const int maxVisible = 5;
    int startPage = (_currentPage - maxVisible ~/ 2).clamp(0, _totalPages - 1);
    int endPage = (startPage + maxVisible - 1).clamp(0, _totalPages - 1);
    if (endPage - startPage < maxVisible - 1) {
      startPage = (endPage - maxVisible + 1).clamp(0, _totalPages - 1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Ukupno: $_totalCount  |  Stranica ${_currentPage + 1} od $_totalPages',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(width: 24),

          _pageButton(
            icon: Icons.first_page,
            onTap: _currentPage > 0 ? () => _goToPage(0) : null,
          ),
          _pageButton(
            icon: Icons.chevron_left,
            onTap: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
          ),

          for (int i = startPage; i <= endPage; i++) _pageNumberButton(i),

          _pageButton(
            icon: Icons.chevron_right,
            onTap: _currentPage < _totalPages - 1
                ? () => _goToPage(_currentPage + 1)
                : null,
          ),
          _pageButton(
            icon: Icons.last_page,
            onTap: _currentPage < _totalPages - 1
                ? () => _goToPage(_totalPages - 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _pageButton({required IconData icon, VoidCallback? onTap}) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onTap,
      color: onTap != null ? const Color(0xFF1E40AF) : Colors.grey.shade400,
    );
  }

  Widget _pageNumberButton(int page) {
    final isActive = page == _currentPage;
    return GestureDetector(
      onTap: () => _goToPage(page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E40AF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? const Color(0xFF1E40AF) : Colors.grey.shade400,
          ),
        ),
        child: Center(
          child: Text(
            '${page + 1}',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
