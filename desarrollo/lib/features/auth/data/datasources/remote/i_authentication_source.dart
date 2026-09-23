import '../../../domain/models/authentication_user.dart';

abstract class IAuthenticationSource {
  Future<bool> login(AuthenticationUser user);

  Future<bool> restoreSession();

  Future<AuthenticationUser?> getLoggedUser();

  Future<bool> signUp(AuthenticationUser user);

  Future<bool> logOut();

  Future<bool> validate(String email, String validationCode);

  Future<bool> refreshToken();

  Future<bool> forgotPassword(String email);

  Future<bool> resetPassword(
    String email,
    String newPassword,
    String validationCode,
  );

  Future<bool> verifyToken();

  /// True si quien tiene la sesión es un invitado, no una cuenta con correo.
  bool get isAnonymous;

  /// Abre una sesión de invitado si no hay ninguna, y la devuelve. Un
  /// invitado es un usuario real -tiene id, lo que escriba queda a su
  /// nombre- solo que sin correo ni clave.
  Future<AuthenticationUser> ensureGuestSession();
}
