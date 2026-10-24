import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class ReservationPriceField extends StatelessWidget {
  const ReservationPriceField({super.key});

  static String? validate(String? value) {
    final normalized = (value ?? '').trim().replaceAll(',', '.');
    const formatMessage = 'Unesite iznos u KM, npr. 5.00';
    if (!RegExp(r'^-?\d+(\.\d{1,2})?$').hasMatch(normalized)) {
      return '$formatMessage (najviše 2 decimale).';
    }
    final price = double.tryParse(normalized);
    if (price == null || !price.isFinite || price < 0.05 || price > 1000) {
      return 'Cijena mora biti od 0.05 do 1000 KM. $formatMessage.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'reservationPrice',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Cijena rezervacije (KM)',
        hintText: 'Unesite iznos u KM, npr. 5.00',
        helperText:
            'Cijena se naplaćuje pri rezervaciji. Promjena cijene ne utiče na već plaćene rezervacije.',
        helperMaxLines: 3,
        errorMaxLines: 3,
        border: OutlineInputBorder(),
      ),
      validator: validate,
    );
  }
}
