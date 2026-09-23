import 'package:roble/roble.dart';

/// Lee una tabla como pueda: normal si hay sesión, pública si no.
///
/// Sin esto, un visitante sin cuenta vería el catálogo vacío (o un 401) en
/// vez de lo publicado: `read()` exige sesión, y `publicRead()` es lo único
/// que un cliente sin iniciar sesión puede pedir. Requiere que la tabla esté
/// marcada como pública en la consola de ROBLE.
Future<List<Map<String, dynamic>>> readPublicOrPrivate(
  RobleApiDataBase db,
  String table, {
  Map<String, dynamic>? filters,
}) async {
  if (!db.isLoggedIn) return db.publicRead(table);
  return db.read(table, filters: filters);
}

/// Una fila por su `_id`, pública o privada según haya sesión.
///
/// `publicRead` no acepta filtros ni id: si no hay sesión, trae la tabla
/// entera y busca la fila en el cliente.
Future<Map<String, dynamic>?> getByIdPublicOrPrivate(
  RobleApiDataBase db,
  String table,
  String id,
) async {
  if (db.isLoggedIn) return db.getById(table, id);
  final rows = await db.publicRead(table);
  for (final row in rows) {
    if (row['_id'] == id) return row;
  }
  return null;
}
