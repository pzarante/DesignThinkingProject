import 'package:flutter_test/flutter_test.dart';

import 'package:f_clean_template/app_routes.dart';

/// Comprobaciones del mapa de rutas.
///
/// Lo que había aquí era la prueba del contador que viene con `flutter
/// create`: montaba un `MyApp` con un `+` que esta app nunca tuvo. Se cambió
/// por algo que sí dice si el mapa de navegación está sano.
void main() {
  test('cada destino de la barra inferior tiene su pantalla', () {
    for (final destination in AppRoutes.mainDestinations) {
      expect(
        AppRoutes.isRegistered(destination),
        isTrue,
        reason: '$destination está en la barra pero no en `pages`',
      );
    }
  });

  test('no hay dos rutas con el mismo nombre', () {
    final names = AppRoutes.pages.map((page) => page.name).toList();
    expect(names.toSet(), hasLength(names.length));
  });

  test('las rutas empiezan por barra', () {
    for (final page in AppRoutes.pages) {
      expect(page.name, startsWith('/'));
    }
  });
}
