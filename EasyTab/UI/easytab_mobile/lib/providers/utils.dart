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

    // Ako je base64 data URL
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
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
}
