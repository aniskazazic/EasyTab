import 'package:easytab_desktop/widgets/load_error.dart';
import 'package:easytab_desktop/exceptions/api_exception.dart';
import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/reservation.dart';
import 'package:easytab_desktop/providers/notification_provider.dart';
import 'package:easytab_desktop/providers/reservation_provider.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:easytab_desktop/widgets/owner_sidebar.dart';
import 'package:easytab_desktop/widgets/cancellation_reason_dialog.dart';
import 'package:easytab_desktop/widgets/reservation_filters.dart';
import 'package:easytab_desktop/widgets/reservations_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OwnerReservationsScreen extends StatefulWidget {
  final int localeId;
  final String localeName;
  final Function(int localeId, String section)? onSectionTap;
  final VoidCallback? onRefresh;

  const OwnerReservationsScreen({
    super.key,
    required this.localeId,
    required this.localeName,
    this.onSectionTap,
    this.onRefresh,
  });

  @override
  State<OwnerReservationsScreen> createState() =>
      _OwnerReservationsScreenState();
}

class _OwnerReservationsScreenState extends State<OwnerReservationsScreen> {
  bool isLoading = true;
  String? _loadError;
  int _loadVersion = 0;
  final Set<int> _cancelling = {};
  String? _selectedPaymentStatus;
  String? _appliedPaymentStatus;
  late ReservationProvider _reservationProvider;
  late NotificationProvider _notificationProvider;
  int _lastNotificationRefreshVersion = 0;
  int _totalCount = 0;
  int _currentPage = 0;
  final int _pageSize = 10;

  List<Reservation> _reservations = [];
  bool _initialized = false;

  DateTime? _selectedDate;
  String? _selectedState = 'Sva stanja';

  String _appliedQuery = '';
  DateTime? _appliedDate;
  String? _appliedState;

