import 'package:flutter/material.dart';

/// Roles de color que el [ColorScheme] de Material 3 no cubre.
///
/// El Figma usa verde para publicar un proyecto y para las pantallas de
/// confirmación; la paleta base (`FlexScheme.material`) no tiene un rol verde,
/// así que se define aquí en vez de repetir literales pantalla por pantalla.
abstract final class AppSemanticColors {
  static const Color success = Color(0xFF1B7A3D);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFE3F2E7);
  static const Color onSuccessContainer = Color(0xFF0B5128);
}
