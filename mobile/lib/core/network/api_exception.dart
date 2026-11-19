import 'package:dio/dio.dart';

/// A failure that the UI can show as is.
///
/// The backend sends `{"message": "..."}` for business errors (for example
/// insufficient stock) and Laravel's `{"message","errors"}` pair for validation,
/// so both are folded into one readable message.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const <String, List<String>>{},
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    if (data is Map) {
      final fieldErrors = _parseFieldErrors(data['errors']);
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return ApiException(
          fieldErrors.isEmpty ? message : _firstFieldMessage(fieldErrors, message),
          statusCode: statusCode,
          fieldErrors: fieldErrors,
        );
      }
    }

    if (statusCode == null) {
      return const ApiException(
        'Tidak bisa menghubungi server. Periksa koneksi dan alamat API.',
      );
    }
    if (statusCode == 401) {
      return const ApiException('Sesi berakhir, silakan masuk lagi.', statusCode: 401);
    }
    if (statusCode == 403) {
      return const ApiException('Role Anda tidak punya akses ke fitur ini.', statusCode: 403);
    }
    if (statusCode >= 500) {
      return ApiException('Terjadi kesalahan di server ($statusCode).', statusCode: statusCode);
    }

    return ApiException('Permintaan gagal ($statusCode).', statusCode: statusCode);
  }

  static String _firstFieldMessage(Map<String, List<String>> errors, String fallback) {
    for (final messages in errors.values) {
      if (messages.isNotEmpty) {
        return messages.first;
      }
    }
    return fallback;
  }

  static Map<String, List<String>> _parseFieldErrors(Object? raw) {
    if (raw is! Map) {
      return const <String, List<String>>{};
    }

    final parsed = <String, List<String>>{};
    raw.forEach((key, value) {
      if (value is List) {
        parsed['$key'] = value.map((entry) => '$entry').toList();
      }
    });
    return parsed;
  }

  @override
  String toString() => message;
}
