import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:flutter/material.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreen();
}

class _AdminUserListScreen extends State<AdminUserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showDeleted = false;

  // Demo podaci (zamijeni providerom kad bude spreman).
  final List<_UserRow> _allUsers = [
    _UserRow(
      ime: 'Admin',
      prezime: 'Admin',
      email: 'easytab@gmail.com',
      korisnickoIme: 'admin',
      grad: 'Mostar',
      uloga: 'Admin',
      status: _UserStatus.aktivan,
    ),
    _UserRow(
      ime: 'User',
      prezime: 'One',
      email: 'user@gmail.com',
      korisnickoIme: 'user',
      grad: 'Sarajevo',
      uloga: 'User',
      status: _UserStatus.aktivan,
    ),
    _UserRow(
      ime: 'Owner',
      prezime: 'Owner',
      email: 'owner@gmail.com',
      korisnickoIme: 'owner',
      grad: 'Zenica',
      uloga: 'Owner',
      status: _UserStatus.aktivan,
    ),
    _UserRow(
      ime: 'Worker',
      prezime: 'Worker',
      email: 'worker@gmail.com',
      korisnickoIme: 'worker',
      grad: 'Mostar',
      uloga: 'Worker',
      status: _UserStatus.izbrisan,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_UserRow> get _filteredUsers {
    final q = _searchController.text.trim().toLowerCase();

    Iterable<_UserRow> res = _allUsers;
    if (!_showDeleted) {
      res = res.where((u) => u.status != _UserStatus.izbrisan);
    }
    if (q.isNotEmpty) {
      res = res.where(
        (u) =>
            u.ime.toLowerCase().contains(q) ||
            u.prezime.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.korisnickoIme.toLowerCase().contains(q) ||
            u.grad.toLowerCase().contains(q) ||
            u.uloga.toLowerCase().contains(q),
      );
    }

    return res.toList();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Korisnici',
      child: Column(
        children: [
          _buildTopBar(),
          const SizedBox(height: 10),
          _buildShowDeletedRow(),
          const SizedBox(height: 10),
          Expanded(child: _buildTable(context)),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        SizedBox(
          width: 280,
          height: 34,
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Pretraga',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF1E40AF)),
              ),
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 34,
          width: 90,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // TODO: otvori formu za dodavanje korisnika
            },
            child: const Text(
              'Dodaj',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShowDeletedRow() {
    return Row(
      children: [
        const Text(
          'Prikaži izbrisane :',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: _showDeleted,
            onChanged: (v) => setState(() => _showDeleted = v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: const Color(0xFF1E40AF),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context) {
    final users = _filteredUsers;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 900),
          child: SingleChildScrollView(
            child: DataTableTheme(
              data: DataTableThemeData(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFF1E40AF),
                ),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                dataTextStyle: const TextStyle(fontSize: 12),
                dividerThickness: 1,
              ),
              child: DataTable(
                columnSpacing: 18,
                headingRowHeight: 38,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 46,
                columns: const [
                  DataColumn(label: Text('Ime')),
                  DataColumn(label: Text('Prezime')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Korisničko ime')),
                  DataColumn(label: Text('Grad')),
                  DataColumn(label: Text('Uloga')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Akcije')),
                ],
                rows: users
                    .map(
                      (u) => DataRow(
                        cells: [
                          DataCell(Text(u.ime)),
                          DataCell(Text(u.prezime)),
                          DataCell(Text(u.email)),
                          DataCell(Text(u.korisnickoIme)),
                          DataCell(Text(u.grad)),
                          DataCell(Text(u.uloga)),
                          DataCell(_statusChip(u.status)),
                          DataCell(_actionsCell(u)),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(_UserStatus s) {
    final text = s == _UserStatus.aktivan ? 'Aktivan' : 'Izbrisan';
    final color = s == _UserStatus.aktivan ? Colors.green : Colors.red;
    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
    );
  }

  Widget _actionsCell(_UserRow u) {
    final isDeleted = u.status == _UserStatus.izbrisan;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Uredi',
          iconSize: 18,
          splashRadius: 18,
          onPressed: isDeleted
              ? null
              : () {
                  // TODO: otvori edit formu
                },
          icon: Icon(
            Icons.edit,
            color: isDeleted ? Colors.grey.shade400 : Colors.black54,
          ),
        ),
        IconButton(
          tooltip: isDeleted ? 'Vrati' : 'Obriši',
          iconSize: 18,
          splashRadius: 18,
          onPressed: () {
            setState(() {
              final idx = _allUsers.indexOf(u);
              if (idx == -1) return;
              _allUsers[idx] = u.copyWith(
                status: isDeleted ? _UserStatus.aktivan : _UserStatus.izbrisan,
              );
            });
          },
          icon: Icon(
            isDeleted ? Icons.restore : Icons.delete,
            color: isDeleted ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}

enum _UserStatus { aktivan, izbrisan }

class _UserRow {
  const _UserRow({
    required this.ime,
    required this.prezime,
    required this.email,
    required this.korisnickoIme,
    required this.grad,
    required this.uloga,
    required this.status,
  });

  final String ime;
  final String prezime;
  final String email;
  final String korisnickoIme;
  final String grad;
  final String uloga;
  final _UserStatus status;

  _UserRow copyWith({_UserStatus? status}) {
    return _UserRow(
      ime: ime,
      prezime: prezime,
      email: email,
      korisnickoIme: korisnickoIme,
      grad: grad,
      uloga: uloga,
      status: status ?? this.status,
    );
  }
}
