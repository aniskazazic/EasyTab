import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  return Image.memory(base64Decode(base64String), height: 200, width: 200);
}

ImageProvider? imageProviderFromString(String? value) {
  if (value == null || value.isEmpty) return null;

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return NetworkImage(value);
  }

  final base64Part = value.contains(',') ? value.split(',').last : value;

  try {
    return MemoryImage(base64Decode(base64Part));
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