  final TextEditingController searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reservationProvider = context.read<ReservationProvider>();
    _notificationProvider = context.read<NotificationProvider>();
    if (!_initialized) {
      _initialized = true;
      _notificationProvider.addListener(_onNotificationReceived);
      _loadReservations();
    }
  }

  @override
  void didUpdateWidget(covariant OwnerReservationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localeId != widget.localeId) {
      _currentPage = 0;
      _loadReservations();
    }
  }

  @override
  void dispose() {
    _notificationProvider.removeListener(_onNotificationReceived);
    searchController.dispose();
    super.dispose();
  }

  void _onNotificationReceived() {
    final version = _notificationProvider.reservationRefreshVersion;
    if (version == _lastNotificationRefreshVersion) return;
    _lastNotificationRefreshVersion = version;
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    if (!mounted) return;
    final loadVersion = ++_loadVersion;
    setState(() {
      isLoading = true;
      _loadError = null;
    });
    try {
      final result = await _reservationProvider.getReservations(
        page: _currentPage + 1,
        pageSize: _pageSize,
        searchTerm: _appliedQuery,
        localeId: widget.localeId,
        reservationState: _appliedState,
        reservationDate: _appliedDate,
        paymentStatus: _appliedPaymentStatus,
      );
      if (!mounted || loadVersion != _loadVersion) return;
      setState(() {
        _reservations = result.items ?? [];
        _totalCount = result.totalCount ?? _reservations.length;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted || loadVersion != _loadVersion) return;
      setState(() {
        isLoading = false;
        _loadError = 'Greška pri učitavanju podataka: $e';
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _appliedQuery = searchController.text.trim();
      _appliedState = _selectedState;
      _appliedPaymentStatus = _selectedPaymentStatus;
      _appliedDate = _selectedDate;
      _currentPage = 0;
    });
    _loadReservations();
  }

  void _clearFilters() {
    setState(() {
      searchController.clear();
      _selectedState = 'Sva stanja';
      _selectedDate = null;
      _selectedPaymentStatus = null;
      _appliedQuery = '';
      _appliedState = null;
      _appliedPaymentStatus = null;
      _appliedDate = null;
      _currentPage = 0;
    });
    _loadReservations();
  }

  Future<void> _confirmReservation(Reservation reservation) async {
    if (reservation.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Potvrda rezervacije')),
            IconButton(
              tooltip: 'Zatvori',
              onPressed: () => Navigator.pop(ctx, false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: Text(
          'Želite li potvrditi rezervaciju za stol "${reservation.tableName ?? 'Stol'}"?',
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
      await _reservationProvider.confirmReservation(reservation.id!);
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

  Future<void> _completeReservation(Reservation reservation) async {
    if (reservation.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Završi rezervaciju')),
            IconButton(
              tooltip: 'Zatvori',
              onPressed: () => Navigator.pop(ctx, false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: Text(
          'Želite li označiti rezervaciju za stol "${reservation.tableName ?? 'Stol'}" kao završenu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
            ),
            child: const Text('Završi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _reservationProvider.completeReservation(reservation.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezervacija je uspješno označena kao završena!'),
            backgroundColor: Color(0xFF1E40AF),
          ),
        );
        _loadReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelReservation(Reservation reservation) async {
    if (reservation.id == null || _cancelling.contains(reservation.id)) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => CancellationReasonDialog(
        description:
            'Unesite razlog otkazivanja rezervacije za stol "${reservation.tableName ?? 'Stol'}":',
        hint: 'Npr. Popunjen kapacitet, radovi u lokalu...',
        refundMessage: reservation.isPaid
            ? 'Otkazivanjem slijedi povrat ${reservation.paidAmountKm?.toStringAsFixed(2) ?? "-"} KM korisniku.'
            : null,
      ),
    );
    if (!mounted || reason == null) return;
    try {
      setState(() => _cancelling.add(reservation.id!));
      await _reservationProvider.cancelReservation(reservation.id!, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reservation.isPaid
                  ? 'Rezervacija je otkazana. Izvršen je povrat novca korisniku.'
                  : 'Rezervacija je uspješno otkazana.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        _loadReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiClientException
                  ? e.message
                  : 'Nije moguće otkazati rezervaciju. Pokušajte ponovo.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling.remove(reservation.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Rezervacije - ${widget.localeName}',
      sidebar: OwnerSidebar(
        activeLocaleId: widget.localeId,
        onSectionTap: widget.onSectionTap,
        onRefresh: widget.onRefresh,
      ),
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
          if (!isLoading && _loadError == null)
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

  Widget _buildSearchAndFilter() => ReservationFilters(
    searchController: searchController,
    state: _selectedState,
    paymentStatus: _selectedPaymentStatus,
    date: _selectedDate,
    expandToFill: true,
    hasAppliedFilters:
        _appliedQuery.isNotEmpty ||
        (_appliedState != null && _appliedState != 'Sva stanja') ||
        _appliedPaymentStatus != null ||
        _appliedDate != null,
    onStateChanged: (value) {
      setState(() => _selectedState = value);
    },
    onPaymentStatusChanged: (value) {
      setState(() => _selectedPaymentStatus = value);
    },
    onDateChanged: (value) {
      setState(() => _selectedDate = value);
    },
    onApply: _applyFilters,
    onClear: _clearFilters,
  );

  Widget _buildTable() => Expanded(
    child: _loadError != null
        ? LoadError(message: _loadError!, onRetry: _loadReservations)
        : ReservationsTable(
            reservations: _reservations,
            showLocale: false,
            buildActions: _buildRowActions,
          ),
  );

  Widget _buildRowActions(Reservation res) {
    if (_cancelling.contains(res.id)) {
      return const Tooltip(
        message: 'Otkazivanje i povrat uplate su u toku.',
        child: IconButton(onPressed: null, icon: Icon(Icons.hourglass_top)),
      );
    }
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
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.task_alt, color: Color(0xFF1E40AF)),
            tooltip: 'Završi rezervaciju',
            onPressed: () => _completeReservation(res),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            tooltip: 'Otkaži rezervaciju',
            onPressed: () => _cancelReservation(res),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
