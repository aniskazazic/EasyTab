import 'package:easytab_desktop/providers/utils.dart';
import 'package:flutter/material.dart';

Future<DateTimeRange?> selectReportPeriod(BuildContext context) {
  final today = DateUtils.dateOnly(DateTime.now());
  var from = today.subtract(const Duration(days: 29));
  var to = today;
  String? error;
  return showDialog<DateTimeRange>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> pick(bool isFrom) async {
          final date = await showDatePicker(
            context: ctx,
            initialDate: isFrom ? from : to,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date == null || !ctx.mounted) return;
          setState(() {
            if (isFrom) {
              from = date;
            } else {
              to = date;
            }
            error = to.isBefore(from)
                ? 'Datum do ne smije biti prije datuma od.'
                : null;
          });
        }

        return AlertDialog(
          title: Row(
            children: [
              const Expanded(child: Text('Period izvještaja')),
              IconButton(
                tooltip: 'Zatvori',
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => pick(true),
                child: Text('Od: ${formatDateOnly(from)}'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => pick(false),
                child: Text('Do: ${formatDateOnly(to)}'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back'),
            ),
            Tooltip(
              message: error ?? 'Generiši PDF za odabrani period',
              child: ElevatedButton(
                onPressed: error == null
                    ? () => Navigator.pop(
                        ctx,
                        DateTimeRange(start: from, end: to),
                      )
                    : null,
                child: const Text('Generiši PDF'),
              ),
            ),
          ],
        );
      },
    ),
  );
}
