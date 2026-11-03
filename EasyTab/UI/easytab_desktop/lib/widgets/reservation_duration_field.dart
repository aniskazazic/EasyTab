import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

int? reservationMinutes(double? hours) {
  if (hours == null ||
      !hours.isFinite ||
      hours < 0.5 ||
      hours > 24 ||
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
      labelText: 'Trajanje rezervacije (minute)',
      border: OutlineInputBorder(),
    ),
    items: [
      for (var minutes = 30; minutes <= 1440; minutes += 30)
        DropdownMenuItem(value: minutes, child: Text('$minutes min')),
    ],
    validator: (value) =>
        value == null || value < 30 || value > 1440 || value % 30 != 0
        ? 'Odaberite trajanje od 30 do 1440 minuta, u koracima od 30 minuta.'
        : null,
  );
}
