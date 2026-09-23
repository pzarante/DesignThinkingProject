import '../models/authentication_user.dart';

abstract class IAuthRepository {
  Future<bool> login(AuthenticationUser user);

  Future<bool> restoreSession();

  Future<AuthenticationUser?> getLoggedUser();

  Future<bool> signUp(AuthenticationUser user);

  Future<bool> logOut();

  Future<bool> validate(String email, String validationCode);

  Future<bool> validateToken();

  Future<void> forgotPassword(String email);

  /// True si quien tiene la sesión es un invitado, no una cuenta con correo.
  bool get isAnonymous;

  /// Abre una sesión de invitado si no hay ninguna, y la devuelve.
  Future<AuthenticationUser> ensureGuestSession();
}
