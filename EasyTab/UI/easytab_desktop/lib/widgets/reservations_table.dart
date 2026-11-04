import 'package:easytab_desktop/models/reservation.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:flutter/material.dart';

class ReservationsTable extends StatelessWidget {
  const ReservationsTable({
    super.key,
    required this.reservations,
    required this.buildActions,
    this.showLocale = false,
  });

  final List<Reservation> reservations;
  final Widget Function(Reservation) buildActions;
  final bool showLocale;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300),
    ),
    clipBehavior: Clip.antiAlias,
    child: reservations.isEmpty
        ? const Center(child: Text('Nema rezervacija za prikaz.'))
        : SingleChildScrollView(
            child: DataTable(
              horizontalMargin: 8,
              columnSpacing: 8,
              headingRowHeight: 52,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 64,
              headingRowColor: WidgetStateProperty.all(const Color(0xFF1E40AF)),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
              columns: [
                if (showLocale) _column('Lokal', const FlexColumnWidth(1.1)),
                _column('Stol', const FlexColumnWidth()),
                _column('Gost', const FlexColumnWidth(1.25)),
                _column('Broj gostiju', const FlexColumnWidth(0.65)),
                _column('Datum', const FlexColumnWidth(0.95)),
                _column('Termin', const FlexColumnWidth(1.1)),
                _column('Status', const FlexColumnWidth(1.1)),
                _column('Plaćeno', const FlexColumnWidth(1.4)),
                _column('Akcija', const FixedColumnWidth(108)),
              ],
              rows: [
                for (var index = 0; index < reservations.length; index++)
                  _buildRow(reservations[index], index),
              ],
            ),
          ),
  );

  static DataColumn _column(String label, TableColumnWidth width) => DataColumn(
    label: Expanded(
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    tooltip: label,
    columnWidth: width,
  );

  DataRow _buildRow(Reservation reservation, int index) => DataRow(
    color: WidgetStateProperty.all(
      index.isEven ? Colors.white : const Color(0xFFF8FAFC),
    ),
    cells: [
      if (showLocale) _textCell(reservation.localeName ?? '-'),
      _textCell(reservation.tableName ?? '-'),
      _textCell(reservation.guestName),
      _textCell('${reservation.numberOfGuests ?? '-'}'),
      _textCell(
        reservation.reservationDate == null
            ? '-'
            : formatDateOnly(reservation.reservationDate!),
      ),
      _textCell(
        formatReservationTimeRange(reservation.startTime, reservation.endTime),
        maxLines: 2,
      ),
      DataCell(_statusBadge(reservation.reservationState ?? 'Na čekanju')),
      _textCell(
        reservation.paymentLabel,
        style: TextStyle(
          color: reservation.refundedAmountKm == null
              ? null
              : Colors.deepOrange,
        ),
      ),
      DataCell(
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: buildActions(reservation),
        ),
      ),
    ],
  );

  static DataCell _textCell(
    String value, {
    TextStyle? style,
    int maxLines = 1,
  }) => DataCell(
    Tooltip(
      message: value,
      child: Text(
        value,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    ),
  );

  static Widget _statusBadge(String state) {
    final (background, foreground, icon) = switch (state.toLowerCase()) {
      'na čekanju' => (
        const Color(0xFFFEF3C7),
        const Color(0xFFB45309),
        Icons.hourglass_top_rounded,
      ),
      'potvrđena' || 'potvrdena' => (
        const Color(0xFFDCFCE7),
        const Color(0xFF15803D),
        Icons.check_circle_rounded,
      ),
      'završena' || 'zavrsena' => (
        const Color(0xFFDBEAFE),
        const Color(0xFF1E40AF),
        Icons.task_alt_rounded,
      ),
      'otkazana' => (
        const Color(0xFFFFE4E6),
        const Color(0xFFBE123C),
        Icons.cancel_rounded,
      ),
      _ => (
        const Color(0xFFF1F5F9),
        const Color(0xFF475569),
        Icons.info_outline,
      ),
    };
    return Tooltip(
      message: state,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                state,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
