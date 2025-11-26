/// Response model for login API
class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}

/// User model
class User {
  final int id;
  final String name;
  final String email;
  final DateTime createdAt;
  final int? age;
  final double? weight;
  final String? goal;
  final String? experienceLevel;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.age,
    this.weight,
    this.goal,
    this.experienceLevel,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      age: json['age'] as int?,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      goal: json['goal'] as String?,
      experienceLevel: json['experienceLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'age': age,
      'weight': weight,
      'goal': goal,
      'experienceLevel': experienceLevel,
    };
  }
}
