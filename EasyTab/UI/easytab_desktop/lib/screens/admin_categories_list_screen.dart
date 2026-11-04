import 'package:easytab_desktop/widgets/load_error.dart';
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
  bool isLoading = true;
  bool _isMutating = false;
  String? _loadError;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    categoryProvider = context.read<CategoryProvider>();
    _loadCategories();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchPressed() {
    setState(() => _currentPage = 0);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      isLoading = true;
      _loadError = null;
    });
    try {
      final filter = {
        "Page": _currentPage + 1,
        "PageSize": _pageSize,
        "IncludeTotalCount": true,
        if (searchController.text.isNotEmpty) "Name": searchController.text,
      };

      var result = await categoryProvider.get(filter: filter);
      if (!mounted) return;
      setState(() {
        _categories = result.items ?? [];
        _totalCount = result.totalCount ?? 0;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _loadError = 'Greška pri učitavanju podataka: ${userError(e)}';
      });
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Greška'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      await categoryProvider.delete(id);
      if (!mounted) return;
      showFeedback(context, 'Kategorija je uspješno obrisana.');
      await _loadCategories();
    } catch (e) {
      if (mounted) _showError(userError(e));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _confirmDelete(Category category) {
    if (_isMutating) return;
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
              await _deleteCategory(category.id!);
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
          if (_isMutating) const LinearProgressIndicator(),
          isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _buildTable(),
          if (!isLoading && _loadError == null)
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
            onSubmitted: (_) => _onSearchPressed(),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Pretraži'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onPressed: _onSearchPressed,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: _isMutating
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminCategoryDetailsScreen(),
                    ),
                  ).then((_) => _onSearchPressed()),
            child: const Text('Dodaj', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_loadError != null) {
      return Expanded(
        child: LoadError(message: _loadError!, onRetry: _loadCategories),
      );
    }
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
                          onPressed: _isMutating
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AdminCategoryDetailsScreen(
                                          category: category,
                                        ),
                                  ),
                                ).then((_) => _loadCategories()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Obriši',
                          onPressed: _isMutating
                              ? null
                              : () => _confirmDelete(category),
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
