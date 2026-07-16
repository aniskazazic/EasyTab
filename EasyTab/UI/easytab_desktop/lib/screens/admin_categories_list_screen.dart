import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/category.dart';
import 'package:easytab_desktop/providers/category_provider.dart';
import 'package:easytab_desktop/screens/admin_category_details_screen.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminCategoriesListScreen extends StatefulWidget {
  const AdminCategoriesListScreen({super.key});

  @override
  State<AdminCategoriesListScreen> createState() =>
      _AdminCategoriesListScreenState();
}

class _AdminCategoriesListScreenState extends State<AdminCategoriesListScreen> {
  late CategoryProvider categoryProvider;
  List<Category> _categories = [];
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
    categoryProvider = context.read<CategoryProvider>();
    _loadCategories();
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
        _loadCategories();
      }
    });
  }

  Future<void> _loadCategories() async {
    setState(() => isLoading = true);
    try {
      final filter = {
        "Page": _currentPage + 1,
        "PageSize": _pageSize,
        "IncludeTotalCount": true,
        if (searchController.text.isNotEmpty) "Name": searchController.text,
      };

      var result = await categoryProvider.get(filter: filter);
      setState(() {
        _categories = result.items ?? [];
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

  void _confirmDelete(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje kategorije'),
        content: Text(
          'Da li ste sigurni da želite obrisati kategoriju ${category.name}?',
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
                await categoryProvider.delete(category.id!);
                await _loadCategories();
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
      title: 'Kategorije',
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
                _loadCategories();
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
              builder: (context) => const AdminCategoryDetailsScreen(),
            ),
          ).then((_) => _loadCategories()),
          child: const Text('Dodaj', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_categories.isEmpty) {
      return const Expanded(
        child: Center(child: Text('Nema kategorija za prikaz.')),
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
              DataColumn(label: Text('Opis')),
              DataColumn(label: Text('Akcije')),
            ],
            rows: _categories.map((category) {
              return DataRow(
                cells: [
                  DataCell(Text(category.name ?? '')),
                  DataCell(Text(category.description ?? '')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Uredi',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminCategoryDetailsScreen(
                                category: category,
                              ),
                            ),
                          ).then((_) => _loadCategories()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Obriši',
                          onPressed: () => _confirmDelete(category),
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
