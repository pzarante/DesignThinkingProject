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
}) {
  Get.put<IAuthRepository>(_FakeAuthRepository(id: id, name: name, email: email));
}

class _FakeAuthRepository implements IAuthRepository {
  _FakeAuthRepository({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

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
  Future<bool> logOut() async => true;

  @override
  Future<bool> validate(String email, String validationCode) async => true;

  @override
  Future<bool> validateToken() async => true;

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  bool get isAnonymous => false;

  @override
  Future<AuthenticationUser> ensureGuestSession() async =>
      AuthenticationUser(id: id, email: email, name: name);
}
