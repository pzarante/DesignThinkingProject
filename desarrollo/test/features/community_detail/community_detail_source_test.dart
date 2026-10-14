import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_clean_template/features/community_detail/data/datasources/roble_community_detail_source.dart';
import 'package:f_clean_template/features/community_detail/data/repositories/community_detail_repository.dart';
import 'package:f_clean_template/features/community_detail/ui/viewmodels/community_detail_controller.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_roble_server.dart';

Map<String, dynamic> _follower(
  String community,
  String user, {
  String status = 'active',
  String role = 'member',
}) => {
  'community_id': community,
  'user_id': user,
  'status': status,
  'role': role,
};

Map<String, dynamic> _membership(
  String project,
  String user, {
  String status = 'active',
}) => {'project_id': project, 'user_id': user, 'status': status};

FakeRobleServer _server() => FakeRobleServer({
  'communities': [
    {'_id': 'c1', 'name': 'Studio', 'created_by': 'owner'},
    {'_id': 'c2', 'name': 'Otra', 'created_by': 'x'},
  ],
  'community_members': [
    _follower('c1', 'owner', role: 'owner'),
    _follower('c1', 'ana'),
    _follower('c1', 'solo-sigue'),
    _follower('c1', 'tambien-solo-sigue'),
    _follower('c1', 'se-fue', status: 'left'),
    _follower('c2', 'otro'),
  ],
  'project_communities': [
    {'community_id': 'c1', 'project_id': 'p1'},
    {'community_id': 'c1', 'project_id': 'p2'},
    {'community_id': 'c1', 'project_id': 'borrado'},
    {'community_id': 'c2', 'project_id': 'p9'},
  ],
  'projects': [
    {'_id': 'p1', 'name': 'Uno', 'created_at': '2026-02-01T00:00:00Z'},
    {'_id': 'p2', 'name': 'Dos', 'created_at': '2026-03-01T00:00:00Z'},
    {'_id': 'borrado', 'name': 'Borrado', 'deleted_at': '2026-04-01T00:00:00Z'},
    {'_id': 'p9', 'name': 'De otra comunidad'},
  ],
  'project_members': [
    // ana participa en dos proyectos: cuenta una sola vez.
    _membership('p1', 'ana'),
    _membership('p2', 'ana'),
    _membership('p1', 'beto'),
    _membership('p2', 'carla'),
    // No cuentan: se salió, el proyecto está borrado o es de otra comunidad.
    _membership('p1', 'ex', status: 'left'),
    _membership('borrado', 'fantasma'),
    _membership('p9', 'otro'),
  ],
});

RobleCommunityDetailSource _sourceOver(
  FakeRobleServer server, {
  String me = 'ana',
}) {
  registerFakeAuth(id: me);
  return RobleCommunityDetailSource(
    server.db,
    server.cache,
    Get.find<IAuthRepository>(),
  );
}

void main() {
  tearDown(Get.reset);

  group('métricas', () {
    test(
      'memberCount cuenta personas con membresía activa en proyectos de la comunidad',
      () async {
        final detail = await _sourceOver(_server()).getDetail('c1');

        // ana (una vez), beto y carla.
        expect(detail!.memberCount, 3);
      },
    );

    test('memberCount no cuenta a quien solo sigue la comunidad', () async {
      final detail = await _sourceOver(_server()).getDetail('c1');

      // owner y solo-sigue siguen la comunidad pero no están en ningún proyecto.
      expect(detail!.followerCount, 4);
      expect(detail.memberCount, isNot(detail.followerCount));
    });

    test('los proyectos borrados no aportan miembros ni aparecen', () async {
      final detail = await _sourceOver(_server()).getDetail('c1');

      expect([for (final p in detail!.projects) p.id], ['p2', 'p1']);
      expect(
        detail.memberCount,
        3,
        reason: 'fantasma solo estaba en el borrado',
      );
    });

    test(
      'followerCount son las filas activas de community_members de esa comunidad',
      () async {
        final detail = await _sourceOver(_server()).getDetail('c1');

        // owner, ana y los dos que solo siguen; no se-fue (left) ni los de c2.
        expect(detail!.followerCount, 4);
      },
    );

    test('isFollowing refleja community_members del usuario actual', () async {
      final follows = await _sourceOver(
        _server(),
        me: 'solo-sigue',
      ).getDetail('c1');
      expect(follows!.isFollowing, isTrue);

      Get.reset();
      final doesNot = await _sourceOver(_server(), me: 'beto').getDetail('c1');
      // beto participa en un proyecto pero no sigue la comunidad.
      expect(doesNot!.isFollowing, isFalse);
      expect(doesNot.memberCount, 3);
    });

    test('quien creó la comunidad la ve como suya', () async {
      final detail = await _sourceOver(_server(), me: 'owner').getDetail('c1');

      expect(detail!.isOwner, isTrue);
    });

    test('una comunidad que no existe da null', () async {
      expect(await _sourceOver(_server()).getDetail('nada'), isNull);
    });
  });

  group('lecturas filtradas', () {
    test('pide la comunidad por _id y sus vínculos por community_id', () async {
      final server = _server();

      await _sourceOver(server).getDetail('c1');

      expect(
        [for (final r in server.readsOf('communities')) r.filters],
        [
          {'_id': 'c1'},
        ],
      );
      expect(
        [for (final r in server.readsOf('community_members')) r.filters],
        [
          {'community_id': 'c1'},
        ],
      );
      expect(
        [for (final r in server.readsOf('project_communities')) r.filters],
        [
          {'community_id': 'c1'},
        ],
      );
    });

    test('no baja las etapas ni los tags más de una vez', () async {
      final server = _server();

      await _sourceOver(server).getDetail('c1');

      expect(server.readsOf('project_stages'), hasLength(1));
      expect(server.readsOf('tags'), hasLength(1));
    });
  });

  group('seguir y dejar de seguir', () {
    test('actualiza followerCount e isFollowing en cada vuelta', () async {
      final server = _server();
      final source = _sourceOver(server, me: 'beto');
      final controller = CommunityDetailController(
        CommunityDetailRepository(source),
      );
      await controller.load('c1');
      expect(controller.community.value!.followerCount, 4);
      expect(controller.community.value!.isFollowing, isFalse);

      await controller.toggleFollowing();
      expect(controller.community.value!.isFollowing, isTrue);
      expect(controller.community.value!.followerCount, 5);
      // La fuente lo ve igual al releer: el caché se invalidó al escribir.
      expect((await source.getDetail('c1'))!.followerCount, 5);

      await controller.toggleFollowing();
      expect(controller.community.value!.isFollowing, isFalse);
      expect(controller.community.value!.followerCount, 4);
      expect((await source.getDetail('c1'))!.followerCount, 4);
    });

    test('seguir no cambia memberCount', () async {
      final server = _server();
      final source = _sourceOver(server, me: 'beto');

      await source.toggleFollowing('c1');

      expect((await source.getDetail('c1'))!.memberCount, 3);
    });

    test(
      'quien creó la comunidad no la puede dejar y el contador no se mueve',
      () async {
        final server = _server();
        final source = _sourceOver(server, me: 'owner');
        final controller = CommunityDetailController(
          CommunityDetailRepository(source),
        );
        await controller.load('c1');

        await controller.toggleFollowing();

        expect(controller.community.value!.isFollowing, isTrue);
        expect(controller.community.value!.followerCount, 4);
      },
    );
  });
}
