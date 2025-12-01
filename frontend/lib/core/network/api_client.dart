import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

/// HTTP client wrapper for API requests
class ApiClient {
  // Singleton instance
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() : _client = http.Client();

  final http.Client _client;
  String? _authToken;

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Get headers with optional authentication
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// GET request
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint',
    ).replace(queryParameters: queryParams);

    return await _client
        .get(uri, headers: _getHeaders(includeAuth: requiresAuth))
        .timeout(ApiConfig.receiveTimeout);
  }

  /// POST request
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    return await _client
        .post(
          uri,
          headers: _getHeaders(includeAuth: requiresAuth),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.receiveTimeout);
  }

  /// PUT request
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    return await _client
        .put(
          uri,
          headers: _getHeaders(includeAuth: requiresAuth),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.receiveTimeout);
  }

  /// DELETE request
  Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    return await _client
        .delete(uri, headers: _getHeaders(includeAuth: requiresAuth))
        .timeout(ApiConfig.receiveTimeout);
  }

  /// Dispose the client
  void dispose() {
    _client.close();
  }
}
