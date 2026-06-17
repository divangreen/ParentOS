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

/// Thin wrapper around ParentOS's own backend REST API -- the mobile app
/// never calls Supabase directly, see DECISIONS.md ADR-009.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> _headers(String? accessToken) => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Future<dynamic> get(String path, {String? accessToken}) async {
    final response = await _client.get(Uri.parse('$_baseUrl$path'), headers: _headers(accessToken));
    return _decodeOrThrow(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, String? accessToken}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(accessToken),
      body: body != null ? jsonEncode(body) : null,
    );
    return _decodeOrThrow(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body, String? accessToken}) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(accessToken),
      body: body != null ? jsonEncode(body) : null,
    );
    return _decodeOrThrow(response);
  }

  dynamic _decodeOrThrow(http.Response response) {
    if (response.statusCode == 204) return null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isEmpty ? null : jsonDecode(response.body);
    }
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
