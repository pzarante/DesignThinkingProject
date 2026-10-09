import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:roble/roble.dart';

import 'package:f_clean_template/core/roble_cache.dart';

/// Servidor de mentira: cuenta las peticiones y responde lo que se le diga.
class _FakeClient extends http.BaseClient {
  _FakeClient({this.statusByTable = const {}, this.delay = Duration.zero});

  /// Estado HTTP por tabla; lo que no esté aquí responde 200.
  final Map<String, int> statusByTable;
  final Duration delay;

  final List<String> requestedTables = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final table = request.url.queryParameters['tableName'] ?? '';
    requestedTables.add(table);
    if (delay > Duration.zero) await Future<void>.delayed(delay);

    final status = statusByTable[table] ?? 200;
    final body = status == 200
        ? jsonEncode([
            {'_id': '$table-1', 'name': table},
          ])
        : jsonEncode({'message': 'no'});

    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      request: request,
    );
  }
}

class _MemoryStorage implements RobleTokenStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> getItem(String key) async => _values[key];

  @override
  Future<void> removeItem(String key) async => _values.remove(key);

  @override
  Future<void> setItem(String key, String value) async => _values[key] = value;
}

RobleTableCache _cacheWith(
  _FakeClient client, {
  Duration ttl = const Duration(minutes: 5),
  Duration readTimeout = const Duration(seconds: 20),
}) => RobleTableCache(
  RobleApiDataBase(
    config: RobleApiConfig.fromContract(
      baseUrl: 'https://example.test',
      contractId: 'proyecto',
    ),
    client: client,
    storage: _MemoryStorage(),
  ),
  ttl: ttl,
  readTimeout: readTimeout,
);

void main() {
  test('la segunda lectura sale de memoria, sin pedirla otra vez', () async {
    final client = _FakeClient();
    final cache = _cacheWith(client);

    await cache.read('projects');
    await cache.read('projects');

    expect(client.requestedTables, ['projects']);
  });

  test('dos lecturas a la vez de la misma tabla son una sola petición', () async {
    final client = _FakeClient(delay: const Duration(milliseconds: 20));
    final cache = _cacheWith(client);

    await Future.wait([cache.read('users'), cache.read('users')]);

    expect(client.requestedTables, ['users']);
  });

  test('ordenar lo devuelto no le cambia el orden a la siguiente lectura', () async {
    final client = _FakeClient();
    final cache = _cacheWith(client);

    final first = await cache.read('tags');
    first.clear();

    expect(await cache.read('tags'), hasLength(1));
  });

  test('un fallo dice de qué tabla fue', () async {
    final client = _FakeClient(statusByTable: {'project_members': 403});
    final cache = _cacheWith(client);

    await expectLater(
      cache.read('project_members'),
      throwsA(
        isA<RobleTableReadException>()
            .having((e) => e.table, 'tabla', 'project_members')
            .having((e) => '$e', 'mensaje', contains('project_members')),
      ),
    );
  });

  test('readAll junta todos los fallos en vez de solo el primero', () async {
    final client = _FakeClient(
      statusByTable: {'comments': 403, 'reactions': 500},
    );
    final cache = _cacheWith(client);

    await expectLater(
      cache.readAll(['projects', 'comments', 'reactions']),
      throwsA(
        isA<RobleReadFailure>().having(
          (e) => e.failures.map((f) => f.table).toList(),
          'tablas',
          ['comments', 'reactions'],
        ),
      ),
    );
  });

  test('readAll devuelve las tablas en el orden pedido', () async {
    final client = _FakeClient();
    final cache = _cacheWith(client);

    final rows = await cache.readAll(['a', 'b', 'c', 'd', 'e', 'f']);

    expect(rows, hasLength(6));
    expect(
      [for (final table in rows) table.single['name']],
      ['a', 'b', 'c', 'd', 'e', 'f'],
    );
  });

  test('una lectura que no responde no deja la pantalla colgada', () async {
    final client = _FakeClient(delay: const Duration(seconds: 2));
    final cache = _cacheWith(
      client,
      readTimeout: const Duration(milliseconds: 50),
    );

    await expectLater(
      cache.read('projects'),
      throwsA(
        isA<RobleTableReadException>().having(
          (e) => e.cause,
          'causa',
          isA<TimeoutException>(),
        ),
      ),
    );
  });
}
