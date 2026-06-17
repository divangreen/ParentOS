import 'api_client.dart';

export 'api_client.dart' show ApiException;

class AuthResult {
  AuthResult({required this.userId, required this.accessToken, required this.refreshToken});

  final String userId;
  final String accessToken;
  final String refreshToken;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        userId: json['user_id'] as String,
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}

class TokenPair {
  TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}

/// Talks to ParentOS's own backend /v1/auth/* endpoints (which proxy Supabase
/// Auth server-side) -- the mobile app never calls Supabase directly.
class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AuthResult> signUp({required String email, required String password}) async {
    final json = await _client.post('/auth/signup', body: {'email': email, 'password': password});
    return AuthResult.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final json = await _client.post('/auth/login', body: {'email': email, 'password': password});
    return AuthResult.fromJson(json as Map<String, dynamic>);
  }

  Future<TokenPair> refresh({required String refreshToken}) async {
    final json = await _client.post('/auth/refresh', body: {'refresh_token': refreshToken});
    return TokenPair.fromJson(json as Map<String, dynamic>);
  }

  Future<void> logout({required String accessToken}) async {
    await _client.post('/auth/logout', accessToken: accessToken);
  }
}
