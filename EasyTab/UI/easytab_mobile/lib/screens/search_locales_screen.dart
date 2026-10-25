import 'package:easytab_mobile/models/category.dart';
import 'package:easytab_mobile/models/city.dart';
import 'package:easytab_mobile/models/country.dart';
import 'package:easytab_mobile/models/locale.dart';
import 'package:easytab_mobile/providers/category_provider.dart';
import 'package:easytab_mobile/providers/city_provider.dart';
import 'package:easytab_mobile/providers/country_provider.dart';
import 'package:easytab_mobile/providers/locale_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:easytab_mobile/screens/locale_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';

class SearchLocalesScreen extends StatefulWidget {
  const SearchLocalesScreen({super.key});

  @override
  State<SearchLocalesScreen> createState() => _SearchLocalesScreenState();
}

class _SearchLocalesScreenState extends State<SearchLocalesScreen> {
  late LocaleProvider _localeProvider;
  late CategoryProvider _categoryProvider;
  late CountryProvider _countryProvider;
  late CityProvider _cityProvider;

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isLoadingFilters = true;
  bool _filtersExpanded = true;
  bool _hasSearched = false;
  String? _loadError;
  String? _filterError;
  int _requestVersion = 0;
  List<Locale> _locales = [];
  List<Category> _categories = [];
  List<Country> _countries = [];
  List<City> _filteredCities = [];
  bool _isLoadingCities = false;
  String? _cityError;
  int _cityRequestVersion = 0;

  int? _selectedCategoryId;
  int? _selectedCountryId;
  int? _selectedCityId;
  int? _selectedRating;

