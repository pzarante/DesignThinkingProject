import 'package:roble/roble.dart';

/// Converts service errors into messages suitable for presentation.
String errorMessage(Object error, {String? fallback}) {
    if (fallback != null) return fallback;
    if (error is RobleApiNetworkException) {
        return 'No hay conexión con ROBLE. Revisa tu conexión a internet.';
    }
    if (error is RobleApiTimeoutException) {
        return 'ROBLE tardó demasiado en responder. Inténtalo de nuevo.';
    }
    if (error is RobleApiAuthException) {
        return 'Las credenciales no son válidas o la sesión expiró.';
    }
    if (error is RobleApiHttpException) {
        return switch (error.statusCode) {
            401 => 'No tienes una sesión válida en ROBLE.',
            403 => 'ROBLE rechazó la operación por falta de permisos.',
            404 => 'El recurso solicitado no existe en ROBLE.',
            _ => 'ROBLE no pudo completar la operación (${error.statusCode}).',
        };
    }
    if (error is RobleApiFormatException) {
        return 'ROBLE devolvió una respuesta inesperada.';
    }
    if (error is RobleApiException) {
        return 'ROBLE no pudo completar la operación.';
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}
