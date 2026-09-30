import 'package:roble/roble.dart';

import '../../../../core/roble_cache.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../../domain/models/community.dart';
import '../../domain/models/home_feed.dart';
import '../../domain/models/opportunity.dart';
import '../../domain/models/project.dart';
import 'i_home_source.dart';

/// Habla con ROBLE sobre proyectos y comunidades.
///
/// ROBLE no hace joins: lo que en SQL sería una consulta con varias tablas
/// aquí son varias lecturas que se cruzan en Dart (`project_stages`, `tags`,
/// `project_tags`, `project_members`).
class RobleHomeSource implements IHomeSource {
  RobleHomeSource(this._db, this._cache, this._authRepository);

  final RobleApiDataBase _db;
  final RobleTableCache _cache;
  final IAuthRepository _authRepository;

  static const _tableStages = 'project_stages';
  static const _tableTags = 'tags';
  static const _tableProjects = 'projects';
  static const _tableProjectTags = 'project_tags';
  static const _tableProjectMembers = 'project_members';
  static const _tableCommunities = 'communities';
  static const _tableCommunityMembers = 'community_members';
  static const _tableProjectCommunities = 'project_communities';
  static const _tableProjectRoles = 'project_roles';
  static const _tableProjectLinks = 'project_links';
  static const _tableProjectSaved = 'project_saved';

  @override
  Future<HomeFeed> getFeed() async {
    final me = await _authRepository.getLoggedUser();
    final myUserId = _authRepository.isAnonymous ? null : me?.id;

    // Todo de una vez: antes eran seis lecturas encadenadas y el feed no
    // aparecía hasta que volvía la última.
    final tables = await _cache.readAll([
      _tableStages,
      _tableTags,
      _tableProjectTags,
      _tableProjectMembers,
      _tableProjects,
      _tableProjectSaved,
      _tableCommunityMembers,
      _tableCommunities,
      _tableProjectCommunities,
    ]);
    final stages = tables[0];
    final tags = tables[1];
    final tagLinks = tables[2];
    final memberRows = tables[3];
    final projectRows = tables[4];
    final savedRows = tables[5];
    final communityMembers = tables[6];
    final communities = tables[7];
    final projectCommunities = tables[8];

    final stageNameById = {
      for (final row in stages) row['_id'] as String: row['name'] as String,
    };
    final tagNameById = {
      for (final row in tags) row['_id'] as String: row['name'] as String,
    };

    final tagNamesByProject = <String, List<String>>{};
    for (final link in tagLinks) {
      final tagName = tagNameById[link['tag_id'] as String];
      if (tagName == null) continue;
      (tagNamesByProject[link['project_id'] as String] ??= []).add(tagName);
    }

    final memberCountByProject = <String, int>{};
    for (final row in memberRows) {
      if (row['status'] != 'active') continue;
      final projectId = row['project_id'] as String;
      memberCountByProject[projectId] =
          (memberCountByProject[projectId] ?? 0) + 1;
    }

    final savedProjectIds = myUserId == null
        ? const <String>{}
        : {
            for (final row in savedRows)
              if (row['user_id'] == myUserId) row['project_id'] as String,
          };

    final myProjects = <Project>[];
    final recommendedProjects = <Project>[];
    final savedProjects = <Project>[];
    for (final row in projectRows) {
      if (row['status'] != 'published' || row['deleted_at'] != null) continue;
      final project = _toProject(
        row,
        stageNameById,
        tagNamesByProject,
        memberCountByProject,
      );
      if (myUserId != null && row['creator_id'] == myUserId) {
        myProjects.add(project);
      } else {
        recommendedProjects.add(project);
        if (savedProjectIds.contains(project.id)) savedProjects.add(project);
      }
    }

    return HomeFeed(
      followedCommunities: myUserId == null
          ? const <Community>[]
          : _communitiesFollowedBy(
              myUserId,
              communityMembers,
              communities,
              projectCommunities,
            ),
      recommendedProjects: recommendedProjects,
      // No hay tabla de convocatorias/oportunidades en el esquema todavía.
      opportunities: const <Opportunity>[],
      myProjects: myProjects,
      savedProjects: savedProjects,
    );
  }

