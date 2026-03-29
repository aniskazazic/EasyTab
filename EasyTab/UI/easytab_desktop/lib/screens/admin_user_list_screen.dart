import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/user.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:easytab_desktop/screens/admin_user_list_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:easytab_desktop/screens/admin_add_user_screen.dart';
import 'package:provider/provider.dart';

class AdminUsersListScreen extends StatefulWidget {
  const AdminUsersListScreen({super.key});

  @override
  State<AdminUsersListScreen> createState() => _AdminUsersListScreenState();
}

class _AdminUsersListScreenState extends State<AdminUsersListScreen> {
  late UserProvider userProvider;

  List<User> _users = [];
  int _totalCount = 0;
  int _currentPage = 0;
  final int _pageSize = 10;

  final TextEditingController searchController = TextEditingController();
  bool showDeleted = false;
  bool isLoading = false;

  // Debounce za pretragu
  DateTime? _lastSearchTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userProvider = context.read<UserProvider>();
    _loadUsers();
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
        // Reset na prvu stranicu kad se mijenja pretraga
        setState(() => _currentPage = 0);
        _loadUsers();
      }
    });
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);

    try {
      final filter = {
        "Page": _currentPage,
        "PageSize": _pageSize,
        "IncludeTotalCount": true,
        if (searchController.text.isNotEmpty) "FTS": searchController.text,
        if (showDeleted) "IsDeleted": true,
      };

      var result = await userProvider.get(filter: filter);

      setState(() {
        _users = result.items ?? [];
        _totalCount = result.totalCount ?? 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  int get _totalPages => (_totalCount / _pageSize).ceil();

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;
    setState(() => _currentPage = page);
    _loadUsers();
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

  Future<void> _deleteUser(int id) async {
    try {
      await userProvider.delete(id);
      await _loadUsers();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _reactivateUser(User user) async {
    try {
      await userProvider.update(user.id!, {"isDeleted": false});
      await _loadUsers();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje korisnika'),
        content: Text(
          'Da li ste sigurni da želite obrisati ${user.firstName} ${user.lastName}?',
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
              _deleteUser(user.id!);
            },
            child: const Text('Obriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmReactivate(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reaktivacija korisnika'),
        content: Text(
          'Da li ste sigurni da želite reaktivirati ${user.firstName} ${user.lastName}?',
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
              _reactivateUser(user);
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
      title: 'Korisnici',
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
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Pretraga...',
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
              builder: (context) => AdminAddUserScreen(onSaved: _loadUsers),
            ),
          ),
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
            _loadUsers();
          },
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_users.isEmpty) {
      return const Expanded(
        child: Center(child: Text('Nema korisnika za prikaz.')),
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
              DataColumn(label: Text('Prezime')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Korisničko ime')),
              DataColumn(label: Text('Uloga')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Akcije')),
            ],
            rows: _users.map((user) {
              final isDeleted = user.isDeleted ?? false;
              final roles = user.userRoles?.isNotEmpty == true
                  ? user.userRoles!
                        .where((r) => r.role?.name != null)
                        .map((r) => r.role!.name!)
                        .join(', ')
                  : 'Korisnik';

              return DataRow(
                cells: [
                  DataCell(Text(user.firstName ?? '')),
                  DataCell(Text(user.lastName ?? '')),
                  DataCell(Text(user.email ?? '')),
                  DataCell(Text(user.username ?? '')),
                  DataCell(Text(roles)),
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdminUserDetailsScreen(user: user),
                                ),
                              ).then((_) => _loadUsers());
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            isDeleted ? Icons.restore : Icons.delete,
                            color: isDeleted ? Colors.green : Colors.red,
                          ),
                          tooltip: isDeleted ? 'Reaktiviraj' : 'Obriši',
                          onPressed: () => isDeleted
                              ? _confirmReactivate(user)
                              : _confirmDelete(user),
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
    // Koliko stranica prikazati oko trenutne
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
          // Info o ukupnom broju
          Text(
            'Ukupno: $_totalCount  |  Stranica ${_currentPage + 1} od $_totalPages',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(width: 24),

          // Prva stranica
          _pageButton(
            icon: Icons.first_page,
            onTap: _currentPage > 0 ? () => _goToPage(0) : null,
          ),

          // Prethodna stranica
          _pageButton(
            icon: Icons.chevron_left,
            onTap: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
          ),

          // Brojevi stranica
          for (int i = startPage; i <= endPage; i++) _pageNumberButton(i),

          // Sljedeća stranica
          _pageButton(
            icon: Icons.chevron_right,
            onTap: _currentPage < _totalPages - 1
                ? () => _goToPage(_currentPage + 1)
                : null,
          ),

          // Zadnja stranica
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
