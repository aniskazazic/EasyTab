import 'package:easytab_desktop/widgets/load_error.dart';
import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/role.dart';
import 'package:easytab_desktop/providers/role_provider.dart';
import 'package:easytab_desktop/screens/admin_role_details_screen.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminRolesListScreen extends StatefulWidget {
  const AdminRolesListScreen({super.key});

  @override
  State<AdminRolesListScreen> createState() => _AdminRolesListScreenState();
}

class _AdminRolesListScreenState extends State<AdminRolesListScreen> {
  late RoleProvider roleProvider;
  List<Role> _roles = [];
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
    roleProvider = context.read<RoleProvider>();
    _loadRoles();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchPressed() {
    if (!mounted) return;
    setState(() => _currentPage = 0);
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      _loadError = null;
    });
    try {
      final filter = {
        "Page": _currentPage + 1,
        "PageSize": _pageSize,
        "IncludeTotalCount": true,
        if (searchController.text.trim().isNotEmpty)
          "NameGTE": searchController.text.trim(),
      };

      var result = await roleProvider.get(filter: filter);
      if (!mounted) return;
      setState(() {
        _roles = result.items ?? [];
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

  Future<void> _deleteRole(int id) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      await roleProvider.delete(id);
      if (!mounted) return;
      showFeedback(context, 'Uloga je uspješno obrisana.');
      if (_roles.length == 1 && _currentPage > 0) _currentPage--;
      await _loadRoles();
    } catch (e) {
      if (mounted) _showError(userError(e));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _confirmDelete(Role role) {
    if (_isMutating) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje uloge'),
        content: Text(
          'Da li ste sigurni da želite obrisati ulogu ${role.name}?',
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
              await _deleteRole(role.id!);
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
      title: 'Uloge',
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
                _loadRoles();
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
                      builder: (context) => const AdminRoleDetailsScreen(),
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
        child: LoadError(message: _loadError!, onRetry: _loadRoles),
      );
    }
    if (_roles.isEmpty) {
      return const Expanded(
        child: Center(child: Text('Nema uloga za prikaz.')),
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
            rows: _roles.map((role) {
              final isSystem = RoleProvider.isSystemRole(role);
              return DataRow(
                cells: [
                  DataCell(Text(role.name ?? '')),
                  DataCell(Text(role.description ?? '')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          color: Colors.blue,
                          tooltip: isSystem ? 'Sistemska uloga' : 'Uredi',
                          onPressed: isSystem || _isMutating
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AdminRoleDetailsScreen(role: role),
                                  ),
                                ).then((_) => _loadRoles()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          tooltip: isSystem ? 'Sistemska uloga' : 'Obriši',
                          onPressed: isSystem || _isMutating
                              ? null
                              : () => _confirmDelete(role),
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
