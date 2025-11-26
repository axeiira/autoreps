import 'dart:convert';
import 'package:flutter_autoreps/core/network/api_client.dart';
import 'package:flutter_autoreps/core/config/api_config.dart';
import 'package:flutter_autoreps/features/user_plan/data/models/user_profile.dart';

class UserProfileRepository {
  final ApiClient _apiClient;

  UserProfileRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get user profile
  Future<UserProfile?> getProfile() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.user}/profile',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) return null;
        return UserProfile.fromJson(data as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        throw UserProfileException(error['error'] ?? 'Failed to get profile');
      }
    } catch (e) {
      if (e is UserProfileException) rethrow;
      throw UserProfileException('Network error: ${e.toString()}');
    }
  }

  /// Create or update user profile
  Future<UserProfile> saveProfile({
    required int age,
    required double weight,
    required String primaryGoal,
    required String experienceLevel,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.user}/profile',
        body: {
          'age': age,
          'weight': weight,
          'primaryGoal': primaryGoal,
          'experienceLevel': experienceLevel,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserProfile.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw UserProfileException(error['error'] ?? 'Failed to save profile');
      }
    } catch (e) {
      if (e is UserProfileException) rethrow;
      throw UserProfileException('Network error: ${e.toString()}');
    }
  }

  /// Dispose
  void dispose() {
    // Don't dispose the singleton client
  }
}

/// Custom exception for user profile errors
class UserProfileException implements Exception {
  final String message;
  UserProfileException(this.message);

  @override
  String toString() => message;
}
