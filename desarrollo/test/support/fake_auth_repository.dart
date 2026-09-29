import 'package:get/get.dart';

import 'package:f_clean_template/features/auth/domain/models/authentication_user.dart';
import 'package:f_clean_template/features/auth/domain/repositories/i_auth_repository.dart';

/// Sesión falsa para pruebas que dependen de "quién está conectado"
/// (`project_detail` la usa para `getCurrentUser()`), sin levantar la fuente
/// real de ROBLE ni requerir red.
void registerFakeAuth({
  String id = 'me',
  String name = 'María García',
  String email = 'maria@uni.edu',
  bool isAnonymous = false,
}) {
  Get.put<IAuthRepository>(
    _FakeAuthRepository(
      id: id,
      name: name,
      email: email,
      isAnonymous: isAnonymous,
    ),
  );
}

class _FakeAuthRepository implements IAuthRepository {
  _FakeAuthRepository({
    required this.id,
    required this.name,
    required this.email,
    required this.isAnonymous,
  });

  final String id;
  final String name;
  final String email;

  /// Sesión de invitado: cuenta real sin correo ni perfil en `users`.
  @override
  final bool isAnonymous;

  @override
  Future<AuthenticationUser?> getLoggedUser() async =>
      AuthenticationUser(id: id, email: email, name: name);

  @override
  Future<bool> login(AuthenticationUser user) async => true;

  @override
  Future<bool> restoreSession() async => true;

  @override
  Future<bool> signUp(AuthenticationUser user) async => true;

  @override
  Future<bool> isUserNameAvailable(String userName) async => true;

  @override
  Future<bool> logOut() async => true;

  @override
  Future<bool> validate(String email, String validationCode) async => true;

  @override
  Future<bool> validateToken() async => true;

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<AuthenticationUser> ensureGuestSession() async =>
      AuthenticationUser(id: id, email: email, name: name);
}
