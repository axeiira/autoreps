import 'dart:convert';
import 'package:flutter_autoreps/core/network/api_client.dart';
import 'package:flutter_autoreps/core/config/api_config.dart';
import 'package:flutter_autoreps/features/auth/data/models/auth_response.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Register a new user
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/register',
        body: {'name': name, 'email': email, 'password': password},
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return User.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw AuthException(error['error'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  /// Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/login',
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(data);

        // Store the token in the API client for future requests
        _apiClient.setAuthToken(authResponse.token);

        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw AuthException(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  /// Logout (clear token)
  void logout() {
    _apiClient.clearAuthToken();
  }

  /// Dispose
  void dispose() {
    // Don't dispose the singleton client
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
