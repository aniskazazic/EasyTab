import 'package:easytab_mobile/models/reservation.dart';
import 'package:easytab_mobile/providers/reservation_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';

class WorkerReservationDetailsScreen extends StatefulWidget {
  final Reservation reservation;

  const WorkerReservationDetailsScreen({super.key, required this.reservation});

  @override
  State<WorkerReservationDetailsScreen> createState() =>
      _WorkerReservationDetailsScreenState();
}

class _WorkerReservationDetailsScreenState
    extends State<WorkerReservationDetailsScreen> {
  static const _blue = Color(0xFF1E40AF);
  late Future<Reservation> _reservationFuture;
  Future<List<String>> _allowedActionsFuture = Future.value([]);
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _reservationFuture = _loadDetails();
  }

  Future<Reservation> _loadDetails() async {
    final id = widget.reservation.id;
    if (id == null) return widget.reservation;
    final provider = context.read<ReservationProvider>();
    late Reservation details;
    late List<String> actions;
    await Future.wait<void>([
      provider.getById(id).then<void>((value) {
        details = value;
      }),
      provider.getAllowedActions(id).then<void>((value) {
        actions = value;
      }),
    ]);
    _allowedActionsFuture = Future.value(actions);
    return details;
  }

  void _reload() => setState(() {
    _reservationFuture = _loadDetails();
  });
  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return formatDateOnly(date);
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '--:--';
    return value.length >= 5 ? value.substring(0, 5) : value;
  }

  String _guestName(Reservation reservation) {
    final name = reservation.customerName;
    return name.isEmpty ? 'Gost' : name;
  }

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

  String _cancellationDisabledReason(String state) {
    switch (state) {
      case 'Otkazana':
        return 'Rezervacija je već otkazana.';
      case 'Završena':
        return 'Završena rezervacija se ne može otkazati.';
      case 'Na čekanju':
      case 'Potvrđena':
        return 'Otkazivanje trenutno nije dozvoljeno za ovu rezervaciju.';
      default:
        return 'Otkazivanje nije dozvoljeno za trenutno stanje rezervacije.';
    }
  }

  Future<String?> _askCancellationReason() async {
    return showDialog<String>(
      context: context,
      builder: (_) => const _CancellationReasonDialog(),
    );
  }

  Future<void> _cancelReservation(Reservation details) async {
    final reason = await _askCancellationReason();
    if (reason == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: dialogTitle(dialogContext, 'Potvrda otkazivanja'),
        content: Text('Da li želite otkazati rezervaciju?\n\nRazlog: $reason'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ne'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Da, otkaži'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || details.id == null) return;

    setState(() => _isCancelling = true);
    try {
      await context.read<ReservationProvider>().cancelReservation(
        details.id!,
        reason,
      );
      if (!mounted) return;
      setState(() => _isCancelling = false);
      showFeedback(
        context,
        details.isPaid
            ? 'Rezervacija je otkazana. Povrat novca je obrađen.'
            : 'Rezervacija je uspješno otkazana.',
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildBrandHeader(context),
          _buildTitleRow(context),
          Expanded(
            child: FutureBuilder<Reservation>(
              future: _reservationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _blue),
                  );
                }
                final details = snapshot.data ?? widget.reservation;
                return _buildDetails(details, snapshot.hasError);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(Reservation details, bool hasError) {
    if (hasError || details.id == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Detalji rezervacije nisu dostupni. Pokušajte ponovo.'),
            TextButton(onPressed: _reload, child: const Text('Pokušaj ponovo')),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: ImageUtils.buildImage(details.localeLogo),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(details.localeName ?? 'Lokal')),
            ],
          ),
          const SizedBox(height: 12),
          _buildReservationStatus(details),
          const SizedBox(height: 18),
          _InfoCard(
            title: 'Informacije o gostu',
            children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Ime i prezime',
                value: _guestName(details),
              ),
              _InfoRow(
                icon: Icons.mail_outline,
                label: 'Email',
                value: details.email ?? 'Nije dostupno',
              ),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Broj telefona',
                value: details.phoneNumber ?? 'Nije dostupno',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoCard(
            title: 'Detalji rezervacije',
            titleColor: Colors.black,
            backgroundColor: Colors.white,
            children: [
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Datum',
                value: _formatDate(details.reservationDate),
                color: Colors.black,
              ),
              _InfoRow(
                icon: Icons.access_time,
                label: 'Vrijeme',
                value:
                    '${_formatTime(details.startTime)} - ${_formatTime(details.endTime)}',
                color: Colors.black,
              ),
              _InfoRow(
                icon: Icons.group_outlined,
                label: 'Broj osoba',
                value: '${details.numberOfGuests ?? 0} osoba',
                color: Colors.black,
              ),
              _InfoRow(
                icon: Icons.table_restaurant_outlined,
                label: 'Stol',
                value: details.tableName ?? 'Stol',
                color: Colors.black,
              ),
              _InfoRow(
                icon: Icons.store_outlined,
                label: 'Lokal',
                value: details.localeName ?? 'Lokal nije dostupan',
                color: Colors.black,
              ),
              if (details.localeAddress?.isNotEmpty == true)
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Adresa lokala',
                  value: details.localeAddress!,
                  color: Colors.black,
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCancellationAction(details),
        ],
      ),
    );
  }

  Widget _buildReservationStatus(Reservation details) {
    final state = details.reservationState ?? '';
    final color = _stateColor(state);
    final background = switch (state) {
      'Na čekanju' => const Color(0xFFFEF3C7),
      'Potvrđena' => const Color(0xFFDCFCE7),
      'Otkazana' => const Color(0xFFFFE4E6),
      'Završena' => const Color(0xFFDBEAFE),
      _ => const Color(0xFFF1F5F9),
    };
    final icon = switch (state) {
      'Na čekanju' => Icons.hourglass_top_rounded,
      'Potvrđena' => Icons.check_circle_rounded,
      'Otkazana' => Icons.cancel_rounded,
      'Završena' => Icons.task_alt_rounded,
      _ => Icons.info_outline,
    };
    final description = switch (state) {
      'Na čekanju' => 'Čeka se da lokal potvrdi rezervaciju.',
      'Potvrđena' => 'Lokal je potvrdio ovu rezervaciju.',
      'Otkazana' =>
        details.cancellationReason?.isNotEmpty == true
            ? 'Rezervacija je otkazana. Razlog: ${details.cancellationReason}'
            : 'Rezervacija je otkazana.',
      'Završena' => 'Termin rezervacije je završen.',
      _ => 'Status rezervacije nije dostupan.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 5),
                Text(
                  state.isEmpty ? 'Nepoznato stanje' : state,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationAction(Reservation details) {
    return FutureBuilder<List<String>>(
      future: _allowedActionsFuture,
      builder: (context, snapshot) {
        final canCancel =
            snapshot.hasData && snapshot.data!.contains('CancelAsync');
        final state = details.reservationState ?? '';
        final disabledReason = snapshot.hasError
            ? 'Dozvoljene akcije nisu dostupne. Pokušajte ponovo kasnije.'
            : snapshot.connectionState != ConnectionState.done
            ? 'Provjeravaju se dozvoljene akcije...'
            : _cancellationDisabledReason(state);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canCancel && !_isCancelling
                    ? () => _cancelReservation(details)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: _isCancelling
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Otkaži rezervaciju',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            if (!canCancel) ...[
              const SizedBox(height: 8),
              Text(
                disabledReason,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _blue,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('EasyTab', style: TextStyle(fontSize: 26, color: Colors.white)),
          SizedBox(width: 8),
          Icon(Icons.table_restaurant, color: Colors.white, size: 30),
        ],
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      color: _blue,
      child: Row(
        children: [
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Detalji rezervacije',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancellationReasonDialog extends StatefulWidget {
  const _CancellationReasonDialog();

  @override
  State<_CancellationReasonDialog> createState() =>
      _CancellationReasonDialogState();
}

class _CancellationReasonDialogState extends State<_CancellationReasonDialog> {
  final _controller = TextEditingController();
  String? _validationMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _validationMessage = 'Razlog otkazivanja je obavezan.');
      return;
    }
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: dialogTitle(context, 'Razlog otkazivanja'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 1000,
        onChanged: (_) {
          if (_validationMessage != null) {
            setState(() => _validationMessage = null);
          }
        },
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Razlog otkazivanja (obavezno)',
          hintText: 'Unesite razlog',
          errorText: _validationMessage,
          errorMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Nazad'),
        ),
        FilledButton(onPressed: _continue, child: const Text('Nastavi')),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Color backgroundColor;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
    this.titleColor = const Color(0xFF111111),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 18, 20, 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: backgroundColor == Colors.white
              ? Colors.black54
              : backgroundColor,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(3, 4), blurRadius: 3),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 28, child: Icon(icon, size: 19, color: color)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12.5, color: color)),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
