import 'dart:convert';

import 'package:easytab_desktop/models/search_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:easytab_desktop/exceptions/api_exception.dart';
import 'package:intl/intl.dart';

String userError(Object error) {
  const fallback =
      'Nije moguće izvršiti zahtjev. Provjerite vezu i pokušajte ponovo.';
  if (error is ApiClientException) {
    final message = error.message.trim();
    if (message.isNotEmpty &&
        !message.startsWith('{') &&
        !message.startsWith('[') &&
        !message.startsWith('<') &&
        !RegExp(
          r'exception|stack\s*trace|\b\w*Error:|BytePositionInLine|\n\s*at ',
          caseSensitive: false,
        ).hasMatch(message)) {
      return ApiErrorParser.messageFromBody(jsonEncode({'message': message})) ??
          fallback;
    }
  }
  return fallback;
}

final dateOnlyFormatter = DateFormat('dd.MM.yyyy.');

void showFeedback(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
}

final usernameInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
];
final earliestBirthDate = DateTime(1900, 1, 2);

DateTime get latestBirthDate {
  final now = DateTime.now();
  final lastDay = DateTime(now.year - 18, now.month + 1, 0).day;
  return DateTime(now.year - 18, now.month, now.day.clamp(1, lastDay));
}

DateTime birthDatePickerInitialDate(DateTime? value) {
  final date = value ?? DateTime(1990, 1, 1);
  if (date.isBefore(earliestBirthDate)) return earliestBirthDate;
  if (date.isAfter(latestBirthDate)) return latestBirthDate;
  return date;
}

String? validateUsername(String? value) {
  if (value == null || value.isEmpty) return 'Korisničko ime je obavezno.';
  if (value.length > 50) {
    return 'Korisničko ime može imati najviše 50 karaktera.';
  }
  return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)
      ? null
      : 'Koristite samo slova, brojeve i donju crtu (_).';
}

String? validateBirthDate(DateTime? value) {
  if (value == null) return null;
  final date = DateTime(value.year, value.month, value.day);
  if (date.isBefore(earliestBirthDate)) {
    return 'Datum rođenja mora biti nakon 01.01.1900.';
  }
  if (date.isAfter(latestBirthDate)) {
    return 'Korisnik mora imati najmanje 18 godina.';
  }
  return null;
}

bool showApiFieldErrors(FormBuilderState? form, Object error) {
  if (form == null || error is! ApiClientException) return false;
  var handled = false;
  for (final entry in error.validationErrors.entries) {
    final key = entry.key.split('.').last.toLowerCase();
    for (final field in form.fields.entries) {
      if (field.key.toLowerCase() == key) {
        field.value.invalidate(entry.value.join('\n'));
        handled = true;
      }
    }
  }
  return handled;
}

const _maxImageCacheEntries = 80;
final Map<String, Uint8List> _decodedImages = {};

Uint8List _decodeCached(String value) {
  final cached = _decodedImages.remove(value);
  if (cached != null) {
    _decodedImages[value] = cached;
    return cached;
  }

  final decoded = base64Decode(value);
  _decodedImages[value] = decoded;
  if (_decodedImages.length > _maxImageCacheEntries) {
    _decodedImages.remove(_decodedImages.keys.first);
  }
  return decoded;
}

String formatDateOnly(DateTime date) => dateOnlyFormatter.format(date);

String formatReservationTimeRange(String? startTime, String? endTime) {
  String formatTime(String? value) {
    if (value == null || value.isEmpty) return '--:--';
    final parts = value.split(':');
    return parts.length < 2
        ? value
        : '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  final start = formatTime(startTime);
  final end = formatTime(endTime);
  final nextDay =
      start != '--:--' && end != '--:--' && end.compareTo(start) < 0;
  return '$start - $end${nextDay ? ' (sljedeći dan)' : ''}';
}

bool worksAfterMidnight(TimeOfDay? start, TimeOfDay? end) =>
    start != null &&
    end != null &&
    end.hour * 60 + end.minute < start.hour * 60 + start.minute;

String? validateWorkingHoursEnd(TimeOfDay? start, TimeOfDay? end) {
  if (end == null) return 'Kraj radnog vremena je obavezan';
  if (start == end) {
    return 'Početak i kraj radnog vremena ne mogu biti isti.';
  }
  return null;
}

String formatSystemDateOnly(DateTime date) =>
    dateOnlyFormatter.format(date.toLocal());

DateTime toLocalDateTime(DateTime date) => date.toLocal();

String? validatePhone(String? value) {
  final phone = value?.trim() ?? '';
  if (phone.isEmpty) return null;

  final cleaned = phone.replaceAll(RegExp(r'[\s\-().]'), '');

  if (RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(cleaned)) {
    return null;
  }

  return 'Unesite ispravan broj (npr. +387 61 123 456 ili +49 30 12345678)';
}

Future<List<T>> fetchAllPages<T>(
  Future<SearchResult<T>> Function(Map<String, dynamic> filter) fetch,
) async {
  const pageSize = 100;
  final items = <T>[];
  var page = 1;

  while (true) {
    final result = await fetch({
      'Page': page,
      'PageSize': pageSize,
      'IncludeTotalCount': true,
    });
    final pageItems = result.items ?? <T>[];
    items.addAll(pageItems);

    if (pageItems.length < pageSize ||
        (result.totalCount != null && items.length >= result.totalCount!)) {
      return items;
    }

    page++;
  }
}

String formatNumber(dynamic number) {
  var f = NumberFormat("#.##0.00", "en_US");
  if (number == null) {
    return "";
  }

  return f.format(number);
}

void alertBox(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("OK"),
        ),
      ],
    ),
  );
}

