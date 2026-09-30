import 'package:roble/roble.dart';

/// La tabla no está marcada como pública en la consola de ROBLE.
///
/// Es distinto de un fallo de red o de permisos de la cuenta: la lectura
/// llegó al servidor y el servidor dijo que esa tabla no se puede leer sin
/// sesión. Se distingue con su propio tipo porque se arregla en un sitio muy
/// concreto —la consola— y antes se confundía con "no hay datos".
///
/// `errorMessage` no la conoce y cae en su `toString()`, así que este texto
/// es el que acaba viendo la persona.
class RobleTableNotPublicException implements Exception {
  const RobleTableNotPublicException(this.table);

  final String table;

  @override
  String toString() =>
      'La tabla "$table" no se puede leer sin iniciar sesión. Márcala como '
      'pública en la consola de ROBLE (Tablas → $table → acceso público) o '
      'inicia sesión.';
}

/// Lee una tabla como pueda: normal si hay sesión, pública si no.
///
/// Sin esto, un visitante sin cuenta vería un 401 en vez de lo publicado:
/// `read()` exige sesión, y `publicRead()` es lo único que un cliente sin
/// iniciar sesión puede pedir.
///
/// Un 403 se convierte en [RobleTableNotPublicException] en vez de devolver
/// una lista vacía. Devolverla en silencio era peor: la pantalla quedaba en
/// blanco sin decir por qué, y eso es indistinguible de "todavía no hay
/// nada".
Future<List<Map<String, dynamic>>> readPublicOrPrivate(
  RobleApiDataBase db,
  String table, {
  Map<String, dynamic>? filters,
}) async {
  if (db.isLoggedIn) return db.read(table, filters: filters);
  try {
    return await db.publicRead(table, filters: filters);
  } on RobleApiHttpException catch (exception) {
    if (exception.statusCode == 403) {
      throw RobleTableNotPublicException(table);
    }
    rethrow;
  }
}

/// Una fila por su `_id`, pública o privada según haya sesión.
Future<Map<String, dynamic>?> getByIdPublicOrPrivate(
  RobleApiDataBase db,
  String table,
  String id,
) async {
  if (db.isLoggedIn) return db.getById(table, id);
  for (final row in await readPublicOrPrivate(db, table)) {
    if (row['_id'] == id) return row;
  }
  return null;
}