  @override
  Future<Project> addProject(
    Project project, {
    required String problem,
    required String objective,
    String? scope,
    required int maxMembers,
    required String availability,
    String? coLeaderId,
    List<String> links = const [], 
  }) async {
    final userId = (await _authRepository.getLoggedUser())?.id;
    if (userId == null) {
      throw StateError('No hay sesión iniciada: no se puede publicar un proyecto.');
    }

    final stages = await _cache.read(_tableStages);
    final stageRow = stages.firstWhere(
      (row) => row['name'] == project.stage,
      orElse: () => throw StateError(
        'La etapa "${project.stage}" no existe en $_tableStages.',
      ),
    );

    final now = DateTime.now().toUtc().toIso8601String();
    final created = await _db.create(_tableProjects, {
      'creator_id': userId,
      'name': project.name,
      'description': project.description ?? '',
      'problem': problem,
      'objective': objective,
      'scope': scope,
      'stage_id': stageRow['_id'],
      'cover_url': project.imageUrl,
      'max_members': maxMembers,
      'availability': availability,
      'progress_percent': 0,
      'status': 'published',
      'created_at': now,
      'updated_at': now,
      'published_at': now,
    });
    final projectId = created['_id'] as String;

    for (final tagName in project.tags) {
      final tagId = await _findOrCreateTag(tagName);
      await _db.create(_tableProjectTags, {
        'project_id': projectId,
        'tag_id': tagId,
        'created_at': now,
      });
    }

    // Los roles buscados (project_roles): no traen detalle de habilidades
    // todavía (project_role_skills), pero publicar no debe perderlos.
    for (final roleName in project.requiredRoles) {
      await _db.create(_tableProjectRoles, {
        'project_id': projectId,
        'name': roleName,
        'status': 'open',
        'created_at': now,
        'updated_at': now,
      });
    }

    for (final url in links) {
      await _db.create(_tableProjectLinks, {
        'project_id': projectId,
        'url': url,
        'created_at': now,
      });
    }

    await _db.create(_tableProjectMembers, {
      'project_id': projectId,
      'user_id': userId,
      'is_creator': true,
      'is_co_leader': false,
      'status': 'active',
      'joined_at': now,
    });

    // El co-líder es opcional, y su selección venía del paso de equipo sin
    // llegar nunca a ninguna tabla: sin esto, el equipo publicado quedaba
    // siempre en uno solo, sin importar lo elegido en el asistente.
    if (coLeaderId != null) {
      await _db.create(_tableProjectMembers, {
        'project_id': projectId,
        'user_id': coLeaderId,
        'is_creator': false,
        'is_co_leader': true,
        'status': 'active',
        'joined_at': now,
      });
    }

    _cache.invalidate([
      _tableProjects,
      _tableProjectTags,
      _tableTags,
      _tableProjectRoles,
      _tableProjectLinks,
      _tableProjectMembers,
    ]);
    return project.copyWith(
      id: projectId,
      memberCount: coLeaderId == null ? 1 : 2,
    );
  }

  @override
  Future<void> addCommunity(Community community) async {
    final userId = (await _authRepository.getLoggedUser())?.id;
    if (userId == null) {
      throw StateError('No hay sesión iniciada: no se puede crear una comunidad.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final created = await _db.create(_tableCommunities, {
      'name': community.name,
      'description': community.description,
      'cover_url': community.coverUrl,
      'created_by': userId,
      'status': 'published',
      'created_at': now,
      'updated_at': now,
    });
    final communityId = created['_id'] as String;

    await _db.create(_tableCommunityMembers, {
      'community_id': communityId,
      'user_id': userId,
      'role': 'owner',
      'status': 'active',
      'joined_at': now,
    });

    for (final projectId in community.projectIds) {
      await _db.create(_tableProjectCommunities, {
        'community_id': communityId,
        'project_id': projectId,
        'created_at': now,
      });
    }

    _cache.invalidate([
      _tableCommunities,
      _tableCommunityMembers,
      _tableProjectCommunities,
    ]);
  }

