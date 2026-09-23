import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';

/// Authentication adapter for the official ROBLE Flutter SDK.
class RobleAuthenticationSource with UiLoggy implements IAuthenticationSource {
  RobleAuthenticationSource(this.roble);

  final RobleApiDataBase roble;
  AuthenticationUser? _loggedUser;

  @override
  Future<bool> login(AuthenticationUser user) async {
    loggy.debug('ROBLE login: ${user.email}');
    final profile = await roble.login(
      email: user.email.trim(),
      password: user.password,
    );
    _loggedUser = _mapUser(profile, fallbackEmail: user.email);
    return true;
  }

  @override
  Future<bool> signUp(AuthenticationUser user) async {
    loggy.debug('ROBLE sign up: ${user.email}');
    final profile = await roble.register(
      email: user.email.trim(),
      password: user.password,
      name: user.name.trim().isEmpty ? user.email.trim() : user.name.trim(),
      autoLogin: true,
    );
    _loggedUser = _mapUser(profile, fallbackEmail: user.email);
    return true;
  }

  @override
  Future<bool> logOut() async {
    await roble.logout();
    _loggedUser = null;
    return true;
  }

  @override
  Future<bool> restoreSession() async {
    final restored = await roble.restoreSession();
    if (!restored) {
      _loggedUser = null;
      return false;
    }
    _loggedUser = _mapUser(await roble.currentUser());
    return true;
  }

  @override
  Future<AuthenticationUser?> getLoggedUser() async {
    if (_loggedUser != null) return _loggedUser;
    try {
      _loggedUser = _mapUser(await roble.currentUser());
      return _loggedUser;
    } on RobleApiAuthException {
      return null;
    }
  }

  @override
  Future<bool> validate(String email, String validationCode) =>
      roble.verifyEmail(email: email, code: validationCode).then((_) => true);

  @override
  Future<bool> refreshToken() => restoreSession();

  @override
  Future<bool> forgotPassword(String email) async {
    await roble.forgotPassword(email: email.trim());
    return true;
  }

  @override
  Future<bool> resetPassword(
    String email,
    String newPassword,
    String validationCode,
  ) async {
    await roble.resetPassword(
      token: validationCode,
      newPassword: newPassword,
    );
    return true;
  }

  @override
  Future<bool> verifyToken() => restoreSession();

  AuthenticationUser _mapUser(
    Map<String, dynamic> profile, {
    String? fallbackEmail,
  }) {
    final email = (profile['email'] as String?) ?? fallbackEmail;
    if (email == null || email.isEmpty) {
      throw const FormatException('ROBLE returned a user without an email.');
    }
    final rawId = profile['id'] ?? profile['_id'];
    return AuthenticationUser(
      id: rawId is int ? rawId : int.tryParse('$rawId'),
      email: email,
      name: (profile['name'] as String?) ?? email,
      password: '',
    );
  }
}