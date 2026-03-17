import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/user.dart';
import 'package:easytab_desktop/models/search_result.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:easytab_desktop/screens/admin_user_list_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminUsersListScreen extends StatefulWidget {
  const AdminUsersListScreen({super.key});

  @override
  State<AdminUsersListScreen> createState() => _AdminUsersListScreenState();
}

class _AdminUsersListScreenState extends State<AdminUsersListScreen> {
  late UserProvider userProvider;

  // Svi korisnici sa backenda
  List<User> _allUsers = [];
  // Filtrirani korisnici za prikaz
  List<User> _displayUsers = [];

  final TextEditingController searchController = TextEditingController();
  bool showDeleted = false;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userProvider = context.read<UserProvider>();
    _loadUsers();
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

  // Dohvati SVE korisnike sa backenda
  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      var result = await userProvider.get(filter: {"RetrieveAll": true});

      setState(() {
        _allUsers = result.items ?? [];
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  // Filtriraj lokalno
  void _applyFilters() {
    final query = searchController.text.toLowerCase();

    setState(() {
      _displayUsers = _allUsers.where((user) {
        // Filter po showDeleted
        final deletedFilter = showDeleted ? true : !(user.isDeleted ?? false);

        // Filter po pretrazi
        final searchFilter =
            query.isEmpty ||
            (user.firstName?.toLowerCase().contains(query) ?? false) ||
            (user.lastName?.toLowerCase().contains(query) ?? false) ||
            (user.email?.toLowerCase().contains(query) ?? false) ||
            (user.username?.toLowerCase().contains(query) ?? false);

        return deletedFilter && searchFilter;
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
      await userProvider.update(user.id!, {
        "firstName": user.firstName,
        "lastName": user.lastName,
        "username": user.username,
        "email": user.email,
        "phoneNumber": user.phoneNumber ?? '',
        "isDeleted": false,
      });
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
              hintText:
                  'Pretraga po imenu, prezimenu, emailu, korisničkom imenu...',
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminUserDetailsScreen(),
              ),
            ).then((_) => _loadUsers());
          },
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
            });
            _applyFilters(); // Filtriraj lokalno
          },
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_displayUsers.isEmpty) {
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
            rows: _displayUsers.map((user) {
              final isDeleted = user.isDeleted ?? false;
              final role = user.userRoles?.isNotEmpty == true
                  ? user.userRoles!.first.role?.name ?? ''
                  : '';

              return DataRow(
                cells: [
                  DataCell(Text(user.firstName ?? '')),
                  DataCell(Text(user.lastName ?? '')),
                  DataCell(Text(user.email ?? '')),
                  DataCell(Text(user.username ?? '')),
                  DataCell(Text(role)),
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
}
