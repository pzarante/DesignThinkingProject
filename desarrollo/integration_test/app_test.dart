import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'flows/auth_flow.dart';
import 'flows/community_creation_flow.dart';
import 'flows/project_application_flow.dart';
import 'flows/project_creation_flow.dart';

/// Pruebas de integración: la app completa, flujo por flujo, sobre las fuentes
/// en memoria (sin red ni ROBLE).
///
/// Todo entra por este archivo para que la app se compile y se lance una sola
/// vez: en escritorio, lanzar un archivo tras otro falla al arrancar el
/// segundo.
///
/// Con un emulador Android abierto (o un dispositivo conectado):
///
/// ```bash
/// flutter test integration_test/app_test.dart
/// # solo un flujo, por el nombre del grupo:
/// flutter test integration_test/app_test.dart --plain-name "Autenticación"
/// ```
/// 
/// En web, con ChromeDriver de la misma versión que Chrome:
///
/// ```bash
/// chromedriver --port=4444
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/app_test.dart -d chrome
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Autenticación', authFlowTests);
  group('Creación de proyecto', projectCreationFlowTests);
  group('Creación de comunidad', communityCreationFlowTests);
  group('Postulaciones y equipo', projectApplicationFlowTests);
}
