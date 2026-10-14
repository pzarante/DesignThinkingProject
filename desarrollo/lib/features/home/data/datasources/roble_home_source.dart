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
  static const _tableProjectApplications = 'project_applications';
  static const _tableProjectLinks = 'project_links';
  static const _tableProjectSaved = 'project_saved';

  @override
  Future<HomeFeed> getFeed() async {
    final me = await _authRepository.getLoggedUser();
    final myUserId = _authRepository.isAnonymous ? null : me?.id;

    // Todo de una vez, y filtrado en el servidor lo que se pueda: ROBLE solo
    // admite igualdad, pero eso basta para no bajar las filas de todo el
    // mundo (guardados, membresías y postulaciones de otras personas) ni los
    // proyectos sin publicar. Las postulaciones salen en la misma tanda en
    // vez de esperar a que termine la anterior.
    final applicationsFuture = myUserId == null
        ? Future.value(const <Map<String, dynamic>>[])
        : _pendingApplications(myUserId);
    final queries = <String, RobleQuery>{
      _tableStages: const RobleQuery(_tableStages),
      _tableTags: const RobleQuery(_tableTags),
      _tableProjectTags: const RobleQuery(_tableProjectTags),
      _tableProjectMembers: const RobleQuery(_tableProjectMembers, {
        'status': 'active',
      }),
      _tableProjects: const RobleQuery(_tableProjects, {'status': 'published'}),
      _tableCommunities: const RobleQuery(_tableCommunities),
      _tableProjectCommunities: const RobleQuery(_tableProjectCommunities),
      // Sin sesión no hay guardados ni comunidades propias que pedir.
      if (myUserId != null) ...{
        _tableProjectSaved: RobleQuery(_tableProjectSaved, {
          'user_id': myUserId,
        }),
        _tableCommunityMembers: RobleQuery(_tableCommunityMembers, {
          'user_id': myUserId,
        }),
      },
    };
    final results = await _cache.readQueries(queries.values.toList());
    final tables = {
      for (final (index, name) in queries.keys.indexed) name: results[index],
    };
    const none = <Map<String, dynamic>>[];
    final stages = tables[_tableStages]!;
    final tags = tables[_tableTags]!;
    final tagLinks = tables[_tableProjectTags]!;
    final memberRows = tables[_tableProjectMembers]!;
    final projectRows = tables[_tableProjects]!;
    final savedRows = tables[_tableProjectSaved] ?? none;
    final communityMembers = tables[_tableCommunityMembers] ?? none;
    final communities = tables[_tableCommunities]!;
    final projectCommunities = tables[_tableProjectCommunities]!;
    final applications = await applicationsFuture;

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

    final relationByProject = myUserId == null
        ? const <String, MyProjectRelation>{}
        : await _myRelations(myUserId, memberRows, applications);

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
      // Sin fila en project_members (proyectos viejos) manda creator_id.
      final relation =
          relationByProject[project.id] ??
          (myUserId != null && row['creator_id'] == myUserId
              ? MyProjectRelation.creator
              : null);
      if (relation != null) {
        myProjects.add(project.copyWith(myRelation: relation));
      } else {
        recommendedProjects.add(project);
      }
      // Postularse no lo vuelve propio: si estaba guardado, sigue ahí.
      if ((relation == null ||
              relation == MyProjectRelation.pendingApplication) &&
          savedProjectIds.contains(project.id)) {
        savedProjects.add(project);
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

  /// Las postulaciones pendientes de [userId]. Sin permiso (p. ej. invitado)
  /// no hay postulaciones que mostrar; eso no debe tumbar el resto del feed.
  Future<List<Map<String, dynamic>>> _pendingApplications(String userId) async {
    try {
      return await _cache.read(
        _tableProjectApplications,
        filters: {'applicant_id': userId, 'status': 'pending'},
      );
    } on RobleTableReadException {
      return const [];
    }
  }

  /// Qué es [userId] en cada proyecto: líder o integrante según su fila
  /// activa de `project_members`, o postulante si tiene una postulación
  /// pendiente a alguno de sus cupos (`project_roles.project_id`). Una
  /// postulación rechazada o aceptada no aparece: la aceptada ya es una
  /// membresía.
  Future<Map<String, MyProjectRelation>> _myRelations(
    String userId,
    List<Map<String, dynamic>> memberRows,
    List<Map<String, dynamic>> applications,
  ) async {
    final relations = <String, MyProjectRelation>{};
    for (final row in memberRows) {
      if (row['user_id'] != userId || row['status'] != 'active') continue;
      relations[row['project_id'] as String] = row['is_creator'] == true
          ? MyProjectRelation.creator
          : MyProjectRelation.member;
    }

    if (applications.isEmpty) return relations;
    final roleRows = await _cache.read(_tableProjectRoles);
    final projectByRole = {
      for (final r in roleRows) r['_id'] as String: r['project_id'] as String,
    };
    for (final application in applications) {
      if (application['applicant_id'] != userId ||
          application['status'] != 'pending') {
        continue;
      }
      final projectId = projectByRole[application['project_role_id']];
      if (projectId == null) continue;
      relations.putIfAbsent(
        projectId,
        () => MyProjectRelation.pendingApplication,
      );
    }
    return relations;
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
