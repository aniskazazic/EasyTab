import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

int? reservationMinutes(double? hours) {
  if (hours == null ||
      !hours.isFinite ||
      hours < 0.5 ||
      hours > 5 ||
      hours * 2 != (hours * 2).truncateToDouble()) {
    return null;
  }
  return (hours * 60).round();
}

class ReservationDurationField extends StatelessWidget {
  const ReservationDurationField({super.key});

  @override
  Widget build(BuildContext context) => FormBuilderDropdown<int>(
    name: 'lengthOfReservation',
    decoration: const InputDecoration(
      labelText: 'Trajanje rezervacije',
      helperText: 'Od 30 minuta do 5 sati; korak 30 minuta.',
      border: OutlineInputBorder(),
    ),
    items: [
      for (var minutes = 30; minutes <= 300; minutes += 30)
        DropdownMenuItem(value: minutes, child: Text(_durationLabel(minutes))),
    ],
    validator: (value) =>
        value == null || value < 30 || value > 300 || value % 30 != 0
        ? 'Odaberite od 30 minuta do 5 sati (300 min), u koracima od 30 minuta.'
        : null,
  );

  static String _durationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$minutes minuta';
    final unit = hours == 1
        ? 'sat'
        : hours < 5
        ? 'sata'
        : 'sati';
    final extra = remainder == 0 ? '' : ' $remainder minuta';
    return '$hours $unit$extra ($minutes min)';
  }
}
