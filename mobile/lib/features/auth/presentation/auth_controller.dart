import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

sealed class AuthState {
  const AuthState();
}

/// The stored token is still being checked, so the router shows a splash.
class AuthChecking extends AuthState {
  const AuthChecking();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.notice});

  /// Set when the server invalidated the token, so the login screen can explain.
  final String? notice;
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);

  final AppUser user;
}

final NotifierProvider<AuthController, AuthState> authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    ref.read(apiClientProvider).onUnauthorized = handleExpiredSession;
    Future<void>.microtask(_restoreSession);
    return const AuthChecking();
  }

  Future<void> _restoreSession() async {
    final user = await _repository.restoreSession();
    state = user == null ? const AuthSignedOut() : AuthSignedIn(user);
  }

  /// Throws [ApiException] so the login form can display the server message.
  Future<void> login({required String username, required String password}) async {
    final user = await _repository.login(username: username, password: password);
    state = AuthSignedIn(user);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthSignedOut();
  }

  void handleExpiredSession() {
    if (state is AuthSignedIn) {
      state = const AuthSignedOut(notice: 'Sesi berakhir, silakan masuk lagi.');
    }
  }
}
