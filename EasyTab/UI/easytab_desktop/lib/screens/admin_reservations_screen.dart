import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/locale.dart' as model;
import 'package:easytab_desktop/models/reservation.dart';
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/providers/reservation_provider.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() =>
      _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  bool isLoading = false;
  late ReservationProvider _reservationProvider;
  late LocaleProvider _localeProvider;

  int _totalCount = 0;
  int _currentPage = 0;
  final int _pageSize = 10;

  List<Reservation> _reservations = [];
  List<model.Locale> _locales = [];
  bool _initialized = false;

  DateTime? _selectedDate;
  String? _selectedState = 'Sva stanja';
  int? _selectedLocaleId;

  String _appliedQuery = '';
  DateTime? _appliedDate;
  String? _appliedState;
  int? _appliedLocaleId;

  final TextEditingController searchController = TextEditingController();

  final List<String> _states = [
    'Sva stanja',
    'Na čekanju',
    'Potvrđena',
    'Završena',
    'Otkazana',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reservationProvider = context.read<ReservationProvider>();
    _localeProvider = context.read<LocaleProvider>();
    if (!_initialized) {
      _initialized = true;
      _loadInitial();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await Future.wait([_loadLocales(), _loadReservations()]);
  }

  Future<void> _loadLocales() async {
    try {
      final res = await _localeProvider.get();
      if (mounted) {
        setState(() {
          _locales = res.items ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading locales: $e');
    }
  }

  Future<void> _loadReservations() async {
    setState(() => isLoading = true);
    try {
      final filter = <String, dynamic>{
        'Page': _currentPage + 1,
        'PageSize': _pageSize,
        'IncludeTotalCount': true,
      };

      if (_appliedLocaleId != null) {
        filter['LocaleId'] = _appliedLocaleId;
      }

      if (_appliedState != null && _appliedState != 'Sva stanja') {
        filter['ReservationState'] = _appliedState;
      }

      final result = await _reservationProvider.get(filter: filter);
      if (mounted) {
        setState(() {
          _reservations = result.items ?? [];
          _totalCount = result.totalCount ?? _reservations.length;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reservations: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri učitavanju rezervacija: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _appliedQuery = searchController.text.trim().toLowerCase();
      _appliedLocaleId = _selectedLocaleId;
      _appliedState = _selectedState;
      _appliedDate = _selectedDate;
      _currentPage = 0;
    });
    _loadReservations();
  }

  void _clearFilters() {
    setState(() {
      searchController.clear();
      _selectedLocaleId = null;
      _selectedState = 'Sva stanja';
      _selectedDate = null;
      _appliedQuery = '';
      _appliedLocaleId = null;
      _appliedState = null;
      _appliedDate = null;
      _currentPage = 0;
    });
    _loadReservations();
  }

  List<Reservation> get _filteredReservations {
    var list = _reservations;

    if (_appliedQuery.isNotEmpty) {
      list = list.where((r) {
        final table = (r.tableName ?? '').toLowerCase();
        final locale = (r.localeName ?? '').toLowerCase();
        final guests = (r.numberOfGuests?.toString() ?? '');
        return table.contains(_appliedQuery) ||
            locale.contains(_appliedQuery) ||
            guests.contains(_appliedQuery);
      }).toList();
    }

    if (_appliedDate != null) {
      list = list.where((r) {
        if (r.reservationDate == null) return false;
        return r.reservationDate!.year == _appliedDate!.year &&
            r.reservationDate!.month == _appliedDate!.month &&
            r.reservationDate!.day == _appliedDate!.day;
      }).toList();
    }

    return list;
  }

  Future<void> _confirmReservation(Reservation reservation) async {
    final currentUserId =
        int.tryParse(AuthProvider.accessTokenDecoded?['Id'] ?? '0') ?? 0;
    if (reservation.id == null || currentUserId == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda rezervacije'),
        content: Text(
          'Želite li potvrditi rezervaciju #${reservation.id} za "${reservation.localeName ?? 'Lokal'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
            ),
            child: const Text('Potvrdi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _reservationProvider.confirmReservation(
        reservation.id!,
        currentUserId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezervacija je uspješno potvrđena!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        _loadReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri potvrđivanju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelReservation(Reservation reservation) async {
    final currentUserId =
        int.tryParse(AuthProvider.accessTokenDecoded?['Id'] ?? '0') ?? 0;
    if (reservation.id == null || currentUserId == 0) return;

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Otkaži rezervaciju'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unesite razlog otkazivanja rezervacije #${reservation.id} za "${reservation.localeName ?? 'Lokal'}":',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Npr. Otkazano od strane administratora...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Otkaži rezervaciju',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final reason = reasonController.text.trim().isNotEmpty
        ? reasonController.text.trim()
        : 'Otkazano od strane administratora';

    try {
      await _reservationProvider.cancelReservation(
        reservation.id!,
        reason,
        currentUserId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezervacija je uspješno otkazana.'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri otkazivanju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Rezervacije',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchAndFilter(),
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
                _loadReservations();
              },
              pageButtonSize: 36,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Pretraži po lokalu, stolu...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _applyFilters(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int?>(
            // ignore: deprecated_member_use
            value: _selectedLocaleId,
            decoration: InputDecoration(
              labelText: 'Lokal',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Svi lokali')),
              ..._locales.map((l) {
                return DropdownMenuItem(value: l.id, child: Text(l.name ?? ''));
              }),
            ],
            onChanged: (val) {
              setState(() {
                _selectedLocaleId = val;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _selectedState,
            decoration: InputDecoration(
              labelText: 'Stanje',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: _states.map((s) {
              return DropdownMenuItem(value: s, child: Text(s));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedState = val ?? 'Sva stanja';
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _selectedDate != null
                  ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
                  : 'Svi datumi',
            ),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _applyFilters,
          ),
        ),
        if (_selectedDate != null ||
            _selectedLocaleId != null ||
            (_selectedState != null && _selectedState != 'Sva stanja') ||
            searchController.text.isNotEmpty) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Poništi filtere',
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: _clearFilters,
          ),
        ],
      ],
    );
  }

  Widget _buildTable() {
    final list = _filteredReservations;

    if (list.isEmpty) {
      return const Expanded(
        child: Center(child: Text('Nema rezervacija za prikaz.')),
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
              DataColumn(label: Text('Lokal')),
              DataColumn(label: Text('Stol')),
              DataColumn(label: Text('Gosti')),
              DataColumn(label: Text('Datum')),
              DataColumn(label: Text('Termin')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Akcija')),
            ],
            rows: list.map((res) {
              final dateStr = res.reservationDate != null
                  ? DateFormat('dd.MM.yyyy').format(res.reservationDate!)
                  : '-';
              final timeStr =
                  '${_formatTime(res.startTime)} - ${_formatTime(res.endTime)}';

              return DataRow(
                cells: [
                  DataCell(Text(res.localeName ?? '-')),
                  DataCell(Text(res.tableName ?? '-')),
                  DataCell(Text('${res.numberOfGuests ?? '-'}')),
                  DataCell(Text(dateStr)),
                  DataCell(Text(timeStr)),
                  DataCell(
                    _buildStatusBadge(res.reservationState ?? 'Na čekanju'),
                  ),
                  DataCell(_buildRowActions(res)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRowActions(Reservation res) {
    final state = (res.reservationState ?? '').toLowerCase();

    if (state == 'na čekanju') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
            tooltip: 'Potvrdi rezervaciju',
            onPressed: () => _confirmReservation(res),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            tooltip: 'Otkaži rezervaciju',
            onPressed: () => _cancelReservation(res),
          ),
        ],
      );
    } else if (state == 'potvrđena' || state == 'potvrdena') {
      return IconButton(
        icon: const Icon(Icons.cancel, color: Colors.red),
        tooltip: 'Otkaži rezervaciju',
        onPressed: () => _cancelReservation(res),
      );
    } else if (state == 'otkazana' &&
        (res.cancellationReason ?? '').isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.info_outline, color: Colors.grey),
        tooltip: 'Razlog: ${res.cancellationReason}',
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Razlog otkazivanja'),
              content: Text(res.cancellationReason!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Zatvori'),
                ),
              ],
            ),
          );
        },
      );
    }

    return const Text('-', style: TextStyle(color: Colors.grey));
  }

  Widget _buildStatusBadge(String state) {
    Color bg;
    Color text;
    IconData icon;

    final lower = state.toLowerCase();
    if (lower == 'na čekanju') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFB45309);
      icon = Icons.hourglass_top_rounded;
    } else if (lower == 'potvrđena' || lower == 'potvrdena') {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF15803D);
      icon = Icons.check_circle_rounded;
    } else if (lower == 'završena' || lower == 'zavrsena') {
      bg = const Color(0xFFDBEAFE);
      text = const Color(0xFF1E40AF);
      icon = Icons.task_alt_rounded;
    } else if (lower == 'otkazana') {
      bg = const Color(0xFFFFE4E6);
      text = const Color(0xFFBE123C);
      icon = Icons.cancel_rounded;
    } else {
      bg = const Color(0xFFF1F5F9);
      text = const Color(0xFF475569);
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(
            state,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return time;
  }
}
