import 'dart:convert';

/// Thrown when the API returns an error body we can show to the user
/// (e.g. [ClinetException] → HTTP 400 with `message` / `errors` from ExceptionFilter).
class ApiClientException implements Exception {
  ApiClientException(this.message, {this.validationErrors = const {}});

  static const imageValidationMessage =
      'Slika mora biti JPG, JPEG ili PNG i manja od 300 KB.';
  final String message;
  final Map<String, List<String>> validationErrors;

  Map<String, String> get imageValidationErrors {
    final result = <String, String>{};
    for (final entry in validationErrors.entries) {
      if (!entry.value.contains(imageValidationMessage)) continue;

      final key = entry.key.toLowerCase();
      final field = key.contains('profilepicture')
          ? 'profilePicture'
          : key.contains('logo')
          ? 'logo'
          : key.contains('images') || key.contains('base64content')
          ? 'images'
          : null;
      if (field != null) result[field] = imageValidationMessage;
    }
    return result;
  }

  @override
  String toString() => message;
}

/// Parses JSON error payloads from eCommerce.WebAPI [ExceptionFilter].
class ApiErrorParser {
  ApiErrorParser._();

  /// Prefer root `message`, then `errors.clientError`, then other error lists.
  static String? messageFromBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) {
        return null;
      }
      final map = Map<String, dynamic>.from(decoded);

      final root = map['message'];
      if (root is String) {
        final m = root.trim();
        if (m.isNotEmpty) {
          return m;
        }
      }

      final errors = map['errors'];
      if (errors is Map) {
        final errMap = Map<String, dynamic>.from(errors);
        final parts = <String>[];

        void addKey(String key) {
          final v = errMap[key];
          parts.addAll(_messagesFromValue(v));
        }

        addKey('userError');
        for (final key in errMap.keys) {
          if (key == 'userError') {
            continue;
          }
          addKey(key);
        }

        final unique = parts.toSet().toList();
        if (unique.isNotEmpty) {
          return unique.join('\n');
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, List<String>> validationErrorsFromBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return const {};

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map || decoded['errors'] is! Map) return const {};

      final errors = Map<String, dynamic>.from(decoded['errors'] as Map);
      return {
        for (final entry in errors.entries)
          if (entry.value is List && (entry.value as List).isNotEmpty)
            entry.key: (entry.value as List)
                .map((value) => value.toString())
                .toList(),
      };
    } on FormatException {
      return const {};
    }
  }

  static List<String> _messagesFromValue(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (v is String) {
      final s = v.trim();
      return s.isEmpty ? [] : [s];
    }
    return [];
  }
}
