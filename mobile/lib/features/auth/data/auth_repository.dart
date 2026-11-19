import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/app_user.dart';

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    client: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

class AuthRepository {
  AuthRepository({required ApiClient client, required TokenStorage tokenStorage})
    : _client = client,
      _tokenStorage = tokenStorage;

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  /// Returns the signed-in user when a still-valid token is on the device.
  Future<AppUser?> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final payload = await _client.getJson('/me');
      return _readUser(payload);
    } on ApiException {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<AppUser> login({required String username, required String password}) async {
    final payload = await _client.postJson(
      '/login',
      body: <String, String>{'username': username, 'password': password},
    );

    final token = payload['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Server tidak mengirim token login.');
    }

    final user = _readUser(payload);
    await _tokenStorage.save(token);
    return user;
  }

  Future<void> logout() async {
    try {
      await _client.postJson('/logout');
    } on ApiException {
      // The token may already be gone server-side; clearing locally is enough.
    }
    await _tokenStorage.clear();
  }

  AppUser _readUser(Map<String, dynamic> payload) {
    final user = payload['user'];
    if (user is! Map) {
      throw const ApiException('Respons login tidak berisi data pengguna.');
    }
    return AppUser.fromJson(Map<String, dynamic>.from(user));
  }
}
