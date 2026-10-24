import 'package:easytab_desktop/exceptions/api_exception.dart';
import 'package:easytab_desktop/models/reservation.dart';
import 'package:easytab_desktop/providers/reservation_provider.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<void> showReservationDetails(
  BuildContext context,
  Reservation item,
) async {
  final future = context.read<ReservationProvider>().getById(item.id!);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Detalji rezervacije')),
          IconButton(
            tooltip: 'Zatvori',
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 430,
        child: FutureBuilder<Reservation>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Text(
                error is ApiClientException
                    ? error.message
                    : 'Nije moguće učitati detalje rezervacije.',
              );
            }
            final reservation = snapshot.data;
            if (reservation == null) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            String timestamp(DateTime value) =>
                DateFormat('dd.MM.yyyy. HH:mm').format(value.toLocal());
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lokal: ${reservation.localeName ?? "-"}'),
                  Text('Stol: ${reservation.tableName ?? "-"}'),
                  if (reservation.reservationDate != null)
                    Text(
                      'Datum: ${formatDateOnly(reservation.reservationDate!)}',
                    ),
                  Text(
                    'Termin: ${reservation.startTime ?? "-"} – ${reservation.endTime ?? "-"}',
                  ),
                  Text('Status: ${reservation.reservationState ?? "-"}'),
                  const SizedBox(height: 12),
                  Text('Plaćeno: ${reservation.paymentLabel}'),
                  if (reservation.paidAt != null)
                    Text('Datum plaćanja: ${timestamp(reservation.paidAt!)}'),
                  if (reservation.refundedAt != null)
                    Text(
                      'Datum refunda: ${timestamp(reservation.refundedAt!)}',
                    ),
                  if (reservation.cancellationReason?.isNotEmpty == true)
                    Text(
                      'Razlog otkazivanja: ${reservation.cancellationReason}',
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Back'),
        ),
      ],
    ),
  );
}
