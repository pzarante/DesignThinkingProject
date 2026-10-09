import 'dart:async';

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
  RobleTableCache(
    this.db, {
    this.ttl = const Duration(seconds: 60),
    this.readTimeout = const Duration(seconds: 20),
  });

  /// El cliente por debajo. Las escrituras siguen yendo directas contra él:
  /// aquí solo se guardan lecturas.
  final RobleApiDataBase db;

  /// Cuánto se considera fresco lo leído. Corto a propósito: es para que una
  /// misma pantalla no repita peticiones, no para trabajar sin conexión.
  final Duration ttl;

  /// Tope por lectura, para que ninguna pantalla se quede cargando para
  /// siempre esperando una respuesta que no va a llegar.
  final Duration readTimeout;

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
        // Copia de la lista: quien la reciba puede ordenarla sin cambiarle
        // el orden a la siguiente pantalla que pida la misma tabla.
        return Future.value(List.of(cached.rows));
      }
      final pending = _inFlight[table];
      if (pending != null) return pending;
    }

    final request = readPublicOrPrivate(db, table)
        // Tope propio además del que trae el paquete: sobre web una petición
        // que se queda a medias deja la pantalla girando sin decir nada.
        // Mejor un error que se pueda leer.
        .timeout(
          readTimeout,
          onTimeout: () => throw TimeoutException(
            'tardó más de ${readTimeout.inSeconds} s en responder',
            readTimeout,
          ),
        )
        .then((rows) {
          _tables[table] = _CachedTable(rows);
          return List.of(rows);
        })
        // Cualquier fallo sale con el nombre de la tabla pegado: sin esto, el
        // mensaje que llegaba a la pantalla no decía cuál de las diez
        // lecturas de esa pantalla fue la que se rompió.
        .onError<Object>(
          (error, stackTrace) => throw RobleTableReadException(table, error),
        )
        // Cuerpo de bloque, no flecha: `Map.remove` devuelve el valor
        // borrado —que aquí es esta misma petición—, y `whenComplete` se
        // queda esperando el futuro que le devuelva la función. Con la
        // flecha, la petición se esperaba a sí misma y no terminaba nunca.
        .whenComplete(() {
          _inFlight.remove(table);
        });

    _inFlight[table] = request;
    return request;
  }

  /// Cuántas lecturas se dejan ir a la vez.
  ///
  /// Los navegadores abren como mucho seis conexiones por dominio: lanzar
  /// diez de golpe no las hace más rápidas, encola las últimas detrás de las
  /// primeras y encima cada una gasta su tiempo de espera mientras aguarda
  /// turno. Y sobre web cada GET lleva antes su `OPTIONS` de CORS, así que el
  /// número real de viajes es el doble.
  static const int _maxConcurrent = 4;

  /// Varias tablas, en paralelo pero de cuatro en cuatro.
  ///
  /// Si alguna falla, se esperan todas y se lanza un solo error que dice
  /// cuáles fueron. Con `Future.wait` a secas solo se veía el primer fallo y
  /// los demás quedaban como errores asíncronos sin dueño, que en web salen
  /// como un `DartError` suelto sin relación aparente con la pantalla.
  Future<List<List<Map<String, dynamic>>>> readAll(
    List<String> tables, {
    bool refresh = false,
  }) async {
    final rows = <List<Map<String, dynamic>>>[];
    final failures = <RobleTableReadException>[];

    for (var start = 0; start < tables.length; start += _maxConcurrent) {
      final end = (start + _maxConcurrent).clamp(0, tables.length);
      final batch = await Future.wait([
        for (final table in tables.sublist(start, end))
          read(table, refresh: refresh).then<Object>(
            (result) => result,
            onError: (Object error) => error as RobleTableReadException,
          ),
      ]);
      for (final outcome in batch) {
        if (outcome is RobleTableReadException) {
          failures.add(outcome);
          rows.add(const []);
        } else {
          rows.add(outcome as List<Map<String, dynamic>>);
        }
      }
    }

    if (failures.isNotEmpty) throw RobleReadFailure(failures);
    return rows;
  }

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

/// Una lectura concreta que falló, con el nombre de la tabla delante.
class RobleTableReadException implements Exception {
  const RobleTableReadException(this.table, this.cause);

  final String table;
  final Object cause;

  @override
  String toString() => 'No se pudo leer "$table": $cause';
}

/// Varias lecturas de una misma pantalla que fallaron.
class RobleReadFailure implements Exception {
  const RobleReadFailure(this.failures);

  final List<RobleTableReadException> failures;

  @override
  String toString() => failures.map((failure) => '$failure').join('\n');
}
