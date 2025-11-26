/// User Profile model
class UserProfile {
  final int id;
  final int userId;
  final int age;
  final double weight;
  final String primaryGoal;
  final String experienceLevel;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    required this.age,
    required this.weight,
    required this.primaryGoal,
    required this.experienceLevel,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      userId: json['userId'] as int,
      age: json['age'] as int,
      weight: (json['weight'] as num).toDouble(),
      primaryGoal: json['primaryGoal'] as String,
      experienceLevel: json['experienceLevel'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'age': age,
      'weight': weight,
      'primaryGoal': primaryGoal,
      'experienceLevel': experienceLevel,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
