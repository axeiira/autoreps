import 'dart:convert';
import 'package:flutter_autoreps/core/network/api_client.dart';
import 'package:flutter_autoreps/core/config/api_config.dart';
import 'package:flutter_autoreps/features/home/data/models/workout_session.dart';

class WorkoutRepository {
  final ApiClient _apiClient;

  WorkoutRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Get workout history
  Future<List<WorkoutSession>> getWorkoutHistory() async {
    try {
      final response = await _apiClient.get(
        ApiConfig.workout,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data
            .map(
              (json) => WorkoutSession.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw WorkoutException(
          error['error'] ?? 'Failed to get workout history',
        );
      }
    } catch (e) {
      if (e is WorkoutException) rethrow;
      throw WorkoutException('Network error: ${e.toString()}');
    }
  }

  /// Calculate current streak from workout sessions
  int calculateStreak(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return 0;

    // Sort sessions by date descending (newest first)
    final sortedSessions = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime? previousDate;

    for (var session in sortedSessions) {
      final sessionDate = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      if (streak == 0) {
        // First session - must be today or yesterday to start a streak
        final daysDiff = todayDate.difference(sessionDate).inDays;
        if (daysDiff > 1) {
          // Too old, no current streak
          return 0;
        }
        streak = 1;
        previousDate = sessionDate;
      } else {
        // Check if this session is consecutive (1 day before previous)
        final daysDiff = previousDate!.difference(sessionDate).inDays;
        if (daysDiff == 1) {
          streak++;
          previousDate = sessionDate;
        } else if (daysDiff == 0) {
          // Same day, don't count but continue checking
          continue;
        } else {
          // Gap found, stop counting
          break;
        }
      }
    }

    return streak;
  }

  /// Dispose
  void dispose() {
    // Don't dispose the singleton client
  }
}

/// Custom exception for workout errors
class WorkoutException implements Exception {
  final String message;
  WorkoutException(this.message);

  @override
  String toString() => message;
}
