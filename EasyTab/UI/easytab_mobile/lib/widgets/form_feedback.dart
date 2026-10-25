import 'package:easytab_mobile/exceptions/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class FormValidation {
  static String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Obavezno polje.' : null;

  static String? username(String? value) {
    final required = requiredText(value);
    if (required != null) return required;
    return value!.trim().length > 50 ||
            !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())
        ? 'Koristite do 50 slova, brojeva ili donju crtu (_).'
        : null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Unesite e-mail adresu.';
    if (email.length > 100 ||
        !RegExp(r'^[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)+$').hasMatch(email)) {
      return 'Unesite e-mail u formatu ime@domena.ba.';
    }
    return null;
  }

  static String? phone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return null;
    final digits = phone.replaceAll(RegExp(r'[\s-]'), '');
    if (phone.length > 20 ||
        !RegExp(r'^\+?[0-9\s-]+$').hasMatch(phone) ||
        !RegExp(r'^\+?[0-9]{8,15}$').hasMatch(digits)) {
      return 'Unesite telefon, npr. +387 6X XXX XXX (8–15 cifara).';
    }
    return null;
  }

  static String? adult(DateTime? value) {
    if (value == null) return 'Unesite datum rođenja.';
    final now = DateTime.now();
    var age = now.year - value.year;
    if (now.month < value.month ||
        (now.month == value.month && now.day < value.day)) {
      age--;
    }
    return age < 18 ? 'Morate imati najmanje 18 godina.' : null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Unesite lozinku.';
    return value.length < 6 ? 'Lozinka mora imati najmanje 6 karaktera.' : null;
  }

  static bool showApiErrors(
    FormBuilderState? form,
    Object error, {
    Map<String, String> aliases = const {},
  }) {
    if (form == null || error is! ApiClientException) return false;
    var handled = false;
    for (final entry in error.validationErrors.entries) {
      final key = entry.key.split('.').last.toLowerCase();
      final name = aliases[key] ?? key;
      for (final field in form.fields.entries) {
        if (field.key.toLowerCase() == name.toLowerCase()) {
          field.value.invalidate(entry.value.join('\n'));
          handled = true;
        }
      }
    }
    return handled;
  }
}

void showFeedback(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : const Color(0xFF1E40AF),
      ),
    );
}

String userError(Object error) => error is ApiClientException
    ? error.message
    : 'Nije moguće izvršiti zahtjev. Provjerite vezu i pokušajte ponovo.';

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: dialogTitle(dialogContext, title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

Widget dialogTitle(BuildContext context, String title) => Row(
  children: [
    Expanded(child: Text(title)),
    IconButton(
      tooltip: 'Zatvori',
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.close),
    ),
  ],
);
