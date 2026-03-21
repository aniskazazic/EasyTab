import 'package:easytab_desktop/models/worker.dart';
import 'package:easytab_desktop/providers/worker_provider.dart';
import 'package:easytab_desktop/screens/owner_worker_details_screen.dart';
import 'package:easytab_desktop/widgets/owner_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OwnerWorkersScreen extends StatefulWidget {
  final int localeId;
  final String localeName;
  final Function(int localeId, String section)? onSectionTap;
  final VoidCallback? onRefresh;

  const OwnerWorkersScreen({
    super.key,
    required this.localeId,
    required this.localeName,
    this.onSectionTap,
    this.onRefresh,
  });

  @override
  State<OwnerWorkersScreen> createState() => _OwnerWorkersScreenState();
}

class _OwnerWorkersScreenState extends State<OwnerWorkersScreen> {
  late WorkerProvider workerProvider;
  List<Worker> _allWorkers = [];
  List<Worker> _displayWorkers = [];
  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    workerProvider = context.read<WorkerProvider>();
    searchController.addListener(_applyFilters);
    _loadWorkers();
  }

  @override
  void dispose() {
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    setState(() => isLoading = true);
    try {
      final workers = await workerProvider.getByLocale(widget.localeId);
      setState(() {
        _allWorkers = workers;
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
      _displayWorkers = _allWorkers.where((w) {
        return query.isEmpty ||
            ('${w.firstName} ${w.lastName}'.toLowerCase().contains(query)) ||
            (w.username?.toLowerCase().contains(query) ?? false) ||
            (w.email?.toLowerCase().contains(query) ?? false) ||
            (w.phoneNumber?.toLowerCase().contains(query) ?? false);
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

  void _confirmDelete(Worker worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje radnika'),
        content: Text(
          'Da li ste sigurni da želite obrisati radnika ${worker.firstName} ${worker.lastName}?',
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
                await workerProvider.delete(worker.id!);
                await _loadWorkers();
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
    return Scaffold(
      body: Row(
        children: [
          OwnerSidebar(
            activeLocaleId: widget.localeId,
            onSectionTap: widget.onSectionTap,
            onRefresh: widget.onRefresh,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Nazad'),
                        ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Radnici',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Pregled radnika za ${widget.localeName}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pretraga i Dodaj
                  Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OwnerWorkerDetailsScreen(
                              localeId: widget.localeId,
                              onSaved: _loadWorkers,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Dodaj',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tabela
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_displayWorkers.isEmpty) {
      return const Expanded(
        child: Center(child: Text('Nema radnika za prikaz.')),
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
              DataColumn(label: Text('Ime i prezime')),
              DataColumn(label: Text('Korisničko ime')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Broj telefona')),
              DataColumn(label: Text('Akcija')),
            ],
            rows: _displayWorkers.map((worker) {
              return DataRow(
                cells: [
                  DataCell(
                    Text('${worker.firstName ?? ''} ${worker.lastName ?? ''}'),
                  ),
                  DataCell(Text(worker.username ?? '')),
                  DataCell(Text(worker.email ?? '')),
                  DataCell(Text(worker.phoneNumber ?? '')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Uredi',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OwnerWorkerDetailsScreen(
                                localeId: widget.localeId,
                                worker: worker,
                                onSaved: _loadWorkers,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Obriši',
                          onPressed: () => _confirmDelete(worker),
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
