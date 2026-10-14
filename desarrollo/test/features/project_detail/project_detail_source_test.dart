import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_clean_template/features/project_detail/data/datasources/roble_project_detail_source.dart';
import 'package:f_clean_template/features/project_detail/domain/models/project_member.dart';
import 'package:f_clean_template/features/project_detail/domain/project_unavailable_exception.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_roble_server.dart';

Map<String, dynamic> _member(
  String user, {
  bool creator = false,
  bool coLeader = false,
  String status = 'active',
  String? role,
}) => {
  '_id': 'm-$user',
  'project_id': 'p1',
  'user_id': user,
  'is_creator': creator,
  'is_co_leader': coLeader,
  'status': status,
  'project_role_id': ?role,
};

RobleProjectDetailSource _sourceOver(FakeRobleServer server) {
  registerFakeAuth(id: 'owner');
  return RobleProjectDetailSource(
    server.db,
    server.cache,
    Get.find<IAuthRepository>(),
  );
}

void main() {
  tearDown(Get.reset);

  group('proyectos borrados', () {
    test('un proyecto disponible se abre', () async {
      final server = FakeRobleServer({
        'projects': [
          {'_id': 'p1', 'name': 'MotionLab', 'creator_id': 'owner'},
        ],
      });

      final detail = await _sourceOver(server).getDetail('p1');

      expect(detail?.name, 'MotionLab');
    });

    test('un proyecto borrado lanza ProjectUnavailableException', () async {
      final server = FakeRobleServer({
        'projects': [
          {
            '_id': 'p1',
            'name': 'MotionLab',
            'deleted_at': '2026-01-01T00:00:00Z',
          },
        ],
      });

      await expectLater(
        _sourceOver(server).getDetail('p1'),
        throwsA(isA<ProjectUnavailableException>()),
      );
    });

    test('un proyecto que no existe sigue dando null', () async {
      final server = FakeRobleServer({
        'projects': [
          {'_id': 'otro', 'name': 'Otro'},
        ],
      });

      expect(await _sourceOver(server).getDetail('p1'), isNull);
    });

    test('lee el proyecto filtrado por _id, no la tabla entera', () async {
      final server = FakeRobleServer({
        'projects': [
          {'_id': 'p1', 'name': 'MotionLab'},
        ],
      });

      await _sourceOver(server).getDetail('p1');

      expect(
        [for (final r in server.readsOf('projects')) r.filters],
        [
          {'_id': 'p1'},
        ],
      );
    });
  });

  group('guardar el equipo desde la configuración', () {
    FakeRobleServer teamServer() => FakeRobleServer({
      'projects': [
        {'_id': 'p1', 'name': 'MotionLab', 'creator_id': 'owner'},
      ],
      'project_members': [
        _member('owner', creator: true),
        _member('ana', role: 'slot-1'),
        _member('luis'),
      ],
      'project_roles': [
        {
          '_id': 'slot-1',
          'project_id': 'p1',
          'name': 'Dev',
          'status': 'filled',
        },
      ],
    });

    Future<Map<String, dynamic>> save(
      FakeRobleServer server, {
      required Set<String> baseline,
      required List<ProjectMember> target,
    }) async {
      final source = _sourceOver(server);
      final detail = (await source.getDetail('p1'))!;
      await source.saveDetail(
        detail.copyWith(members: target),
        originalMemberIds: baseline,
      );
      return {
        for (final row in server.rows('project_members'))
          row['user_id'] as String: row,
      };
    }

    ProjectMember person(String id, {bool coLeader = false}) =>
        ProjectMember(id: id, name: id, isCoLeader: coLeader);

    test('quien entró después de abrir la pantalla sigue activo', () async {
      final server = teamServer();
      // Al abrir la configuración solo estaban owner y ana.
      final baseline = {'owner', 'ana'};
      // Luego entra "luis" (ya está en la tabla) y la copia no lo conoce.
      final rows = await save(
        server,
        baseline: baseline,
        target: [
          const ProjectMember(id: 'owner', name: 'owner', isCreator: true),
          person('ana'),
        ],
      );

      expect(rows['luis']!['status'], 'active');
      expect(rows['ana']!['status'], 'active');
    });

    test(
      'a quien se quitó a propósito se le retira y se libera su cupo',
      () async {
        final server = teamServer();

        final rows = await save(
          server,
          baseline: {'owner', 'ana', 'luis'},
          target: [
            const ProjectMember(id: 'owner', name: 'owner', isCreator: true),
            person('luis'),
          ],
        );

        expect(rows['ana']!['status'], 'removed');
        expect(rows['ana']!['left_at'], isNotNull);
        expect(rows['luis']!['status'], 'active');
        final slot = server.rows('project_roles').single;
        expect(slot['status'], 'open');
        expect(slot['assigned_user_id'], isNull);
      },
    );

    test('quien se retira queda como historial, no se borra la fila', () async {
      final server = teamServer();

      await save(
        server,
        baseline: {'owner', 'ana', 'luis'},
        target: [
          const ProjectMember(id: 'owner', name: 'owner', isCreator: true),
        ],
      );

      expect(server.requests.where((r) => r.endpoint == 'delete'), isEmpty);
      expect(server.rows('project_members'), hasLength(3));
    });

    test('el creador no se retira aunque falte en la copia', () async {
      final server = teamServer();

      final rows = await save(
        server,
        baseline: {'owner', 'ana', 'luis'},
        target: [person('ana'), person('luis')],
      );

      expect(rows['owner']!['status'], 'active');
    });

    test('sin línea base no se retira a nadie', () async {
      final server = teamServer();

      final rows = await save(server, baseline: const {}, target: const []);

      expect([
        for (final row in rows.values) row['status'],
      ], everyElement('active'));
    });

    test(
      'actualiza al co-líder y suma a quien se añadió desde la pantalla',
      () async {
        final server = teamServer();

        final rows = await save(
          server,
          baseline: {'owner', 'ana', 'luis'},
          target: [
            const ProjectMember(id: 'owner', name: 'owner', isCreator: true),
            person('ana', coLeader: true),
            person('luis'),
            person('marta'),
          ],
        );

        expect(rows['ana']!['is_co_leader'], isTrue);
        expect(rows['marta']!['status'], 'active');
        expect(rows['marta']!['project_id'], 'p1');
      },
    );
  });

  group('aceptar una postulación (addMember)', () {
    FakeRobleServer server() => FakeRobleServer({
      'project_roles': [
        {'_id': 'slot-1', 'project_id': 'p1', 'name': 'Dev', 'status': 'open'},
        {'_id': 'slot-2', 'project_id': 'p1', 'name': 'Dev', 'status': 'open'},
      ],
    });

    Future<void> accept(RobleProjectDetailSource source) => source.addMember(
      projectId: 'p1',
      member: const ProjectMember(id: 'ana', name: 'Ana'),
      projectRoleId: 'slot-1',
    );

    test('reintentar no le quita un segundo cupo a la misma persona', () async {
      final fake = server();
      final source = _sourceOver(fake);

      await accept(source);
      await accept(source);

      final slots = fake.rows('project_roles');
      expect(slots.where((r) => r['assigned_user_id'] == 'ana').length, 1);
      expect(slots.last['status'], 'open');
      expect(fake.rows('project_members'), hasLength(1));
    });
  });
}
