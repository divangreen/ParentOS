import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

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
  AuthApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<AuthResult> signUp({required String email, required String password}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return AuthResult.fromJson(_decodeOrThrow(response));
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return AuthResult.fromJson(_decodeOrThrow(response));
  }

  Future<TokenPair> refresh({required String refreshToken}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    return TokenPair.fromJson(_decodeOrThrow(response));
  }

  Future<void> logout({required String accessToken}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/logout'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 204) {
      _throwForStatus(response);
    }
  }

  Map<String, dynamic> _decodeOrThrow(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _throwForStatus(response);
  }

  Never _throwForStatus(http.Response response) {
    String message = 'Request failed';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = (body['detail'] ?? message).toString();
    } catch (_) {
      // Response body wasn't JSON -- fall back to the default message.
    }
    throw ApiException(response.statusCode, message);
  }
}
