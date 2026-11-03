import 'package:easytab_desktop/models/locale.dart' as model;
import 'package:easytab_desktop/providers/utils.dart';
import 'package:flutter/material.dart';

class ReservationFilters extends StatelessWidget {
  const ReservationFilters({
    super.key,
    required this.searchController,
    this.locales = const [],
    this.localeId,
    required this.state,
    required this.paymentStatus,
    required this.date,
    this.onLocaleChanged,
    required this.onStateChanged,
    required this.onPaymentStatusChanged,
    required this.onDateChanged,
    required this.onApply,
    required this.onClear,
    this.hasAppliedFilters = false,
    this.expandToFill = false,
  });

  final TextEditingController searchController;
  final List<model.Locale> locales;
  final int? localeId;
  final String? state;
  final String? paymentStatus;
  final DateTime? date;
  final ValueChanged<int?>? onLocaleChanged;
  final ValueChanged<String?> onStateChanged;
  final ValueChanged<String?> onPaymentStatusChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final bool hasAppliedFilters;
  final bool expandToFill;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: searchController,
    builder: (context, value, child) {
      final showClear =
          hasAppliedFilters ||
          value.text.isNotEmpty ||
          localeId != null ||
          (state != null && state != 'Sva stanja') ||
          paymentStatus != null ||
          date != null;
      final searchField = TextField(
        controller: searchController,
        decoration: const InputDecoration(
          labelText: 'Pretraga',
          hintText: 'Naziv stola ili ime i prezime gosta',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      );
      final localeField = DropdownButtonFormField<int>(
        key: ValueKey((localeId, locales.length)),
        initialValue: locales.any((item) => item.id == localeId)
            ? localeId
            : null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Lokal',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Svi lokali')),
          ...locales.map(
            (locale) => DropdownMenuItem(
              value: locale.id,
              child: Text(locale.name ?? '', overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onLocaleChanged,
      );
      final stateField = DropdownButtonFormField<String>(
        key: ValueKey(state),
        initialValue: state ?? 'Sva stanja',
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Stanje',
          border: OutlineInputBorder(),
        ),
        items: ['Sva stanja', 'Na čekanju', 'Potvrđena', 'Završena', 'Otkazana']
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: onStateChanged,
      );
      final paymentField = DropdownButtonFormField<String>(
        key: ValueKey(paymentStatus),
        initialValue: paymentStatus,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Status plaćanja',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: null, child: Text('Sve')),
          DropdownMenuItem(value: 'Paid', child: Text('Plaćeno')),
          DropdownMenuItem(value: 'Unpaid', child: Text('Neplaćeno')),
          DropdownMenuItem(value: 'Refunded', child: Text('Refundirano')),
        ],
        onChanged: onPaymentStatusChanged,
      );
      final dateButton = OutlinedButton.icon(
        icon: const Icon(Icons.calendar_today, size: 18),
        label: Text(date == null ? 'Svi datumi' : formatDateOnly(date!)),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (context.mounted && picked != null) onDateChanged(picked);
        },
      );
      final searchButton = ElevatedButton.icon(
        icon: const Icon(Icons.search),
        label: const Text('Pretraga'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E40AF),
          foregroundColor: Colors.white,
        ),
        onPressed: onApply,
      );
      final clearButton = IconButton(
        tooltip: 'Poništi filtere',
        icon: const Icon(Icons.clear),
        onPressed: onClear,
      );

      if (!expandToFill) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(width: 280, child: searchField),
            if (onLocaleChanged != null)
              SizedBox(width: 220, child: localeField),
            SizedBox(width: 180, child: stateField),
            SizedBox(width: 190, child: paymentField),
            dateButton,
            searchButton,
            if (showClear) clearButton,
          ],
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final actions = [
            const SizedBox(width: 12),
            SizedBox(width: 132, height: 56, child: searchButton),
            if (showClear) ...[const SizedBox(width: 12), clearButton],
          ];
          if (constraints.maxWidth >= 960) {
            return Row(
              children: [
                Expanded(flex: 4, child: searchField),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: stateField),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: paymentField),
                const SizedBox(width: 12),
                SizedBox(width: 160, height: 56, child: dateButton),
                ...actions,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: stateField),
                  const SizedBox(width: 12),
                  Expanded(child: paymentField),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: SizedBox(height: 56, child: dateButton)),
                  ...actions,
                ],
              ),
            ],
          );
        },
      );
    },
  );
}
