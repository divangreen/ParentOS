import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_api.dart';
import '../services/token_storage.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.userId);
  final String userId;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.error});
  final String? error;
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authApiProvider = Provider<AuthApi>((ref) => AuthApi());

class AuthController extends Notifier<AuthState> {
  late final AuthApi _authApi;
  late final TokenStorage _tokenStorage;

  @override
  AuthState build() {
    _authApi = ref.watch(authApiProvider);
    _tokenStorage = ref.watch(tokenStorageProvider);
    _restoreSession();
    return const AuthInitial();
  }

  Future<void> _restoreSession() async {
    final userId = await _tokenStorage.readUserId();
    final accessToken = await _tokenStorage.readAccessToken();
    if (userId != null && accessToken != null) {
      state = AuthAuthenticated(userId);
    } else {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final result = await _authApi.signUp(email: email, password: password);
      await _tokenStorage.saveSession(
        userId: result.userId,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      state = AuthAuthenticated(result.userId);
    } on ApiException catch (e) {
      state = AuthUnauthenticated(error: e.message);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final result = await _authApi.login(email: email, password: password);
      await _tokenStorage.saveSession(
        userId: result.userId,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      state = AuthAuthenticated(result.userId);
    } on ApiException catch (e) {
      state = AuthUnauthenticated(error: e.message);
    }
  }

  Future<void> logout() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null) {
      try {
        await _authApi.logout(accessToken: accessToken);
      } on ApiException {
        // Token may already be expired/invalid server-side -- clear local state regardless.
      }
    }
    await _tokenStorage.clear();
    state = const AuthUnauthenticated();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
