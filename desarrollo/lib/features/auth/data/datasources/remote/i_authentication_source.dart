import '../../../domain/models/authentication_user.dart';

abstract class IAuthenticationSource {
  /// Inicia sesión. `user.email` admite el correo o el nombre de usuario:
  /// quien implemente esto se encarga de resolver el segundo.
  Future<bool> login(AuthenticationUser user);

  Future<bool> restoreSession();

  Future<AuthenticationUser?> getLoggedUser();

  Future<bool> signUp(AuthenticationUser user);

  /// True si nadie ha tomado todavía ese nombre de usuario.
  ///
  /// Se comprueba antes de registrar porque `user_name` es cómo se busca a
  /// una persona en Explorar: dos iguales harían la búsqueda ambigua, y el
  /// registro fallaría a medias (la cuenta de ROBLE creada, el perfil no).
  Future<bool> isUserNameAvailable(String userName);

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
