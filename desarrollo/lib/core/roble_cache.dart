import 'dart:async';

import 'dart:convert';

import 'package:loggy/loggy.dart';
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

  /// Una tabla, de la memoria si sigue fresca.
  ///
  /// Con [filters] la filtra el servidor (ROBLE solo admite igualdad) y viaja
  /// menos: es lo que hay que usar cuando solo importan las filas de una
  /// persona o de un estado. Cada combinación de filtros se guarda aparte.
  ///
  /// Con [refresh] se salta lo guardado, que es lo que quiere el gesto de
  /// "deslizar para actualizar".
  Future<List<Map<String, dynamic>>> read(
    String table, {
    Map<String, dynamic>? filters,
    bool refresh = false,
  }) {
    final key = _keyFor(table, filters);
    if (!refresh) {
      final cached = _tables[key];
      if (cached != null && !cached.isStale(ttl)) {
        // Copia de la lista: quien la reciba puede ordenarla sin cambiarle
        // el orden a la siguiente pantalla que pida la misma tabla.
        return Future.value(List.of(cached.rows));
      }
      final pending = _inFlight[key];
      if (pending != null) return pending;
    }

    final stopwatch = Stopwatch()..start();
    final request = readPublicOrPrivate(db, table, filters: filters)
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
          _logRead(key, rows, stopwatch);
          _tables[key] = _CachedTable(rows);
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
          _inFlight.remove(key);
        });

    _inFlight[key] = request;
    return request;
  }

  /// TEMPORAL: tamaño y duración de cada lectura de red, solo en debug, para
  /// decidir con datos si `users` o `project_role_skills` hay que tocarlas.
  /// Quitar cuando se haya medido.
  void _logRead(String key, List<Map<String, dynamic>> rows, Stopwatch watch) {
    assert(() {
      final bytes = utf8.encode(jsonEncode(rows)).length;
      logDebug(
        'RobleTableCache: $key → ${rows.length} filas, $bytes B, '
        '${watch.elapsedMilliseconds} ms',
      );
      return true;
    }());
  }

  /// Clave de una lectura: la tabla sola, o la tabla con sus filtros en un
  /// orden fijo para que `{a, b}` y `{b, a}` sean la misma lectura.
  static String _keyFor(String table, Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) return table;
    final names = filters.keys.toList()..sort();
    return '$table?${[for (final name in names) '$name=${filters[name]}'].join('&')}';
  }

  /// Cuántas lecturas se dejan ir a la vez.
  ///
  /// Los navegadores abren como mucho seis conexiones por dominio: lanzar
  /// diez de golpe no las hace más rápidas, encola las últimas detrás de las
  /// primeras y encima cada una gasta su tiempo de espera mientras aguarda
  /// turno. Y sobre web cada GET lleva antes su `OPTIONS` de CORS, así que el
  /// número real de viajes es el doble.
  static const int _maxConcurrent = 4;

  /// Varias tablas, en paralelo con un máximo de [_maxConcurrent] a la vez.
  ///
  /// Si alguna falla, se esperan todas y se lanza un solo error que dice
  /// cuáles fueron. Con `Future.wait` a secas solo se veía el primer fallo y
  /// los demás quedaban como errores asíncronos sin dueño, que en web salen
  /// como un `DartError` suelto sin relación aparente con la pantalla.
  Future<List<List<Map<String, dynamic>>>> readAll(
    List<String> tables, {
    bool refresh = false,
  }) => readQueries([
    for (final table in tables) RobleQuery(table),
  ], refresh: refresh);

  /// Como [readAll], pero cada lectura puede llevar sus filtros.
  ///
  /// Las lecturas salen en cuanto queda un hueco, no por tandas: con tandas
  /// fijas la siguiente no arrancaba hasta que terminaba la más lenta de la
  /// anterior, y una sola tabla pesada retrasaba a todas las demás.
  Future<List<List<Map<String, dynamic>>>> readQueries(
    List<RobleQuery> queries, {
    bool refresh = false,
  }) async {
    final rows = List<List<Map<String, dynamic>>>.filled(
      queries.length,
      const [],
    );
    final failures = <RobleTableReadException>[];
    var next = 0;

    Future<void> worker() async {
      while (next < queries.length) {
        final index = next++;
        final query = queries[index];
        try {
          rows[index] = await read(
            query.table,
            filters: query.filters,
            refresh: refresh,
          );
        } on RobleTableReadException catch (failure) {
          failures.add(failure);
        }
      }
    }

    await Future.wait([
      for (var i = 0; i < _maxConcurrent && i < queries.length; i++) worker(),
    ]);

    if (failures.isNotEmpty) {
      // Se acaban en el orden en que fallan, no en el pedido.
      failures.sort(
        (a, b) => queries
            .indexWhere((q) => q.table == a.table)
            .compareTo(queries.indexWhere((q) => q.table == b.table)),
      );
      throw RobleReadFailure(failures);
    }
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
      // Tanto la tabla entera como cualquiera de sus lecturas filtradas.
      _tables.removeWhere(
        (key, _) => key == table || key.startsWith('$table?'),
      );
    }
  }
}

/// Una lectura pedida a [RobleTableCache.readQueries].
class RobleQuery {
  const RobleQuery(this.table, [this.filters]);

  final String table;

  /// Igualdades que aplica el servidor; null o vacío es la tabla entera.
  final Map<String, dynamic>? filters;
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
