import 'package:roble/roble.dart';

import 'roble_read.dart';

/// Memoria corta de las tablas de ROBLE, compartida por toda la app.
///
/// Existe por cómo hay que leer de ROBLE: no hay joins ni agregados, así que
/// una sola pantalla termina pidiendo la misma tabla varias veces (`users`
/// para el creador, para el equipo y para los comentarios; `tags` para cada
/// proyecto). Cada una de esas era una petición HTTP completa, en fila, y es
/// lo que hacía que abrir un proyecto o un perfil se sintiera lento.
///
/// Hace dos cosas:
///
/// - **Une las peticiones en vuelo.** Si tres partes de la pantalla piden
///   `users` a la vez, sale una sola petición y las tres esperan su resultado.
/// - **Guarda el resultado un rato.** Dentro de [ttl] la siguiente lectura de
///   esa tabla no vuelve a la red.
///
/// Lo que se escribe invalida lo que se leyó: después de crear, actualizar o
/// borrar una fila hay que llamar a [invalidate] con las tablas tocadas, o la
/// pantalla seguiría enseñando lo de antes.
class RobleTableCache {
  RobleTableCache(this.db, {this.ttl = const Duration(seconds: 60)});

  /// El cliente por debajo. Las escrituras siguen yendo directas contra él:
  /// aquí solo se guardan lecturas.
  final RobleApiDataBase db;

  /// Cuánto se considera fresco lo leído. Corto a propósito: es para que una
  /// misma pantalla no repita peticiones, no para trabajar sin conexión.
  final Duration ttl;

  final Map<String, _CachedTable> _tables = {};
  final Map<String, Future<List<Map<String, dynamic>>>> _inFlight = {};

  /// Una tabla entera, de la memoria si sigue fresca.
  ///
  /// Con [refresh] se salta lo guardado, que es lo que quiere el gesto de
  /// "deslizar para actualizar".
  Future<List<Map<String, dynamic>>> read(
    String table, {
    bool refresh = false,
  }) {
    if (!refresh) {
      final cached = _tables[table];
      if (cached != null && !cached.isStale(ttl)) {
        return Future.value(cached.rows);
      }
      final pending = _inFlight[table];
      if (pending != null) return pending;
    }

    final request = readPublicOrPrivate(db, table)
        .then((rows) {
          _tables[table] = _CachedTable(rows);
          return rows;
        })
        .whenComplete(() => _inFlight.remove(table));

    _inFlight[table] = request;
    return request;
  }

  /// Varias tablas a la vez. Es la forma corta de `Future.wait`, que es lo
  /// que de verdad acelera una pantalla: lecturas en paralelo en vez de una
  /// detrás de otra.
  Future<List<List<Map<String, dynamic>>>> readAll(
    List<String> tables, {
    bool refresh = false,
  }) => Future.wait([
    for (final table in tables) read(table, refresh: refresh),
  ]);

  /// Una fila por su `_id`, a partir de la tabla ya cargada.
  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final rows = await read(table);
    for (final row in rows) {
      if (row['_id'] == id) return row;
    }
    return null;
  }

  /// Olvida lo guardado de esas tablas. Sin argumentos, olvida todo.
  void invalidate([List<String>? tables]) {
    if (tables == null) {
      _tables.clear();
      return;
    }
    for (final table in tables) {
      _tables.remove(table);
    }
  }
}

class _CachedTable {
  _CachedTable(this.rows) : readAt = DateTime.now();

  final List<Map<String, dynamic>> rows;
  final DateTime readAt;

  bool isStale(Duration ttl) => DateTime.now().difference(readAt) > ttl;
}
