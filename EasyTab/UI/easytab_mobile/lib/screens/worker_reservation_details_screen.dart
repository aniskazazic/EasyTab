import 'package:easytab_mobile/models/reservation.dart';
import 'package:easytab_mobile/providers/reservation_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  late final Future<Reservation> _reservationFuture;

  @override
  void initState() {
    super.initState();
    final reservationId = widget.reservation.id;
    _reservationFuture = reservationId == null
        ? Future.value(widget.reservation)
        : ReservationProvider().getById(reservationId);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '--:--';
    return value.length >= 5 ? value.substring(0, 5) : value;
  }

  String _guestName(Reservation reservation) {
    final name = reservation.customerName;
    return name.isEmpty ? 'Gost' : name;
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: _blue,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Rezervacije',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Postavke',
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(Reservation details, bool hasError) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasError)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Detalji nisu osvježeni sa servera. Prikazani su podaci iz liste.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
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
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                disabledBackgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                'Otkaži rezervaciju',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
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
      height: 56,
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
          const Text(
            'Detalji rezervacije',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
