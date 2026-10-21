import 'package:integration_test/integration_test_driver.dart';

/// Driver para correr las pruebas de integración en web (Chrome).
///
/// En Android, iOS y escritorio no hace falta: `flutter test integration_test`
/// ya habla con el dispositivo. En web se usa con `flutter drive`; los pasos
/// están en `integration_test/app_test.dart`.
Future<void> main() => integrationDriver();
