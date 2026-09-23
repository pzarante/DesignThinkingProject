import 'package:roble/roble.dart';

import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';

/// Habla con ROBLE sobre cuentas. No decide nada: convertir el mapa que
/// devuelve el servidor y traducir los fallos es del repositorio y de
/// `errorMessage`.
class RobleAuthenticationSource implements IAuthenticationSource {
  RobleAuthenticationSource(this._db);

  final RobleApiDataBase _db;

  @override
  Future<bool> login(AuthenticationUser user) async {
    final profile = await _db.login(
      email: user.email,
      password: user.password ?? '',
    );
    await _ensureUserRow(profile);
    return true;
  }

  /// `users` es el perfil de la app, aparte de la cuenta de ROBLE: otras
  /// features (candidatos a co-líder, creador de un proyecto) lo leen por
  /// `user_id`. Se crea la primera vez que se ve ese `userId`, no en
  /// `signUp`, porque registrar una cuenta no deja sesión abierta para poder
  /// escribir la tabla todavía.
  Future<void> _ensureUserRow(Map<String, dynamic> profile) async {
    final userId = profile['userId'] as String;
    final existing = await _db.read('users', filters: {'user_id': userId});
    if (existing.isNotEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.create('users', {
      'user_id': userId,
      'user_name': (profile['name'] as String?) ?? (profile['email'] as String),
      'email': profile['email'],
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<bool> restoreSession() => _db.restoreSession();

  @override
  Future<AuthenticationUser?> getLoggedUser() async {
    if (!_db.isLoggedIn) return null;
    return _toUser(await _db.currentUser());
  }

  @override
  Future<bool> signUp(AuthenticationUser user) async {
    await _db.register(
      email: user.email,
      password: user.password ?? '',
      name: user.name,
    );
    // `register` no deja sesión abierta ni siempre devuelve el userId; se
    // entra un momento para poder crear el perfil de la app en `users`, la
    // tabla propia que las demás tablas referencian (ver ESQUEMA_BD_ROBLE.md).
    await _db.login(email: user.email, password: user.password ?? '');
    await _ensureUserProfile(user.name);
    return true;
  }

  Future<void> _ensureUserProfile(String name) async {
    final profile = await _db.currentUser();
    final userId = profile['userId'] as String?;
    if (userId == null) return;

    final existing = await _db.read('users', filters: {'user_id': userId});
    if (existing.isNotEmpty) return;

    await _db.create('users', {
      'user_id': userId,
      'user_name': name,
      'email': (profile['email'] as String?) ?? '',
    });
  }

  @override
  Future<bool> logOut() async {
    await _db.logout();
    return true;
  }

  @override
  Future<bool> validate(String email, String validationCode) async {
    await _db.verifyEmail(email: email, code: validationCode);
    return true;
  }

  @override
  Future<bool> refreshToken() async {
    // El paquete guarda y refresca los tokens por su cuenta; no hay nada que
    // pedirle aparte.
    return true;
  }

  @override
  Future<bool> forgotPassword(String email) async {
    await _db.forgotPassword(email: email);
    return true;
  }

  @override
  Future<bool> resetPassword(
    String email,
    String newPassword,
    String validationCode,
  ) async {
    await _db.resetPassword(token: validationCode, newPassword: newPassword);
    return true;
  }

  @override
  Future<bool> verifyToken() async {
    if (!_db.isLoggedIn) return false;
    try {
      await _db.currentUser();
      return true;
    } on RobleApiException {
      return false;
    }
  }

  @override
  bool get isAnonymous => _db.isAnonymous;

  @override
  Future<AuthenticationUser> ensureGuestSession() async {
    if (!_db.isLoggedIn) await _db.signInAnonymously();
    return _toUser(await _db.currentUser());
  }

  AuthenticationUser _toUser(Map<String, dynamic> profile) =>
      AuthenticationUser(
        id: profile['userId'] as String?,
        email: (profile['email'] as String?) ?? '',
        name: (profile['name'] as String?) ?? '',
      );
}
