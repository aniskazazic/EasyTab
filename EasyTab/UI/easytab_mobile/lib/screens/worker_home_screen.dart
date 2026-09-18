import 'package:easytab_mobile/models/reservation.dart';
import 'package:easytab_mobile/providers/owner_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:easytab_mobile/screens/worker_reservation_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime _searchedDate = DateTime.now();
  String _searchedQuery = '';
  List<Reservation> _reservations = [];
  int _currentPage = 0;
  int _totalCount = 0;
  static const int _pageSize = 5;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations({int page = 0}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await context.read<OwnerProvider>().getReservations(
        date: _searchedDate,
        query: _searchedQuery,
        page: page,
        pageSize: _pageSize,
      );
      if (mounted) {
        setState(() {
          _reservations = result.items ?? [];
          _totalCount = result.totalCount ?? 0;
          _currentPage = page;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Greška pri učitavanju rezervacija.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applySearch() async {
    _searchedDate = _selectedDate;
    _searchedQuery = _searchController.text.trim();
    await _loadReservations();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(34, 36, 22, 30),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    maxLength: 50,
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    decoration: InputDecoration(
                      hintText: 'Pretraga',
                      prefixIcon: const Icon(Icons.search),
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFE0E0E0),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(color: Colors.black54),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 13,
                    ),
                    side: const BorderSide(color: Colors.black54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(34, 0, 22, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _applySearch,
                icon: const Icon(Icons.search),
                label: const Text('Pretraži'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                if (!_isLoading && _error == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pronađeno: $_totalCount ${_reservationLabel(_totalCount)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Expanded(child: _buildReservations()),
                if (!_isLoading && _error == null)
                  PaginationUtils.buildPageControls(
                    currentPage: _currentPage,
                    totalCount: _totalCount,
                    pageSize: _pageSize,
                    onPageChanged: (page) => _loadReservations(page: page),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservations() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_reservations.isEmpty) {
      final query = _searchedQuery;
      final date = DateFormat('dd.MM.yyyy').format(_searchedDate);
      final message = query.isEmpty
          ? 'Nema rezervacija za datum $date.'
          : 'Nema rezervacija za "$query" na datum $date.';
      return Center(child: Text(message, textAlign: TextAlign.center));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: _reservations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) =>
          _ReservationCard(reservation: _reservations[index]),
    );
  }

  String _reservationLabel(int count) {
    if (count == 1) return 'rezervacija';
    if (count >= 2 && count <= 4) return 'rezervacije';
    return 'rezervacija';
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(3, 4), blurRadius: 3),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation.customerName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(Icons.access_time, size: 20),
              const SizedBox(width: 10),
              Text(
                '${_formatTime(reservation.startTime)} - ${_formatTime(reservation.endTime)}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.group_outlined, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${reservation.numberOfGuests ?? 0} osoba',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.table_restaurant_outlined, size: 20),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              reservation.tableName ?? 'Stol',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerReservationDetailsScreen(
                        reservation: reservation,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Detalji',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF1E40AF),
                        size: 21,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '--:--';
    return value.length >= 5 ? value.substring(0, 5) : value;
  }
}
