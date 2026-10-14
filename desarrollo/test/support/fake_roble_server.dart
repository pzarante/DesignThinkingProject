import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:roble/roble.dart';

import 'package:f_clean_template/core/roble_cache.dart';

/// Una petición que llegó al servidor falso.
class FakeRobleRequest {
  const FakeRobleRequest(this.endpoint, this.table, this.filters);

  /// `read`, `public-read`, `insert-one`, `update` o `delete`.
  final String endpoint;
  final String table;

  /// Igualdades que viajaron en la lectura, sin el nombre de la tabla.
  final Map<String, String> filters;

  bool get isRead => endpoint == 'read' || endpoint == 'public-read';
}

/// ROBLE de mentira, en memoria: tablas editables que responden lecturas con
/// filtros de igualdad y aceptan escrituras, para probar fuentes de datos de
/// punta a punta sin red.
class FakeRobleServer extends http.BaseClient {
  FakeRobleServer([Map<String, List<Map<String, dynamic>>> seed = const {}])
    : tables = {
        for (final entry in seed.entries)
          entry.key: [
            for (final row in entry.value) {...row},
          ],
      };

  final Map<String, List<Map<String, dynamic>>> tables;
  final List<FakeRobleRequest> requests = [];
  int _nextId = 1;

  late final RobleApiDataBase db = RobleApiDataBase(
    config: RobleApiConfig.fromContract(
      baseUrl: 'https://example.test',
      contractId: 'proyecto',
    ),
    client: this,
    storage: _MemoryStorage(),
  );

  late final RobleTableCache cache = RobleTableCache(
    db,
    ttl: const Duration(minutes: 5),
  );

  /// Lecturas hechas a [table], con sus filtros.
  List<FakeRobleRequest> readsOf(String table) => [
    for (final request in requests)
      if (request.isRead && request.table == table) request,
  ];

  List<Map<String, dynamic>> rows(String table) =>
      tables.putIfAbsent(table, () => []);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final endpoint = request.url.pathSegments.last;
    final query = request.url.queryParameters;
    final body = request is http.Request && request.body.isNotEmpty
        ? jsonDecode(request.body) as Map<String, dynamic>
        : const <String, dynamic>{};

    final Object result;
    switch (endpoint) {
      case 'read' || 'public-read':
        final table = query['tableName']!;
        final filters = {...query}..remove('tableName');
        requests.add(FakeRobleRequest(endpoint, table, filters));
        result = [
          for (final row in rows(table))
            if (filters.entries.every((e) => '${row[e.key]}' == e.value))
              {...row},
        ];
      case 'insert-one':
        final table = body['tableName'] as String;
        requests.add(FakeRobleRequest(endpoint, table, const {}));
        final row = {
          ...(body['record'] as Map<String, dynamic>),
          '_id': 'new-${_nextId++}',
        };
        rows(table).add(row);
        result = row;
      case 'update':
        final table = body['tableName'] as String;
        requests.add(FakeRobleRequest(endpoint, table, const {}));
        final row = rows(table).firstWhere((r) => r['_id'] == body['idValue']);
        row.addAll(body['updates'] as Map<String, dynamic>);
        result = row;
      case 'delete':
        final table = body['tableName'] as String;
        requests.add(FakeRobleRequest(endpoint, table, const {}));
        rows(table).removeWhere((r) => r['_id'] == body['idValue']);
        result = const <String, dynamic>{};
      default:
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"message":"no"}')),
          404,
          request: request,
        );
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(result))),
      200,
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