  int _totalCount = 0;
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _localeProvider = context.read<LocaleProvider>();
    _categoryProvider = context.read<CategoryProvider>();
    _countryProvider = context.read<CountryProvider>();
    _cityProvider = context.read<CityProvider>();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait<void>([_loadDropdowns(), _loadLocales()]);
  }

  Future<void> _loadDropdowns() async {
    setState(() => _isLoadingFilters = true);
    try {
      final results = await Future.wait([
        _categoryProvider.getLookupItems(),
        _countryProvider.getLookupItems(),
      ]);

      if (!mounted) return;

      setState(() {
        _categories = results[0] as List<Category>;
        _countries = results[1] as List<Country>;
        _filterError = null;
      });
      if (mounted) setState(() => _isLoadingFilters = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingFilters = false;
        _filterError = userError(e);
      });
    }
  }

  Future<void> _loadLocales() async {
    final version = ++_requestVersion;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final filter = <String, dynamic>{
        "Page": _currentPage + 1,
        "PageSize": _pageSize,
        "IncludeTotalCount": true,
        if (_searchController.text.trim().isNotEmpty)
          "Name": _searchController.text.trim(),
        if (_selectedCategoryId != null) "CategoryId": _selectedCategoryId,
        if (_selectedCityId != null) "CityId": _selectedCityId,
        if (_selectedCountryId != null && _selectedCityId == null)
          "CountryId": _selectedCountryId,
        if (_selectedRating != null) "Rating": _selectedRating,
      };

      final result = await _localeProvider.get(filter: filter);

      if (!mounted || version != _requestVersion) return;
      setState(() {
        _locales = result.items ?? [];
        _totalCount = result.totalCount ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _isLoading = false;
        _loadError = userError(e);
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _currentPage = 0);
    await _loadLocales();
  }

  void _searchLocales() {
    setState(() {
      _currentPage = 0;
      _hasSearched = true;
    });
    _loadLocales();
  }

  int get _totalPages =>
      _totalCount == 0 ? 1 : (_totalCount / _pageSize).ceil();

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedCategoryId != null ||
      _selectedCountryId != null ||
      _selectedCityId != null ||
      _selectedRating != null;

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;
    setState(() => _currentPage = page);
    _loadLocales();
  }

  void _clearFilters() {
    _cityRequestVersion++;
    _searchController.clear();
    setState(() {
      _selectedCategoryId = null;
      _selectedCountryId = null;
      _selectedCityId = null;
      _selectedRating = null;
      _filteredCities = [];
      _isLoadingCities = false;
      _cityError = null;
      _currentPage = 0;
      _hasSearched = false;
    });
    // Nakon čišćenja filtera, učitaj sve lokacije
    _loadLocales();
  }

  Future<void> _onCountryChanged(int? countryId) async {
    final version = ++_cityRequestVersion;
    setState(() {
      _selectedCountryId = countryId;
      _selectedCityId = null;
      _filteredCities = [];
      _cityError = null;
      _isLoadingCities = countryId != null;
      _currentPage = 0;
    });
    if (countryId == null) return;
    try {
      final cities = await _cityProvider.getLookupItems(
        filter: {'CountryId': countryId},
      );
      if (!mounted || version != _cityRequestVersion) return;
      setState(() {
        _filteredCities = cities;
        _isLoadingCities = false;
      });
    } catch (e) {
      if (!mounted || version != _cityRequestVersion) return;
      setState(() {
        _cityError = userError(e);
        _isLoadingCities = false;
      });
    }
  }

  void _onCategoryChanged(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _currentPage = 0;
    });
  }

  void _onCityChanged(int? cityId) {
    setState(() {
      _selectedCityId = cityId;
      _currentPage = 0;
    });
  }

  void _onRatingChanged(int? rating) {
    setState(() {
      _selectedRating = rating;
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSearchHeader(),
                  if (_filterError != null)
                    ListTile(
                      title: Text(_filterError!),
                      trailing: TextButton(
                        onPressed: _loadDropdowns,
                        child: const Text('Ponovi filtere'),
                      ),
                    ),
                  if (_isLoadingFilters) const LinearProgressIndicator(),
                  if (_filtersExpanded &&
                      !_isLoadingFilters &&
                      _filterError == null)
                    _buildFilters(),
                  if (_hasSearched && !_isLoading && _loadError == null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pronađeno: $_totalCount ${_totalCount == 1 ? 'lokal' : 'lokala'}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      TextButton(
                        onPressed: _loadLocales,
                        child: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_locales.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == _locales.length) return _buildPagination();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _LocaleCard(locale: _locales[index]),
                    );
                  }, childCount: _locales.length + 1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pretraži po nazivu lokala...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF1E40AF),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _searchLocales(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: _filtersExpanded ? const Color(0xFF1E40AF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Icon(
                  Icons.tune_rounded,
                  color: _filtersExpanded
                      ? Colors.white
                      : const Color(0xFF1E40AF),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _searchLocales,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size(96, 48),
            ),
            child: const Text(
              'Pretraži',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filteri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (_hasActiveFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Očisti',
                      style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _buildDropdown<int>(
              label: 'Kategorija',
              icon: Icons.category_outlined,
              value: _selectedCategoryId,
              hint: 'Sve kategorije',
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Sve kategorije'),
                ),
                ..._categories.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name ?? '', overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: _onCategoryChanged,
            ),
            const SizedBox(height: 10),
            _buildDropdown<int>(
              label: 'Država',
              icon: Icons.public_outlined,
              value: _selectedCountryId,
              hint: 'Sve države',
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Sve države'),
                ),
                ..._countries.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name ?? '', overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: _onCountryChanged,
            ),
            const SizedBox(height: 10),
            _buildDropdown<int>(
              label: 'Grad',
              icon: Icons.location_city_outlined,
              value: _selectedCityId,
              hint: _selectedCountryId == null
                  ? 'Prvo odaberite državu'
                  : 'Svi gradovi',
              helperText: _selectedCountryId == null
                  ? 'Prvo odaberite državu.'
                  : _isLoadingCities
                  ? 'Učitavanje gradova…'
                  : _cityError ??
                        (_filteredCities.isEmpty
                            ? 'Odabrana država nema dostupnih gradova.'
                            : null),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Svi gradovi'),
                ),
                ..._filteredCities.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name ?? '', overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged:
                  _selectedCountryId == null ||
                      _isLoadingCities ||
                      _cityError != null ||
                      _filteredCities.isEmpty
                  ? null
                  : _onCityChanged,
            ),
            if (_cityError != null)
              TextButton(
                onPressed: () => _onCountryChanged(_selectedCountryId),
                child: const Text('Ponovi učitavanje gradova'),
              ),
            const SizedBox(height: 10),
            _buildDropdown<int>(
              label: 'Prosječna ocjena',
              icon: Icons.star_outline,
              value: _selectedRating,
              hint: 'Sve ocjene',
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Sve ocjene'),
                ),
                ...List.generate(
                  5,
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text(
                      '${index + 1} ${index == 0 ? 'zvijezdica' : 'zvjezdice'}',
                    ),
                  ),
                ),
              ],
              onChanged: _onRatingChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            helperText: helperText,
            helperMaxLines: 3,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E40AF)),
            ),
          ),
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade500)),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return PaginationUtils.buildPageControls(
      currentPage: _currentPage,
      totalCount: _totalCount,
      pageSize: _pageSize,
      onPageChanged: _goToPage,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            _hasActiveFilters
                ? 'Nema lokala za zadane kriterije'
                : 'Nema dostupnih lokala',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearFilters,
              child: const Text(
                'Očisti filtere',
                style: TextStyle(color: Color(0xFF1E40AF)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocaleCard extends StatelessWidget {
  final Locale locale;
  const _LocaleCard({required this.locale});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LocaleDetailScreen(locale: locale)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 148,
                width: double.infinity,
                child: ImageUtils.buildImage(
                  locale.logo,
                  fit: BoxFit.cover,
                  placeholder: _placeholder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 84),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            locale.name ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (locale.averageRating != null &&
                            locale.averageRating! > 0) ...[
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                locale.averageRating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFBBF24),
                                size: 25,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            locale.categoryName ?? 'Ostalo',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (locale.address != null &&
                            locale.address!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    locale.address!,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1E40AF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: Color(0xFF1E40AF),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(Icons.store_outlined, size: 48, color: Color(0xFF1E40AF)),
      ),
    );
  }
}
