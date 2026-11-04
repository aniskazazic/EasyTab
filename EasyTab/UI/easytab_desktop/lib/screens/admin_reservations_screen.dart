import 'package:easytab_desktop/widgets/load_error.dart';
import 'package:easytab_desktop/exceptions/api_exception.dart';
import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/locale.dart' as model;
import 'package:easytab_desktop/models/reservation.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/providers/notification_provider.dart';
import 'package:easytab_desktop/providers/reservation_provider.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:easytab_desktop/widgets/cancellation_reason_dialog.dart';
import 'package:easytab_desktop/widgets/reservation_filters.dart';
import 'package:easytab_desktop/widgets/reservations_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() =>
      _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  bool isLoading = true;
  String? _loadError;
  int _loadVersion = 0;
  final Set<int> _processing = {};
  String? _selectedPaymentStatus;
  String? _appliedPaymentStatus;
  late ReservationProvider _reservationProvider;
  late LocaleProvider _localeProvider;
  late NotificationProvider _notificationProvider;
  int _lastNotificationRefreshVersion = 0;

  int _totalCount = 0;
  int _currentPage = 0;
  final int _pageSize = 10;

  List<Reservation> _reservations = [];
  List<model.Locale> _locales = [];
  bool _isLoadingLocales = true;
  String? _localeLoadError;
  bool _initialized = false;

  DateTime? _selectedDate;
  String? _selectedState = 'Sva stanja';
  int? _selectedLocaleId;

  String _appliedQuery = '';
  DateTime? _appliedDate;
  String? _appliedState;
  int? _appliedLocaleId;

  final TextEditingController searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reservationProvider = context.read<ReservationProvider>();
    _localeProvider = context.read<LocaleProvider>();
    _notificationProvider = context.read<NotificationProvider>();
    if (!_initialized) {
      _initialized = true;
      _notificationProvider.addListener(_onNotificationReceived);
      _loadInitial();
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

  Future<void> _loadInitial() async {
    await Future.wait([_loadLocales(), _loadReservations()]);
  }

  Future<void> _loadLocales() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocales = true;
      _localeLoadError = null;
    });
    try {
      final locales = await _localeProvider.getForReservationFilter();
      if (mounted) {
        setState(() {
          _locales = locales;
          _isLoadingLocales = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocales = false;
        _localeLoadError = 'Greška pri učitavanju lokala: ${userError(e)}';
      });
    }
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
        localeId: _appliedLocaleId,
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
        _loadError = 'Greška pri učitavanju podataka: ${userError(e)}';
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _appliedQuery = searchController.text.trim();
      _appliedLocaleId = _selectedLocaleId;
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
      _selectedLocaleId = null;
      _selectedState = 'Sva stanja';
      _selectedDate = null;
      _selectedPaymentStatus = null;
      _appliedQuery = '';
      _appliedLocaleId = null;
      _appliedState = null;
      _appliedPaymentStatus = null;
      _appliedDate = null;
      _currentPage = 0;
    });
    _loadReservations();
  }

  Future<void> _confirmReservation(Reservation reservation) async {
    if (reservation.id == null || _processing.contains(reservation.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda rezervacije'),
        content: Text(
          'Želite li potvrditi rezervaciju za "${reservation.localeName ?? 'Lokal'}"?',
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

    if (confirmed != true || !mounted || _processing.contains(reservation.id)) {
      return;
    }
    setState(() => _processing.add(reservation.id!));

    try {
      await _reservationProvider.confirmReservation(reservation.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezervacija je uspješno potvrđena!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        await _loadReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri potvrđivanju: ${userError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing.remove(reservation.id));
    }
  }

  Future<void> _cancelReservation(Reservation reservation) async {
    if (reservation.id == null || _processing.contains(reservation.id)) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => CancellationReasonDialog(
        description:
            'Unesite razlog otkazivanja rezervacije za "${reservation.localeName ?? 'Lokal'}":',
        hint: 'Npr. Otkazano zbog tehničkog problema...',
        refundMessage: reservation.isPaid
            ? 'Otkazivanjem slijedi povrat ${reservation.paidAmountKm?.toStringAsFixed(2) ?? "-"} KM korisniku.'
            : null,
      ),
    );
    if (!mounted || reason == null || _processing.contains(reservation.id)) {
      return;
    }
    try {
      setState(() => _processing.add(reservation.id!));
      await _reservationProvider.cancelReservation(reservation.id!, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reservation.isPaid
                  ? 'Rezervacija je otkazana. Povrat uplate je pokrenut.'
                  : 'Rezervacija je uspješno otkazana.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiClientException
                  ? userError(e)
                  : 'Nije moguće otkazati rezervaciju. Pokušajte ponovo.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing.remove(reservation.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Rezervacije',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingLocales) const LinearProgressIndicator(),
          if (_localeLoadError != null)
            LoadError(message: _localeLoadError!, onRetry: _loadLocales),
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
    locales: _locales,
    localeId: _selectedLocaleId,
    state: _selectedState,
    paymentStatus: _selectedPaymentStatus,
    date: _selectedDate,
    hasAppliedFilters:
        _appliedQuery.isNotEmpty ||
        _appliedLocaleId != null ||
        (_appliedState != null && _appliedState != 'Sva stanja') ||
        _appliedPaymentStatus != null ||
        _appliedDate != null,
    onLocaleChanged: (value) {
      setState(() => _selectedLocaleId = value);
    },
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
            showLocale: true,
            buildActions: _buildRowActions,
          ),
  );

  Widget _buildRowActions(Reservation res) {
    if (_processing.contains(res.id)) {
      return const Tooltip(
        message: 'Obrada rezervacije je u toku.',
        child: IconButton(
          onPressed: null,
          icon: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
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
      return IconButton(
        icon: const Icon(Icons.cancel, color: Colors.red),
        tooltip: 'Otkaži rezervaciju',
        onPressed: () => _cancelReservation(res),
      );
    }

    return const SizedBox.shrink();
  }
}
