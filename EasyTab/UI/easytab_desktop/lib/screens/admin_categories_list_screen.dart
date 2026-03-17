import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/category.dart';
import 'package:easytab_desktop/providers/category_provider.dart';
import 'package:easytab_desktop/screens/admin_category_details_screen.dart';
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
  List<Category> _allCategories = [];
  List<Category> _displayCategories = [];
  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    categoryProvider = context.read<CategoryProvider>();
    _loadCategories();
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

  Future<void> _loadCategories() async {
    setState(() => isLoading = true);
    try {
      var result = await categoryProvider.get(filter: {"RetrieveAll": true});
      setState(() {
        _allCategories = result.items ?? [];
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
      _displayCategories = _allCategories
          .where(
            (c) =>
                query.isEmpty ||
                (c.name?.toLowerCase().contains(query) ?? false) ||
                (c.description?.toLowerCase().contains(query) ?? false),
          )
          .toList();
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
    if (_displayCategories.isEmpty) {
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
            rows: _displayCategories.map((category) {
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
