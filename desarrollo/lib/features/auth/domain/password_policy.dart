/// Las reglas de contraseña que exige ROBLE al registrar una cuenta.
///
/// Están aquí, y no dentro de la pantalla, porque las necesitan dos sitios: el
/// formulario (para ir marcando lo que falta mientras se escribe) y el
/// controlador (para no gastar una llamada que el servidor va a rechazar con
/// un 400).
abstract final class PasswordPolicy {
  static const int minLength = 8;

  /// Los únicos símbolos que ROBLE acepta.
  static const String symbols = '!@#\$_-';

  static bool hasMinLength(String value) => value.length >= minLength;

  static bool hasUppercase(String value) => value.contains(RegExp(r'[A-Z]'));

  static bool hasLowercase(String value) => value.contains(RegExp(r'[a-z]'));

  static bool hasDigit(String value) => value.contains(RegExp(r'[0-9]'));

  static bool hasSymbol(String value) =>
      value.contains(RegExp(r'[!@#$_\-]'));

  static bool isValid(String value) =>
      hasMinLength(value) &&
      hasUppercase(value) &&
      hasLowercase(value) &&
      hasDigit(value) &&
      hasSymbol(value);

  /// Las reglas en el orden en que se enseñan bajo el campo.
  static List<({String label, bool Function(String) check})> get rules => [
    (label: 'Al menos $minLength caracteres', check: hasMinLength),
    (label: 'Una mayúscula', check: hasUppercase),
    (label: 'Una minúscula', check: hasLowercase),
    (label: 'Un número', check: hasDigit),
    (label: 'Un símbolo ($symbols)', check: hasSymbol),
  ];
}

/// Reglas del nombre de usuario, que es además cómo se busca a alguien en
/// Explorar: sin espacios para poder escribirlo como `@usuario`.
abstract final class UserNamePolicy {
  static const int minLength = 3;
  static const int maxLength = 20;

  static final RegExp _allowed = RegExp(r'^[a-zA-Z0-9._]+$');

  /// El motivo por el que no sirve, o null si está bien.
  static String? validate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Elige un nombre de usuario.';
    if (trimmed.length < minLength) {
      return 'Debe tener al menos $minLength caracteres.';
    }
    if (trimmed.length > maxLength) {
      return 'No puede pasar de $maxLength caracteres.';
    }
    if (!_allowed.hasMatch(trimmed)) {
      return 'Solo letras, números, punto y guion bajo.';
    }
    return null;
  }
}