  @override
  Future<void> updateProject(Project project) async {
    await _db.update(_tableProjects, project.id, {
      'name': project.name,
      'description': project.description,
      'cover_url': project.imageUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    final existingLinks = await _db.read(
      _tableProjectTags,
      filters: {'project_id': project.id},
    );
    for (final link in existingLinks) {
      await _db.delete(_tableProjectTags, link['_id'] as String);
    }
    for (final tagName in project.tags) {
      final tagId = await _findOrCreateTag(tagName);
      await _db.create(_tableProjectTags, {
        'project_id': project.id,
        'tag_id': tagId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    _cache.invalidate([_tableProjects, _tableProjectTags, _tableTags]);
  }

  @override
  Future<void> updateCommunity(Community community) async {
    await _db.update(_tableCommunities, community.id, {
      'name': community.name,
      'description': community.description,
      'cover_url': community.coverUrl,
      'status': community.isPublic ? 'published' : 'private',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    final existingLinks = await _db.read(
      _tableProjectCommunities,
      filters: {'community_id': community.id},
    );
    for (final link in existingLinks) {
      await _db.delete(_tableProjectCommunities, link['_id'] as String);
    }
    for (final projectId in community.projectIds) {
      await _db.create(_tableProjectCommunities, {
        'community_id': community.id,
        'project_id': projectId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    _cache.invalidate([_tableCommunities, _tableProjectCommunities]);
  }

  Future<String> _findOrCreateTag(String name) async {
    final normalized = name.trim().toLowerCase();
    final existing = await _db.read(
      _tableTags,
      filters: {'normalized_name': normalized},
    );
    if (existing.isNotEmpty) return existing.first['_id'] as String;
    final created = await _db.create(_tableTags, {
      'name': name.trim(),
      'normalized_name': normalized,
      'tag_type': 'user',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    return created['_id'] as String;
  }

  /// Las comunidades activas de esta persona, cruzadas sobre lo que ya se
  /// leyó: antes era una lectura por comunidad, dentro de un bucle.
  List<Community> _communitiesFollowedBy(
    String userId,
    List<Map<String, dynamic>> memberships,
    List<Map<String, dynamic>> communities,
    List<Map<String, dynamic>> projectLinks,
  ) {
    final myCommunityIds = {
      for (final membership in memberships)
        if (membership['user_id'] == userId && membership['status'] == 'active')
          membership['community_id'] as String,
    };
    if (myCommunityIds.isEmpty) return const [];

    final projectIdsByCommunity = <String, List<String>>{};
    for (final link in projectLinks) {
      (projectIdsByCommunity[link['community_id'] as String] ??= []).add(
        link['project_id'] as String,
      );
    }

    return [
      for (final row in communities)
        if (myCommunityIds.contains(row['_id']))
          Community(
            id: row['_id'] as String,
            name: row['name'] as String,
            description: row['description'] as String?,
            coverUrl: row['cover_url'] as String?,
            projectIds: projectIdsByCommunity[row['_id']] ?? const [],
          ),
    ];
  }

  Project _toProject(
    Map<String, dynamic> row,
    Map<String, String> stageNameById,
    Map<String, List<String>> tagNamesByProject,
    Map<String, int> memberCountByProject,
  ) {
    final id = row['_id'] as String;
    return Project(
      id: id,
      name: row['name'] as String,
      tags: tagNamesByProject[id] ?? const [],
      stage: stageNameById[row['stage_id'] as String?],
      memberCount: memberCountByProject[id] ?? 1,
      imageUrl: row['cover_url'] as String?,
      createdAt: row['created_at'] == null
          ? null
          : DateTime.tryParse('${row['created_at']}')?.toLocal(),
      description: row['description'] as String?,
    );
  }
}