Image imageFromBase64String(String base64String) {
  return Image.memory(_decodeCached(base64String), height: 200, width: 200);
}

ImageProvider? imageProviderFromString(String? value) {
  if (value == null || value.isEmpty) return null;

  final base64Part = value.startsWith('data:image')
      ? value.split(',').last
      : value;

  try {
    return MemoryImage(_decodeCached(base64Part));
  } catch (_) {
    return null;
  }
}

class PaginationUtils {
  static int totalPages(int totalCount, int pageSize) {
    if (pageSize <= 0) return 1;
    return totalCount == 0 ? 1 : (totalCount / pageSize).ceil();
  }

  static Widget buildPageControls({
    required int currentPage,
    required int totalCount,
    required int pageSize,
    required ValueChanged<int> onPageChanged,
    int maxVisible = 3,
    String pageLabelPrefix = 'Stranica',
    Color activeColor = const Color(0xFF1E40AF),
    Color inactiveColor = Colors.grey,
    double pageButtonSize = 26,
    bool showSummary = true,
  }) {
    final pageCount = totalPages(totalCount, pageSize);
    if (pageCount <= 1) {
      return const SizedBox.shrink();
    }

    int startPage = (currentPage - maxVisible ~/ 2).clamp(0, pageCount - 1);
    int endPage = (startPage + maxVisible - 1).clamp(0, pageCount - 1);
    if (endPage - startPage < maxVisible - 1) {
      startPage = (endPage - maxVisible + 1).clamp(0, pageCount - 1);
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showSummary) ...[
                Text(
                  '$pageLabelPrefix ${currentPage + 1}/$pageCount',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _pageButton(
                    icon: Icons.first_page_rounded,
                    onTap: currentPage > 0 ? () => onPageChanged(0) : null,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    pageButtonSize: pageButtonSize,
                  ),
                  _pageButton(
                    icon: Icons.keyboard_arrow_left_rounded,
                    onTap: currentPage > 0
                        ? () => onPageChanged(currentPage - 1)
                        : null,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    pageButtonSize: pageButtonSize,
                  ),
                  for (int i = startPage; i <= endPage; i++)
                    _pageNumberButton(
                      page: i,
                      currentPage: currentPage,
                      onPageChanged: onPageChanged,
                      activeColor: activeColor,
                      pageButtonSize: pageButtonSize,
                    ),
                  _pageButton(
                    icon: Icons.keyboard_arrow_right_rounded,
                    onTap: currentPage < pageCount - 1
                        ? () => onPageChanged(currentPage + 1)
                        : null,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    pageButtonSize: pageButtonSize,
                  ),
                  _pageButton(
                    icon: Icons.last_page_rounded,
                    onTap: currentPage < pageCount - 1
                        ? () => onPageChanged(pageCount - 1)
                        : null,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    pageButtonSize: pageButtonSize,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _pageButton({
    required IconData icon,
    VoidCallback? onTap,
    required Color activeColor,
    required Color inactiveColor,
    required double pageButtonSize,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: pageButtonSize,
        minHeight: pageButtonSize,
      ),
      color: onTap != null ? activeColor : inactiveColor,
    );
  }

  static Widget _pageNumberButton({
    required int page,
    required int currentPage,
    required ValueChanged<int> onPageChanged,
    required Color activeColor,
    required double pageButtonSize,
  }) {
    final isActive = page == currentPage;
    return GestureDetector(
      onTap: () => onPageChanged(page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        width: pageButtonSize,
        height: pageButtonSize,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            '${page + 1}',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
