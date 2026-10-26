import 'package:easytab_mobile/providers/notification_provider.dart';
import 'package:easytab_mobile/exceptions/api_exception.dart';
import 'package:easytab_mobile/models/reservation.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/reservation_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';

class UserReservationsScreen extends StatefulWidget {
  const UserReservationsScreen({super.key});

  @override
  State<UserReservationsScreen> createState() => _UserReservationsScreenState();
}

class _UserReservationsScreenState extends State<UserReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ReservationProvider _reservationProvider;
  late NotificationProvider _notifications;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reservationProvider = context.read<ReservationProvider>();
    _notifications = context.read<NotificationProvider>();
    _notifications.addListener(_onNotification);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _notifications.removeListener(_onNotification);
    _tabController.dispose();
    super.dispose();
  }

  void _onNotification() {
    if (mounted) _loadData();
  }

  Future<void> _loadData() async {
    final userId = AuthProvider.currentUserId;
    if (userId == null) return;
    await _reservationProvider.loadAll(userId);
  }

  Future<void> _loadUpcoming() async {
    final userId = AuthProvider.currentUserId;
    if (userId == null) return;
    await _reservationProvider.loadUpcoming(userId);
  }

  Future<void> _loadPast() async {
    final userId = AuthProvider.currentUserId;
    if (userId == null) return;
    await _reservationProvider.loadPast(userId);
  }

  Future<void> _handleCancelReservation(Reservation reservation) async {
    final userId = AuthProvider.currentUserId;
    if (userId == null || reservation.id == null) return;

    if (_busy) return;
    setState(() => _busy = true);
    var enteredReason = '';
    final reasonFormKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: dialogTitle(ctx, 'Otkaži rezervaciju'),
        content: Form(
          key: reasonFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jeste li sigurni da želite otkazati rezervaciju za "${reservation.localeName ?? 'Lokal'}"?',
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
              ),
              if (reservation.isPaid)
                const Text(
                  'Rezervacija je plaćena; nakon otkazivanja slijedi povrat novca',
                ),
              const SizedBox(height: 16),
              const Text(
                'Razlog otkazivanja (obavezno):',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                maxLength: 1000,
                onChanged: (value) => enteredReason = value.trim(),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Razlog otkazivanja je obavezan.'
                    : null,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Npr. Promjena planova...',
                  errorMaxLines: 3,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Odustani',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonFormKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Otkaži rezervaciju',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      if (mounted) setState(() => _busy = false);
      return;
    }

    try {
      await _reservationProvider.cancelReservation(
        reservation.id!,
        enteredReason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reservation.isPaid
                        ? 'Rezervacija je otkazana. Povrat novca je obrađen.'
                        : 'Rezervacija je uspješno otkazana.',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _tabController.animateTo(1);
      }
    } on ApiClientException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Otkazivanje nije potvrđeno. Provjerite internet vezu i pokušajte ponovo.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildTabBarContainer(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildUpcomingTab(provider), _buildPastTab(provider)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarContainer() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF1E40AF),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Aktivne'),
            Tab(text: 'Historija'),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTab(ReservationProvider provider) {
    if (provider.isLoadingUpcoming) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
      );
    }

    if (provider.errorUpcoming != null) {
      return _buildErrorView(provider.errorUpcoming!, _loadUpcoming);
    }

    if (provider.upcomingReservations.isEmpty) {
      return _buildEmptyView(
        icon: Icons.calendar_today_outlined,
        title: 'Nemate aktivnih rezervacija',
        subtitle:
            'Rezervišite stol u vašem omiljenom lokalu i pratite status ovdje.',
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1E40AF),
      onRefresh: _loadUpcoming,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        itemCount: provider.upcomingReservations.length + 1,
        itemBuilder: (context, index) {
          if (index == provider.upcomingReservations.length) {
            return PaginationUtils.buildPageControls(
              currentPage: provider.upcomingPage,
              totalCount: provider.upcomingTotal,
              pageSize: ReservationProvider.pageSize,
              onPageChanged: (page) {
                final id = AuthProvider.currentUserId;
                if (id != null) provider.loadUpcoming(id, page: page);
              },
            );
          }
          final res = provider.upcomingReservations[index];
          return _buildReservationCard(res, isUpcoming: true);
        },
      ),
    );
  }

  Widget _buildPastTab(ReservationProvider provider) {
    if (provider.isLoadingPast) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
      );
    }

    if (provider.errorPast != null) {
      return _buildErrorView(provider.errorPast!, _loadPast);
    }

    if (provider.pastReservations.isEmpty) {
      return _buildEmptyView(
        icon: Icons.history_rounded,
        title: 'Nemate prošlih rezervacija',
        subtitle:
            'Ovdje će se prikazivati vaše završene i otkazane rezervacije.',
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1E40AF),
      onRefresh: _loadPast,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        itemCount: provider.pastReservations.length + 1,
        itemBuilder: (context, index) {
          if (index == provider.pastReservations.length) {
            return PaginationUtils.buildPageControls(
              currentPage: provider.pastPage,
              totalCount: provider.pastTotal,
              pageSize: ReservationProvider.pageSize,
              onPageChanged: (page) {
                final id = AuthProvider.currentUserId;
                if (id != null) provider.loadPast(id, page: page);
              },
            );
          }
          final res = provider.pastReservations[index];
          return _buildReservationCard(res, isUpcoming: false);
        },
      ),
    );
  }

  Widget _buildReservationCard(Reservation res, {required bool isUpcoming}) {
    final state = res.reservationState ?? 'Na čekanju';
    final canCancel = isUpcoming && res.isActive;

    final dateStr = res.reservationDate == null
        ? '-'
        : formatDateOnly(res.reservationDate!);

    final startTimeClean = _formatTime(res.startTime);
    final endTimeClean = _formatTime(res.endTime);
    final timeStr = '$startTimeClean - $endTimeClean';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gornji dio sa logotipom i statusom
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo lokala
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: ImageUtils.buildImage(
                      res.localeLogo,
                      fit: BoxFit.cover,
                      placeholder: const Center(
                        child: Icon(
                          Icons.store_outlined,
                          size: 24,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Naziv i adresa
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          res.localeName ?? 'Lokal',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (res.localeAddress != null &&
                            res.localeAddress!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  res.localeAddress!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status badge
                  _buildStatusBadge(state),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Detalji rezervacije (Sto, Datum, Termin, Gosti)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _infoItem(
                            Icons.table_restaurant_outlined,
                            'Stol',
                            res.tableName ?? 'Stol',
                          ),
                        ),
                        Expanded(
                          child: _infoItem(
                            Icons.people_outline,
                            'Broj gostiju',
                            '${res.numberOfGuests ?? 2} ${(res.numberOfGuests ?? 2) == 1 ? 'gost' : 'gosta/iju'}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _infoItem(
                            Icons.calendar_today_outlined,
                            'Datum',
                            dateStr,
                          ),
                        ),
                        Expanded(
                          child: _infoItem(
                            Icons.access_time_rounded,
                            'Termin',
                            timeStr,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Razlog otkazivanja ako postoji
            if (state.toLowerCase() == 'otkazana' &&
                res.cancellationReason != null &&
                res.cancellationReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFFBE123C),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Razlog: ${res.cancellationReason}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFBE123C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (res.isPaid)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  '✓ Plaćeno${res.paidAmountKm == null ? '' : ' · ${res.paidAmountKm!.toStringAsFixed(2)} KM'}',
                ),
              ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Sačekajte završetak trenutnog zahtjeva.'),
              ),
            // Dugme za otkazivanje
            if (canCancel)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _handleCancelReservation(res),
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Otkaži rezervaciju',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECDD3)),
                      backgroundColor: const Color(0xFFFFF1F2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1E40AF)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String state) {
    Color bg;
    Color text;
    IconData icon;
    String label = state;

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
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

  Widget _buildEmptyView({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF1E40AF)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
              ),
              child: const Text(
                'Pokušaj ponovo',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
