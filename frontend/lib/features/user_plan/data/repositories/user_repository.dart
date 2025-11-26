import 'dart:convert';
import 'package:flutter_autoreps/core/network/api_client.dart';
import 'package:flutter_autoreps/core/config/api_config.dart';
import 'package:flutter_autoreps/features/auth/data/models/auth_response.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get current user info (from User table, not UserProfile)
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.user}/me',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return User.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw UserException(error['error'] ?? 'Failed to get user');
      }
    } catch (e) {
      if (e is UserException) rethrow;
      throw UserException('Network error: ${e.toString()}');
    }
  }

  /// Dispose
  void dispose() {
    // Don't dispose the singleton client
  }
}

/// Custom exception for user errors
class UserException implements Exception {
  final String message;
  UserException(this.message);

  @override
  String toString() => message;
}
