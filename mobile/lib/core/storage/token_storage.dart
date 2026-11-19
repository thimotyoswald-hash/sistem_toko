import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the Sanctum bearer token in the platform keystore.
///
/// The token is also cached in memory so the Dio interceptor does not hit the
/// keystore on every request.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'pos_api_token';

  final FlutterSecureStorage _storage;

  String? _cached;
  bool _loaded = false;

  Future<String?> read() async {
    if (_loaded) {
      return _cached;
    }
    _cached = await _storage.read(key: _tokenKey);
    _loaded = true;
    return _cached;
  }

  Future<void> save(String token) async {
    _cached = token;
    _loaded = true;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _storage.delete(key: _tokenKey);
  }
}
