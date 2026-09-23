import 'package:roble/roble.dart';

/// Converts an unexpected error into a message suitable for presentation.
///
/// Maps ROBLE's typed exceptions to messages a user can act on; anything else
/// falls back to its own string representation.
String errorMessage(Object error, {String? fallback}) {
  if (fallback != null) return fallback;

  if (error is RobleApiForbiddenException) {
    return 'Tu cuenta no tiene permiso para hacer esto.';
  }
  if (error is RobleApiNotFoundException) {
    return 'No se encontró lo que buscabas.';
  }
  if (error is RobleApiHttpException) {
    return switch (error.statusCode) {
      401 => 'Correo o contraseña incorrectos.',
      409 => 'Ya existe una cuenta con ese correo.',
      _ => error.message,
    };
  }
  if (error is RobleApiNetworkException) {
    return 'Sin conexión. Verifica tu internet e inténtalo de nuevo.';
  }
  if (error is RobleApiTimeoutException) {
    return 'La operación tardó demasiado. Inténtalo de nuevo.';
  }
  if (error is RobleApiException) return error.message;

  return error.toString();
}
