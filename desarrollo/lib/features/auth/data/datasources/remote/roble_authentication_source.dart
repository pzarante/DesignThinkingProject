import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import '../../../../../core/roble_read.dart';
import '../../../domain/models/authentication_user.dart';
import '../../../domain/unknown_account_exception.dart';
import 'i_authentication_source.dart';

/// Habla con ROBLE sobre cuentas. No decide nada: convertir el mapa que
/// devuelve el servidor y traducir los fallos es del repositorio y de
/// `errorMessage`.
class RobleAuthenticationSource with UiLoggy implements IAuthenticationSource {
  RobleAuthenticationSource(this._db);

  final RobleApiDataBase _db;

  @override
  Future<bool> login(AuthenticationUser user) async {
    final profile = await _db.login(
      email: await _resolveEmail(user.email),
      password: user.password ?? '',
    );
    await _ensureUserRow(profile);
    return true;
  }

  /// Traduce lo que se escribió en el campo a un correo.
  ///
  /// ROBLE solo sabe entrar con correo, pero el nombre de usuario es lo que
  /// la gente ve y recuerda de sí misma, así que se acepta cualquiera de los
  /// dos: si lleva arroba es un correo y se usa tal cual; si no, se busca en
  /// `users` el correo de quien tenga ese `user_name`.
  ///
  /// La búsqueda va sin sesión (todavía no la hay), así que depende de que
  /// `users` esté marcada como pública en la consola. Si no lo está, el
  /// nombre de usuario no se puede resolver y solo funcionará el correo.
  Future<String> _resolveEmail(String identifier) async {
    final value = identifier.trim();
    if (value.contains('@')) return value;

    final normalized = value.toLowerCase();
    final rows = await readPublicOrPrivate(_db, 'users');
    final match = rows
        .where(
          (row) =>
              (row['user_name'] as String?)?.trim().toLowerCase() == normalized,
        )
        .firstOrNull;

    final email = match?['email'] as String?;
    if (email == null || email.isEmpty) {
      throw const UnknownAccountException(
        'No encontramos ninguna cuenta con ese nombre de usuario. '
        'Prueba con tu correo.',
      );
    }
    return email;
  }

  /// `users` es el perfil de la app, aparte de la cuenta de ROBLE: otras
  /// features (candidatos a co-líder, creador de un proyecto) lo leen por
  /// `user_id`. Se crea la primera vez que se ve ese `userId`: al hacer
  /// login (cualquier cuenta, incluida una creada antes de que existiera
  /// esta lógica) y, mejor aún, justo después de registrarse con los datos
  /// que trajo el formulario ([signupData]).
  Future<void> _ensureUserRow(
    Map<String, dynamic> profile, {
    AuthenticationUser? signupData,
  }) async {
    final userId = profile['userId'] as String;
    final existing = await _db.read('users', filters: {'user_id': userId});
    if (existing.isNotEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.create('users', {
      'user_id': userId,
      'user_name': (profile['name'] as String?) ?? (profile['email'] as String),
      'email': profile['email'],
      if (signupData?.firstName != null) 'first_name': signupData!.firstName,
      if (signupData?.lastName != null) 'last_name': signupData!.lastName,
      if (signupData?.career != null) 'career': signupData!.career,
      if (signupData?.academicYear != null)
        'academic_year': signupData!.academicYear,
      if (signupData?.bio != null) 'bio': signupData!.bio,
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
    // La cuenta ya existe aunque lo de abajo falle: entrar ahora es para
    // dejar listo el perfil en `users`, no lo que garantiza este método. Si
    // falla (red, servidor lento), la persona entra por su cuenta después y
    // `login()` deja el perfil listo en ese momento.
    try {
      final profile = await _db.login(
        email: user.email,
        password: user.password ?? '',
      );
      await _ensureUserRow(profile, signupData: user);
    } catch (exception) {
      // P. ej. "nombre de usuario" repetido (es único): la cuenta de ROBLE
      // ya existe, así que no se reporta como fallo, pero queda en el log
      // para poder diagnosticarlo en vez de perderse en silencio.
      loggy.warning(
        'RobleAuthenticationSource: no se pudo crear el perfil en users: $exception',
      );
    }
    return true;
  }

  /// Mira la tabla `users`, que es donde vive el nombre visible; la cuenta de
  /// ROBLE solo garantiza que el correo sea único.
  ///
  /// Se consulta sin sesión (quien se está registrando todavía no la tiene),
  /// así que depende de que `users` esté marcada como pública en la consola.
  /// Si no lo está no se puede comprobar, y entonces se deja pasar: perder el
  /// aviso temprano de un nombre repetido es mucho menos malo que impedir
  /// registrarse. Queda en el log para poder diagnosticarlo.
  @override
  Future<bool> isUserNameAvailable(String userName) async {
    final normalized = userName.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    try {
      final rows = await readPublicOrPrivate(_db, 'users');
      return !rows.any(
        (row) =>
            (row['user_name'] as String?)?.trim().toLowerCase() == normalized,
      );
    } on RobleTableNotPublicException catch (exception) {
      loggy.warning(
        'RobleAuthenticationSource: no se pudo comprobar el nombre de '
        'usuario: $exception',
      );
      return true;
    }
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
