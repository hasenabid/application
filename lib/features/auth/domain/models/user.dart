class User {
  final String id;
  final String email;
  final String name;
  final String token;
  final String role;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.token,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      token: json['token'] as String,
      role: json['role'] as String? ?? 'WORKER',
    );
  }
}
