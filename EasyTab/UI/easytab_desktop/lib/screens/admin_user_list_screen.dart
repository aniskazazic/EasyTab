import 'package:easytab_desktop/widgets/load_error.dart';
import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/user.dart';
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:easytab_desktop/screens/admin_user_list_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:easytab_desktop/screens/admin_add_user_screen.dart';
import 'package:easytab_desktop/providers/utils.dart';
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
  bool isLoading = true;
  bool _isMutating = false;
  String? _loadError;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    userProvider = context.read<UserProvider>();
    _loadUsers();
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
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
      _loadError = null;
    });

    try {
      final filter = {
        "Page": _currentPage + 1,
        "PageSize": _pageSize,
        "IncludeTotalCount": true,
        "ExcludeCurrentUser": true,
        if (searchController.text.isNotEmpty) "FTS": searchController.text,
        "IsDeleted": showDeleted,
      };

      var result = await userProvider.get(filter: filter);

      if (!mounted) return;
      setState(() {
        _users = result.items ?? [];
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

  Future<void> _deleteUser(int id) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      await userProvider.delete(id);
      if (!mounted) return;
      showFeedback(context, 'Korisnik je uspješno obrisan.');
      await _loadUsers();
    } catch (e) {
      if (mounted) _showError(userError(e));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _reactivateUser(User user) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      await userProvider.update(user.id!, {
        "username": user.username,
        "isDeleted": false,
      });
      if (!mounted) return;
      showFeedback(context, 'Korisnik je uspješno reaktiviran.');
      await _loadUsers();
    } catch (e) {
      if (mounted) _showError(userError(e));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _confirmDelete(User user) {
    if (_isMutating) return;
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
    if (_isMutating) return;
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
                _loadUsers();
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AdminAddUserScreen(onSaved: _onSearchPressed),
              ),
            ),
            child: const Text('Dodaj', style: TextStyle(color: Colors.white)),
          ),
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
          },
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_loadError != null) {
      return Expanded(
        child: LoadError(message: _loadError!, onRetry: _loadUsers),
      );
    }
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
              final isProtected =
                  user.id == AuthProvider.currentUser?.id ||
                  (user.userRoles?.any((role) => role.role?.name == 'Admin') ??
                      false);
              final protectedReason = user.id == AuthProvider.currentUser?.id
                  ? 'Vlastiti profil uređujete kroz Postavke.'
                  : 'Akcije nad administratorskim nalozima nisu dozvoljene.';
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
                            icon: const Icon(Icons.edit),
                            color: Colors.blue,
                            tooltip: isProtected ? protectedReason : 'Uredi',
                            onPressed: isProtected || _isMutating
                                ? null
                                : () {
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
                          icon: Icon(isDeleted ? Icons.restore : Icons.delete),
                          color: isDeleted ? Colors.green : Colors.red,
                          tooltip: isProtected
                              ? protectedReason
                              : isDeleted
                              ? 'Reaktiviraj'
                              : 'Obriši',
                          onPressed: isProtected || _isMutating
                              ? null
                              : () => isDeleted
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
}
