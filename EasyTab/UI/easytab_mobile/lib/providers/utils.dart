import 'dart:convert';

import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatNumber(dynamic number) {
  var f = NumberFormat("#.##0.00", "en_US");
  if (number == null) {
    return "";
  }

  return f.format(number);
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

    return Container(
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

class ImageUtils {
  /// Vraća Widget za prikaz slike iz URL-a ili base64 stringa
  static Widget buildImage(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return placeholder ?? _defaultPlaceholder();
    }

    // Ako je base64 data URL ili čisti base64 string
    if (imageUrl.startsWith('data:image') || _isBase64(imageUrl)) {
      try {
        final base64String = imageUrl.startsWith('data:image') 
            ? imageUrl.split(',').last 
            : imageUrl;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder ?? _defaultPlaceholder(),
        );
      } catch (e) {
        return placeholder ?? _defaultPlaceholder();
      }
    }

    // Inače običan URL - popravi localhost
    final fixedUrl = _fixLocalhost(imageUrl);
    return Image.network(
      fixedUrl!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (_, __, ___) => placeholder ?? _defaultPlaceholder(),
    );
  }

  static String? _fixLocalhost(String? url) {
    if (url == null || url.isEmpty) return url;
    if (url.startsWith('data:')) return url;
    try {
      final uri = Uri.parse(url);
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        final base = BaseProvider.baseUrl;
        if (base != null && base.isNotEmpty) {
          final baseUri = Uri.parse(base);
          final newUri = uri.replace(
            scheme: baseUri.scheme,
            host: baseUri.host,
            port: baseUri.port,
          );
          return newUri.toString();
        }
      }
    } catch (_) {}
    return url;
  }

  static Widget _defaultPlaceholder() {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(Icons.store_outlined, size: 32, color: Color(0xFF1E40AF)),
      ),
    );
  }
  static bool _isBase64(String str) {
    if (str.length % 4 != 0) return false;
    final base64Regex = RegExp(r'^[a-zA-Z0-9+/]*={0,2}$');
    return base64Regex.hasMatch(str);
  }
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

MemoryImage imageFromBase64WithouthDimensions(String base64Image) {
  return MemoryImage(base64Decode(base64Image));
}
