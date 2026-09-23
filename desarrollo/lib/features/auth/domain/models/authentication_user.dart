class AuthenticationUser {
  String? id;
  final String email;
  final String name;
  final String? password;

  /// Lo que agrega el registro además de la cuenta de ROBLE (tabla `users`).
  /// Null en un usuario que ya inició sesión: eso se lee aparte, de `users`.
  final String? firstName;
  final String? lastName;
  final String? career;
  final int? academicYear;
  final String? bio;

  AuthenticationUser({
    this.id,
    required this.email,
    required this.name,
    this.password,
    this.firstName,
    this.lastName,
    this.career,
    this.academicYear,
    this.bio,
  });

  factory AuthenticationUser.fromJson(Map<String, dynamic> json) {
    return AuthenticationUser(
      id: json['id'] as String?,
      email: json['email'],
      name: json['name'],
      password: json['password'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name, 'password': password};
  }
}
