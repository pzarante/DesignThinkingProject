import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

/// Qué clase de aviso es, que es lo único que cambia entre uno y otro.
enum AppSnackKind { success, error, info }

/// Aviso flotante de la app: arriba, esmerilado y teñido según el caso.
///
/// Arriba y no abajo porque abajo lo tapan la barra de navegación y el botón
/// de crear, y porque un mensaje que aparece donde están los dedos se cierra
/// sin querer. El color es el tono "container" del tema (verde o rojo suave)
/// sobre desenfoque, con el texto en su tono oscuro correspondiente: mantiene
/// el efecto de cristal sin que el mensaje se pierda en el fondo.
void showAppSnack(
  String title, {
  String message = '',
  AppSnackKind kind = AppSnackKind.info,
}) {
  final colors = _colorsFor(kind);

  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    // Translúcido, no transparente: por debajo de esto el texto empieza a
    // competir con lo que haya detrás.
    backgroundColor: colors.background.withValues(alpha: 0.92),
    colorText: colors.foreground,
    barBlur: 18,
    borderColor: colors.accent.withValues(alpha: 0.35),
    borderWidth: 1,
    borderRadius: AppSpacing.md,
    margin: const EdgeInsets.all(AppSpacing.md),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    maxWidth: 520,
    icon: Icon(colors.icon, color: colors.accent),
    shouldIconPulse: false,
    isDismissible: true,
    boxShadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
    // Un error suele traer algo que leer y decidir; una confirmación, no.
    duration: Duration(seconds: kind == AppSnackKind.error ? 5 : 3),
  );
}

void showSuccessSnack(String title, {String message = ''}) =>
    showAppSnack(title, message: message, kind: AppSnackKind.success);

void showErrorSnack(String title, {String message = ''}) =>
    showAppSnack(title, message: message, kind: AppSnackKind.error);

void showInfoSnack(String title, {String message = ''}) =>
    showAppSnack(title, message: message, kind: AppSnackKind.info);

typedef _SnackColors = ({
  Color background,
  Color foreground,
  Color accent,
  IconData icon,
});

_SnackColors _colorsFor(AppSnackKind kind) {
  // `Get.context` es null antes de que haya un árbol montado (p. ej. en una
  // prueba unitaria); el tema claro de reserva evita que un aviso tumbe la
  // llamada que lo lanzó.
  final context = Get.context;
  final scheme = context == null
      ? ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4))
      : Theme.of(context).colorScheme;

  return switch (kind) {
    AppSnackKind.success => (
      background: AppSemanticColors.successContainer,
      foreground: AppSemanticColors.onSuccessContainer,
      accent: AppSemanticColors.success,
      icon: Icons.check_circle_outline,
    ),
    AppSnackKind.error => (
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
      accent: scheme.error,
      icon: Icons.error_outline,
    ),
    AppSnackKind.info => (
      background: scheme.surfaceContainerHighest,
      foreground: scheme.onSurface,
      accent: scheme.primary,
      icon: Icons.info_outline,
    ),
  };
}
