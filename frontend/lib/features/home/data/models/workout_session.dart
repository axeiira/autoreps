/// Workout Session model
class WorkoutSession {
  final int id;
  final int userId;
  final int reps;
  final int validReps;
  final int invalidReps;
  final int durationSec;
  final DateTime date;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.reps,
    required this.validReps,
    required this.invalidReps,
    required this.durationSec,
    required this.date,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as int,
      userId: json['userId'] as int,
      reps: json['reps'] as int,
      validReps: json['validReps'] as int,
      invalidReps: json['invalidReps'] as int,
      durationSec: json['durationSec'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'reps': reps,
      'validReps': validReps,
      'invalidReps': invalidReps,
      'durationSec': durationSec,
      'date': date.toIso8601String(),
    };
  }
}
