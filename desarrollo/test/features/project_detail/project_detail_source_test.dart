import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_clean_template/features/project_detail/data/datasources/roble_project_detail_source.dart';
import 'package:f_clean_template/features/project_detail/domain/models/project_member.dart';
import 'package:f_clean_template/features/project_detail/domain/models/project_role.dart';
import 'package:f_clean_template/features/project_detail/domain/models/publication.dart';
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
          'status': 'assigned',
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

  group('addMember a medias o con cambio de rol', () {
    test('si falla llenar el cupo, reintentar lo llena', () async {
      final fake = FakeRobleServer({
        'project_roles': [
          {
            '_id': 'slot-1',
            'project_id': 'p1',
            'name': 'Dev',
            'status': 'open',
          },
          {
            '_id': 'slot-2',
            'project_id': 'p1',
            'name': 'Dev',
            'status': 'open',
          },
        ],
      });
      final source = _sourceOver(fake);
      Future<void> accept() => source.addMember(
        projectId: 'p1',
        member: const ProjectMember(id: 'ana', name: 'Ana'),
        projectRoleId: 'slot-1',
      );

      fake.failOnce.add('update:project_roles');
      await expectLater(accept(), throwsA(anything));
      await accept();

      final slots = {for (final r in fake.rows('project_roles')) r['_id']: r};
      expect(slots['slot-1']!['assigned_user_id'], 'ana');
      expect(slots['slot-1']!['status'], 'assigned');
      expect(slots['slot-2']!['status'], 'open');
      expect(fake.rows('project_members'), hasLength(1));
    });

    test('aceptar en otro rol a quien ya está le cambia el cupo', () async {
      final fake = FakeRobleServer({
        'project_members': [_member('ana', role: 'slot-1')],
        'project_roles': [
          {
            '_id': 'slot-1',
            'project_id': 'p1',
            'name': 'Dev',
            'status': 'assigned',
            'assigned_user_id': 'ana',
          },
          {'_id': 'slot-3', 'project_id': 'p1', 'name': 'UX', 'status': 'open'},
        ],
      });

      await _sourceOver(fake).addMember(
        projectId: 'p1',
        member: const ProjectMember(id: 'ana', name: 'Ana'),
        projectRoleId: 'slot-3',
      );

      final slots = {for (final r in fake.rows('project_roles')) r['_id']: r};
      expect(fake.rows('project_members').single['project_role_id'], 'slot-3');
      expect(slots['slot-3']!['assigned_user_id'], 'ana');
      expect(slots['slot-1']!['status'], 'open');
      expect(slots['slot-1']!['assigned_user_id'], isNull);
    });
  });

  group('guardar roles con postulaciones pendientes', () {
    FakeRobleServer rolesServer(List<String> pendingSlots) => FakeRobleServer({
      'projects': [
        {'_id': 'p1', 'name': 'MotionLab', 'creator_id': 'owner'},
      ],
      'project_members': [_member('owner', creator: true)],
      'project_roles': [
        {'_id': 'slot-1', 'project_id': 'p1', 'name': 'Dev', 'status': 'open'},
        {'_id': 'slot-2', 'project_id': 'p1', 'name': 'Dev', 'status': 'open'},
      ],
      'project_applications': [
        for (final slot in pendingSlots)
          {'_id': 'a-$slot', 'project_role_id': slot, 'status': 'pending'},
      ],
    });

    Future<void> saveWithSlots(FakeRobleServer server, int slots) async {
      final source = _sourceOver(server);
      final detail = (await source.getDetail('p1'))!;
      await source.saveDetail(
        detail.copyWith(
          name: 'Nuevo nombre',
          openRoles: [
            for (final role in detail.openRoles)
              if (slots > 0) role.copyWith(totalSlots: slots),
          ],
        ),
      );
    }

    test('al bajar cupos se borra el que nadie pidió', () async {
      final server = rolesServer(['slot-2']);

      await saveWithSlots(server, 1);

      expect(server.rows('project_roles').single['_id'], 'slot-2');
    });

    test('al bajar cupos no borra el que se acaba de asignar', () async {
      final server = rolesServer([]);
      final source = _sourceOver(server);
      final detail = (await source.getDetail('p1'))!;

      await source.saveDetail(
        detail.copyWith(
          members: [
            ...detail.members,
            const ProjectMember(
              id: 'ana',
              name: 'ana',
              projectRoleId: 'slot-2',
            ),
          ],
          openRoles: [detail.openRoles.single.copyWith(totalSlots: 1)],
        ),
      );

      final slot = server.rows('project_roles').single;
      expect(slot['_id'], 'slot-2');
      expect(slot['assigned_user_id'], 'ana');
    });

    test('una vacante sin guardar se asigna al guardar', () async {
      final server = rolesServer([]);
      final source = _sourceOver(server);
      final detail = (await source.getDetail('p1'))!;
      const design = ProjectRole(title: 'UX');

      await source.saveDetail(
        detail.copyWith(
          members: [
            ...detail.members,
            ProjectMember(
              id: 'ana',
              name: 'ana',
              projectRoleId: design.pendingSlotId,
            ),
          ],
          openRoles: [...detail.openRoles, design],
        ),
      );

      final slot = server
          .rows('project_roles')
          .singleWhere((r) => r['name'] == 'UX');
      expect(slot['assigned_user_id'], 'ana');
      final ana = server
          .rows('project_members')
          .singleWhere((r) => r['user_id'] == 'ana');
      expect(ana['project_role_id'], slot['_id']);
    });

    test('el tope del equipo sale de los cupos de las vacantes', () async {
      final detail = (await _sourceOver(rolesServer([])).getDetail('p1'))!;

      // El creador (sin cupo) más los dos cupos de "Dev".
      expect(detail.maxMembers, 3);
    });

    test('no deja quitar un cupo con postulación pendiente', () async {
      final server = rolesServer(['slot-1', 'slot-2']);

      await expectLater(
        saveWithSlots(server, 0),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('postulaciones pendientes'),
          ),
        ),
      );
      expect(server.rows('project_roles'), hasLength(2));
      expect(server.rows('projects').single['name'], 'MotionLab');
    });
  });

  test('quitar a alguien cuyo rol se archivó no reabre la vacante', () async {
    final server = FakeRobleServer({
      'projects': [
        {'_id': 'p1', 'name': 'MotionLab', 'creator_id': 'owner'},
      ],
      'project_members': [
        _member('owner', creator: true),
        _member('ana', role: 'slot-1'),
      ],
      'project_roles': [
        {
          '_id': 'slot-1',
          'project_id': 'p1',
          'name': 'Dev',
          'status': 'assigned',
          'assigned_user_id': 'ana',
        },
      ],
    });
    final source = _sourceOver(server);
    final detail = (await source.getDetail('p1'))!;

    // En un mismo guardado: se quita el rol y a quien lo ocupaba.
    await source.saveDetail(
      detail.copyWith(
        openRoles: const [],
        members: [
          for (final m in detail.members)
            if (m.id != 'ana') m,
        ],
      ),
      originalMemberIds: {'owner', 'ana'},
    );

    expect(server.rows('project_roles').single['status'], 'closed');
    expect((await source.getDetail('p1'))!.openRoles, isEmpty);
  });

  group('publicaciones en ROBLE', () {
    FakeRobleServer wall() => FakeRobleServer({
      'projects': [
        {
          '_id': 'p1',
          'name': 'MotionLab',
          'creator_id': 'owner',
          'progress_percent': 40,
        },
      ],
      'users': [
        {'user_id': 'owner', 'user_name': 'Natalia'},
      ],
    });

    test(
      'un avance con imagen y enlace se guarda y se vuelve a leer',
      () async {
        final server = wall();
        final source = _sourceOver(server);

        await source.createPublication(
          const Publication(
            id: '',
            projectId: 'p1',
            authorName: 'Natalia',
            title: 'Primer prototipo',
            content: 'Ya se puede probar.',
            imageUrl: 'https://x.test/proto.png',
            linkUrl: 'https://figma.com/file/abc',
          ),
        );

        final update = server.rows('project_updates').single;
        expect(update['progress_percent'], 40);
        expect(
          {
            for (final m in server.rows('project_media'))
              m['media_type']: m['file_url'],
          },
          {
            'image': 'https://x.test/proto.png',
            'document': 'https://figma.com/file/abc',
          },
        );

        final read = (await source.getPublications('p1')).single;
        expect(read.title, 'Primer prototipo');
        expect(read.authorName, 'Natalia');
        expect(read.imageUrl, 'https://x.test/proto.png');
        expect(read.linkUrl, 'https://figma.com/file/abc');
      },
    );

    test('una encuesta se vota, y votar otra vez cambia el voto', () async {
      final server = wall();
      final source = _sourceOver(server);

      final poll = await source.createPublication(
        const Publication(
          id: '',
          projectId: 'p1',
          authorName: 'Natalia',
          title: '¿Qué color?',
          content: '',
          pollOptions: ['Azul', 'Verde'],
        ),
      );
      await source.votePoll(poll, 'Azul');
      await source.votePoll(poll, 'Verde');

      expect(server.rows('poll_responses'), hasLength(1));
      final read = (await source.getPublications('p1')).single;
      expect(read.pollOptions, ['Azul', 'Verde']);
      expect(read.pollVotes, {'Azul': 0, 'Verde': 1});
      expect(read.selectedPollOption, 'Verde');
    });

    test(
      'me gusta y comentarios de una publicación no cuentan como del proyecto',
      () async {
        final server = wall();
        final source = _sourceOver(server);
        final post = await source.createPublication(
          const Publication(
            id: '',
            projectId: 'p1',
            authorName: 'Natalia',
            title: 'Avance',
            content: 'Texto',
          ),
        );

        expect(await source.togglePublicationReaction(post), 1);
        await source.addComment('p1', 'Bien', publicationId: post.id);

        expect((await source.getLikeStatus('p1')).count, 0);
        expect(await source.getComments('p1'), isEmpty);
        final read = (await source.getPublications('p1')).single;
        expect(read.reactionCount, 1);
        expect(read.viewerReacted, isTrue);
        expect(read.comments.single.content, 'Bien');

        // Dar me gusta al proyecto no borra el de la publicación.
        await source.toggleLike('p1');
        await source.toggleLike('p1');
        expect((await source.getPublications('p1')).single.reactionCount, 1);
      },
    );

    test('borrar una encuesta la archiva y deja de verse', () async {
      final server = wall();
      final source = _sourceOver(server);
      final poll = await source.createPublication(
        const Publication(
          id: '',
          projectId: 'p1',
          authorName: 'Natalia',
          title: 'Encuesta',
          content: '',
          pollOptions: ['Sí', 'No'],
        ),
      );

      await source.deletePublication(poll);

      expect(server.rows('polls').single['status'], 'archived');
      expect(await source.getPublications('p1'), isEmpty);
    });
  });

  group('equipo completo', () {
    test(
      'aceptar en un rol sin cupos libres falla y no suma a nadie',
      () async {
        final server = FakeRobleServer({
          'project_members': [_member('ana', role: 'slot-1')],
          'project_roles': [
            {
              '_id': 'slot-1',
              'project_id': 'p1',
              'name': 'Dev',
              'status': 'assigned',
              'assigned_user_id': 'ana',
            },
          ],
        });

        await expectLater(
          _sourceOver(server).addMember(
            projectId: 'p1',
            member: const ProjectMember(id: 'luis', name: 'Luis'),
            projectRoleId: 'slot-1',
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('completo'),
            ),
          ),
        );
        expect(server.rows('project_members'), hasLength(1));
      },
    );

    test('quien entra sin rol (p. ej. el co-lider) no se rechaza', () async {
      final server = FakeRobleServer();

      await _sourceOver(server).addMember(
        projectId: 'p1',
        member: const ProjectMember(id: 'colider', name: 'Co'),
        projectRoleId: '',
      );

      expect(server.rows('project_members').single['user_id'], 'colider');
    });

    test('guardar deja max_members igual al tope que calcula la app', () async {
      final server = FakeRobleServer({
        'projects': [
          {
            '_id': 'p1',
            'name': 'MotionLab',
            'creator_id': 'owner',
            'max_members': 2,
          },
        ],
        'project_members': [_member('owner', creator: true)],
        'project_roles': [
          {
            '_id': 'slot-1',
            'project_id': 'p1',
            'name': 'Dev',
            'status': 'open',
          },
        ],
      });
      final source = _sourceOver(server);
      final detail = (await source.getDetail('p1'))!;

      await source.saveDetail(
        detail.copyWith(
          openRoles: [detail.openRoles.single.copyWith(totalSlots: 3)],
        ),
      );

      // El creador sin cupo + 3 cupos de Dev.
      expect(server.rows('projects').single['max_members'], 4);
      expect((await source.getDetail('p1'))!.maxMembers, 4);
    });
  });
}
