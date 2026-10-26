import 'package:easytab_mobile/models/reservation.dart';
import 'package:easytab_mobile/providers/owner_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:easytab_mobile/screens/worker_reservation_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/providers/notification_provider.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';

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
  int _requestVersion = 0;
  late NotificationProvider _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = context.read<NotificationProvider>();
    _notifications.addListener(_onNotification);
    _loadReservations();
  }

  @override
  void dispose() {
    _notifications.removeListener(_onNotification);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations({int page = 0}) async {
    final version = ++_requestVersion;
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
      if (!mounted || version != _requestVersion) return;
      if (page > 0 && (result.items?.isEmpty ?? true)) {
        await _loadReservations();
        return;
      }
      if (mounted && version == _requestVersion) {
        setState(() {
          _reservations = result.items ?? [];
          _totalCount = result.totalCount ?? 0;
          _currentPage = page;
        });
      }
    } catch (e) {
      if (mounted && version == _requestVersion) {
        setState(() => _error = userError(e));
      }
    } finally {
      if (mounted && version == _requestVersion) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onNotification() {
    if (mounted) _loadReservations(page: _currentPage);
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
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: RefreshIndicator(
      onRefresh: () => _loadReservations(page: _currentPage),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 36, 22, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: TextField(
                          onSubmitted: (_) => _applySearch(),
                          controller: _searchController,
                          maxLength: 50,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Pretraga',
                            prefixIcon: const Icon(Icons.search),
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFE0E0E0),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        label: Text(formatDateOnly(_selectedDate)),
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
                if (!_isLoading && _error == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pronađeno: $_totalCount ${_reservationLabel(_totalCount)}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => _loadReservations(page: _currentPage),
                      child: const Text('Pokušaj ponovo'),
                    ),
                  ],
                ),
              ),
            )
          else if (_reservations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  _searchedQuery.isEmpty
                      ? 'Nema rezervacija za datum ${DateFormat('dd.MM.yyyy').format(_searchedDate)}.'
                      : 'Nema rezervacija za "$_searchedQuery" na datum ${DateFormat('dd.MM.yyyy').format(_searchedDate)}.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReservationCard(
                      reservation: _reservations[index],
                      onReservationChanged: () =>
                          _loadReservations(page: _currentPage),
                    ),
                  ),
                  childCount: _reservations.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: PaginationUtils.buildPageControls(
                currentPage: _currentPage,
                totalCount: _totalCount,
                pageSize: _pageSize,
                onPageChanged: (page) => _loadReservations(page: page),
              ),
            ),
          ],
        ],
      ),
    ),
  );
  String _reservationLabel(int count) {
    if (count == 1) return 'rezervacija';
    if (count >= 2 && count <= 4) return 'rezervacije';
    return 'rezervacija';
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final Future<void> Function() onReservationChanged;

  const _ReservationCard({
    required this.reservation,
    required this.onReservationChanged,
  });

  Color _stateColor(String state) {
    switch (state) {
      case 'Na čekanju':
        return Colors.orange.shade800;
      case 'Potvrđena':
        return Colors.green.shade700;
      case 'Otkazana':
        return Colors.red.shade700;
      case 'Završena':
        return Colors.blueGrey.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _stateDescription(String state) {
    switch (state) {
      case 'Na čekanju':
        return 'Čeka se potvrda lokala.';
      case 'Potvrđena':
        return 'Lokal je potvrdio rezervaciju.';
      case 'Otkazana':
        return 'Rezervacija je otkazana.';
      case 'Završena':
        return 'Termin rezervacije je završen.';
      default:
        return 'Status rezervacije nije dostupan.';
    }
  }

  IconData _stateIcon(String state) {
    switch (state) {
      case 'Na čekanju':
        return Icons.hourglass_top_rounded;
      case 'Potvrđena':
        return Icons.check_circle_rounded;
      case 'Otkazana':
        return Icons.cancel_rounded;
      case 'Završena':
        return Icons.task_alt_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = reservation.reservationState ?? '';
    final stateColor = _stateColor(state);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            offset: Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: ImageUtils.buildImage(reservation.localeLogo),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.customerName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.store_outlined,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            reservation.localeName ?? 'Lokal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: stateColor.withAlpha(24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_stateIcon(state), size: 14, color: stateColor),
                  const SizedBox(width: 4),
                  Text(
                    state.isEmpty ? 'Nepoznato' : state,
                    style: TextStyle(
                      color: stateColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stateDescription(state),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _ReservationInfo(
                        icon: Icons.access_time_rounded,
                        label: 'Termin',
                        value:
                            '${_formatTime(reservation.startTime)} - ${_formatTime(reservation.endTime)}',
                        alignment: MainAxisAlignment.start,
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: _ReservationInfo(
                        icon: Icons.table_restaurant_outlined,
                        label: 'Stol',
                        value: reservation.tableName ?? 'Stol',
                        alignment: MainAxisAlignment.center,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _ReservationInfo(
                        icon: Icons.people_outline,
                        label: 'Gosti',
                        value: '${reservation.numberOfGuests ?? 0}',
                        alignment: MainAxisAlignment.end,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () async {
                if (reservation.id == null) {
                  showFeedback(
                    context,
                    'Rezervacija više nije dostupna. Osvježite pregled.',
                    error: true,
                  );
                  return;
                }
                final cancelled = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkerReservationDetailsScreen(
                      reservation: reservation,
                    ),
                  ),
                );
                if (cancelled == true && context.mounted) {
                  await onReservationChanged();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Detalji rezervacije',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF1E40AF),
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
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

class _ReservationInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final MainAxisAlignment alignment;
  final TextAlign textAlign;

  const _ReservationInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.alignment,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1E40AF)),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                textAlign: textAlign,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
              ),
              Text(
                value,
                textAlign: textAlign,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
