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

  @override
  Future<CommunityDetail?> getDetail(String communityId) async {
    final tables = await _cache.readAll([
      _tableCommunities,
      _tableCommunityMembers,
      _tableProjectCommunities,
      _tableProjects,
      _tableProjectMembers,
      _tableStages,
      _tableTags,
      _tableProjectTags,
    ]);

    final row = tables[0].where((c) => c['_id'] == communityId).firstOrNull;
    if (row == null) return null;

    final members = tables[1]
        .where((m) => m['community_id'] == communityId && m['status'] == 'active')
        .toList();
    final myUserId = await _accountId();

    final projectIds = {
      for (final link in tables[2])
        if (link['community_id'] == communityId) link['project_id'] as String,
    };

    final activeMemberships = tables[4]
        .where((m) => m['status'] == 'active')
        .toList();
    final memberCountByProject = <String, int>{};
    for (final membership in activeMemberships) {
      final projectId = membership['project_id'] as String;
      memberCountByProject[projectId] =
          (memberCountByProject[projectId] ?? 0) + 1;
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
            createdAt: DateTime.tryParse(
              '${project['created_at']}',
            )?.toLocal(),
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
      memberCount: members.length,
      isMember: myUserId != null && members.any((m) => m['user_id'] == myUserId),
      isOwner: myUserId != null && row['created_by'] == myUserId,
      projects: projects,
    );
  }

  @override
  Future<bool> toggleMembership(String communityId) async {
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

    final bool nowMember;
    if (existing.isNotEmpty) {
      for (final row in existing) {
        await _db.delete(_tableCommunityMembers, row['_id'] as String);
      }
      nowMember = false;
    } else {
      await _db.create(_tableCommunityMembers, {
        'community_id': communityId,
        'user_id': me,
        'role': 'member',
        'status': 'active',
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });
      nowMember = true;
    }

    _cache.invalidate([_tableCommunityMembers]);
    return nowMember;
  }

  /// Solo una cuenta de verdad sirve: un invitado es una identidad de usar y
  /// tirar, y seguir algo con ella no se podría recuperar después.
  Future<String?> _accountId() async {
    if (_authRepository.isAnonymous) return null;
    return (await _authRepository.getLoggedUser())?.id;
  }
}
