import 'dart:async';

import 'package:roble/roble.dart';

import '../../../../core/roble_cache.dart';
import '../../../auth/domain/account_required_exception.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../../domain/models/community_detail.dart';
import 'i_community_detail_source.dart';

/// Lee una comunidad y los proyectos que la acompañan.
///
/// El vínculo vive en `project_communities`, que es una tabla de unión pura:
/// una fila por (proyecto, comunidad). Como en el resto de la app, todas las
/// tablas se piden a la vez por [RobleTableCache] en vez de una detrás de
/// otra.
class RobleCommunityDetailSource implements ICommunityDetailSource {
  RobleCommunityDetailSource(this._db, this._cache, this._authRepository);

  final RobleApiDataBase _db;
  final RobleTableCache _cache;
  final IAuthRepository _authRepository;

  static const _tableCommunities = 'communities';
  static const _tableCommunityMembers = 'community_members';
  static const _tableProjectCommunities = 'project_communities';
  static const _tableProjects = 'projects';
  static const _tableProjectMembers = 'project_members';
  static const _tableStages = 'project_stages';
  static const _tableTags = 'tags';
  static const _tableProjectTags = 'project_tags';
  static const _tableUsers = 'users';
  static const _tableProjectRoleSkills = 'project_role_skills';
  static const _tableSkills = 'skills';

  @override
  Future<CommunityDetail?> getDetail(String communityId) async {
    // Filtrado en el servidor lo que ROBLE deja filtrar por esta comunidad.
    // `projects`, `project_members` y `project_tags` se bajan enteras porque
    // el servidor no admite "id en esta lista" y una petición por proyecto
    // sería más lenta; en Dart se recorta a los proyectos de la comunidad.
    // `project_members` va con `status=active`, la misma lectura que ya hace
    // el feed, así que se comparte en el caché. Etapas y tags son catálogos
    // pequeños.
    final byCommunity = {'community_id': communityId};
    final tables = await _cache.readQueries([
      RobleQuery(_tableCommunities, {'_id': communityId}),
      RobleQuery(_tableCommunityMembers, byCommunity),
      RobleQuery(_tableProjectCommunities, byCommunity),
      const RobleQuery(_tableProjects),
      const RobleQuery(_tableProjectMembers, {'status': 'active'}),
      const RobleQuery(_tableStages),
      const RobleQuery(_tableTags),
      const RobleQuery(_tableProjectTags),
    ]);

    final row = tables[0].where((c) => c['_id'] == communityId).firstOrNull;
    if (row == null) return null;

    _warmProjectDetail();

    final followers = tables[1]
        .where(
          (m) => m['community_id'] == communityId && m['status'] == 'active',
        )
        .toList();
    final myUserId = await _accountId();

    final projectIds = {
      for (final link in tables[2])
        if (link['community_id'] == communityId) link['project_id'] as String,
    };

    final activeMemberships = tables[4]
        .where((m) => m['status'] == 'active')
        .toList();
    final liveProjectIds = {
      for (final project in tables[3])
        if (projectIds.contains(project['_id']) &&
            project['deleted_at'] == null)
          project['_id'] as String,
    };
    final memberCountByProject = <String, int>{};
    // Miembros de la comunidad: personas distintas en al menos uno de sus
    // proyectos, no quienes solo la siguen.
    final communityMemberIds = <Object?>{};
    for (final membership in activeMemberships) {
      final projectId = membership['project_id'] as String;
      memberCountByProject[projectId] =
          (memberCountByProject[projectId] ?? 0) + 1;
      if (liveProjectIds.contains(projectId)) {
        communityMemberIds.add(membership['user_id']);
      }
    }

    final stageNameById = {
      for (final stage in tables[5])
        stage['_id'] as String: stage['name'] as String,
    };
    final tagNameById = {
      for (final tag in tables[6]) tag['_id'] as String: tag['name'] as String,
    };
    final tagNamesByProject = <String, List<String>>{};
    for (final link in tables[7]) {
      final name = tagNameById[link['tag_id'] as String];
      if (name == null) continue;
      (tagNamesByProject[link['project_id'] as String] ??= []).add(name);
    }

    final projects = [
      for (final project in tables[3])
        if (projectIds.contains(project['_id']) &&
            project['deleted_at'] == null)
          CommunityProject(
            id: project['_id'] as String,
            name: project['name'] as String,
            description: project['description'] as String?,
            coverUrl: project['cover_url'] as String?,
            stage: stageNameById[project['stage_id'] as String?],
            tags: tagNamesByProject[project['_id']] ?? const [],
            memberCount: memberCountByProject[project['_id']] ?? 1,
            createdAt: DateTime.tryParse('${project['created_at']}')?.toLocal(),
          ),
    ];
    projects.sort((a, b) {
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return CommunityDetail(
      id: communityId,
      name: row['name'] as String,
      description: row['description'] as String?,
      coverUrl: row['cover_url'] as String?,
      memberCount: communityMemberIds.length,
      followerCount: followers.length,
      isFollowing:
          myUserId != null && followers.any((m) => m['user_id'] == myUserId),
      isOwner: myUserId != null && row['created_by'] == myUserId,
      projects: projects,
    );
  }

  /// Calienta las tablas que el detalle de un proyecto baja enteras (ROBLE no
  /// filtra "id en esta lista"), para que abrir un proyecto desde este feed no
  /// las espere en frío. Es solo un adelanto: si falla, el detalle las pedirá
  /// él mismo.
  void _warmProjectDetail() {
    unawaited(
      _cache
          .readQueries(const [
            RobleQuery(_tableUsers),
            RobleQuery(_tableProjectRoleSkills),
            RobleQuery(_tableSkills),
          ])
          .then<void>((_) {})
          .catchError((Object _) {}),
    );
  }

  @override
  Future<bool> toggleFollowing(String communityId) async {
    final me = await _accountId();
    if (me == null) {
      throw const AccountRequiredException(
        'Inicia sesión para seguir comunidades y verlas en tu inicio.',
      );
    }

    final existing = await _db.read(
      _tableCommunityMembers,
      filters: {'community_id': communityId, 'user_id': me},
    );

    // Quien la creó no puede dejar de seguirla: borrar esa fila la dejaría
    // sin dueño y sin quien pueda configurarla.
    if (existing.any((row) => row['role'] == 'owner')) return true;

    final bool nowFollowing;
    if (existing.isNotEmpty) {
      for (final row in existing) {
        await _db.delete(_tableCommunityMembers, row['_id'] as String);
      }
      nowFollowing = false;
    } else {
      await _db.create(_tableCommunityMembers, {
        'community_id': communityId,
        'user_id': me,
        'role': 'member',
        'status': 'active',
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });
      nowFollowing = true;
    }

    _cache.invalidate([_tableCommunityMembers]);
    return nowFollowing;
  }

  /// Solo una cuenta de verdad sirve: un invitado es una identidad de usar y
  /// tirar, y seguir algo con ella no se podría recuperar después.
  Future<String?> _accountId() async {
    if (_authRepository.isAnonymous) return null;
    return (await _authRepository.getLoggedUser())?.id;
  }
}
