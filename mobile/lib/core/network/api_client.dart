import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Thin Dio wrapper: attaches the bearer token, unwraps JSON maps, and turns
/// every transport/HTTP failure into an [ApiException] the UI can render.
class ApiClient {
  ApiClient({required AppConfig config, required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage,
      dio = Dio(
        BaseOptions(
          baseUrl: config.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Accept': 'application/json'},
          contentType: Headers.jsonContentType,
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401 && !_isLoginCall(error)) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final TokenStorage _tokenStorage;

  /// Invoked when the API rejects the stored token, so the app can log out.
  void Function()? onUnauthorized;

  static bool _isLoginCall(DioException error) =>
      error.requestOptions.path.endsWith('/login');

  /// Single-resource endpoints answer `{"data": {...}}`; unwrap that envelope.
  static Map<String, dynamic> unwrap(Map<String, dynamic> payload) {
    final data = payload['data'];
    return data is Map ? Map<String, dynamic>.from(data) : payload;
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, dynamic>? query}) {
    return _send(() => dio.get<dynamic>(path, queryParameters: query));
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body}) {
    return _send(() => dio.post<dynamic>(path, data: body));
  }

  Future<Map<String, dynamic>> putJson(String path, {Object? body}) {
    return _send(() => dio.put<dynamic>(path, data: body));
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return data.map((key, value) => MapEntry('$key', value));
      }
      return const <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
