import 'package:roble/roble.dart';

import '../../../../core/roble_cache.dart';
import '../../../auth/domain/account_required_exception.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../../domain/models/project_comment.dart';
import '../../domain/models/project_community.dart';
import '../../domain/models/project_detail.dart';
import '../../domain/models/project_member.dart';
import '../../domain/models/project_role.dart';
import '../../domain/models/viewer_role.dart';
import 'i_project_detail_source.dart';

/// Habla con ROBLE sobre el detalle de un proyecto ya publicado.
///
/// Como ROBLE no hace joins, el detalle sale de cruzar una docena de tablas.
/// Lo importante para que la pantalla no tarde es **no pedirlas en fila**:
/// todas las lecturas van juntas por [RobleTableCache], que además une las
/// repetidas (`users` hace falta para el creador, para el equipo y para los
/// comentarios) en una sola petición.
class RobleProjectDetailSource implements IProjectDetailSource {
  RobleProjectDetailSource(this._db, this._cache, this._authRepository);

  final RobleApiDataBase _db;
  final RobleTableCache _cache;
  final IAuthRepository _authRepository;

  static const _tableProjects = 'projects';
  static const _tableStages = 'project_stages';
  static const _tableTags = 'tags';
  static const _tableProjectTags = 'project_tags';
  static const _tableProjectMembers = 'project_members';
  static const _tableProjectRoles = 'project_roles';
  static const _tableProjectLinks = 'project_links';
  static const _tableProjectCommunities = 'project_communities';
  static const _tableCommunities = 'communities';
  static const _tableUsers = 'users';
  static const _tableReactions = 'reactions';
  static const _tableComments = 'comments';
  static const _tableSaved = 'project_saved';
  static const _tableFollowers = 'project_followers';
  static const _likeType = 'like';

  @override
  Future<ProjectDetail?> getDetail(String projectId) async {
    // Una sola tanda en paralelo en vez de diez lecturas encadenadas.
    final tables = await _cache.readAll([
      _tableProjects,
      _tableStages,
      _tableTags,
      _tableProjectTags,
      _tableProjectMembers,
      _tableProjectRoles,
      _tableProjectLinks,
      _tableProjectCommunities,
      _tableCommunities,
      _tableUsers,
    ]);
    final projects = tables[0];
    final stages = tables[1];
    final tags = tables[2];
    final projectTags = tables[3];
    final members = tables[4];
    final roles = tables[5];
    final links = tables[6];
    final projectCommunities = tables[7];
    final communities = tables[8];
    final users = tables[9];

    final row = projects.where((p) => p['_id'] == projectId).firstOrNull;
    if (row == null) return null;

    final tagNameById = {
      for (final tag in tags) tag['_id'] as String: tag['name'] as String,
    };
    final projectTagNames = [
      for (final link in projectTags)
        if (link['project_id'] == projectId &&
            tagNameById.containsKey(link['tag_id']))
          tagNameById[link['tag_id']]!,
    ];

    final userById = {
      for (final user in users) user['user_id'] as String: user,
    };

    final team = [
      for (final membership in members)
        if (membership['project_id'] == projectId &&
            membership['status'] == 'active')
          _toMember(membership, userById),
    ];

    final myUserId = (await _authRepository.getLoggedUser())?.id;
    final viewerRole = myUserId == null
        ? ViewerRole.visitor
        : myUserId == row['creator_id']
        ? ViewerRole.creator
        : team.any((member) => member.id == myUserId)
        ? ViewerRole.member
        : ViewerRole.visitor;

    final communityNameById = {
      for (final community in communities)
        community['_id'] as String: community['name'] as String,
    };
    final linkedCommunities = [
      for (final link in projectCommunities)
        if (link['project_id'] == projectId &&
            communityNameById.containsKey(link['community_id']))
          ProjectCommunity(
            id: link['community_id'] as String,
            name: communityNameById[link['community_id']]!,
          ),
    ];

    return ProjectDetail(
      projectId: projectId,
      name: row['name'] as String,
      coverUrl: row['cover_url'] as String?,
      stage: stages
          .where((stage) => stage['_id'] == row['stage_id'])
          .firstOrNull?['name'] as String?,
      tags: projectTagNames,
      creator: _creator(row['creator_id'] as String?, userById),
      description: row['description'] as String?,
      problem: row['problem'] as String?,
      objective: row['objective'] as String?,
      scope: row['scope'] as String?,
      progressPercent: (row['progress_percent'] as num?)?.toInt() ?? 0,
      links: [
        for (final link in links)
          if (link['project_id'] == projectId) link['url'] as String,
      ],
      members: team,
      maxMembers: (row['max_members'] as num?)?.toInt() ?? 0,
      openRoles: [
        for (final role in roles)
          if (role['project_id'] == projectId && role['status'] == 'open')
            ProjectRole(title: role['name'] as String),
      ],
      availability: row['availability'] as String?,
      communityName: linkedCommunities.firstOrNull?.name,
      communities: linkedCommunities,
      viewerRole: viewerRole,
    );
  }

  @override
  Future<void> saveDetail(ProjectDetail detail) async {
    // Cubre lo mismo que `RobleHomeSource.updateProject`: nombre, descripción
    // y portada. Editar equipo o desvincular la comunidad desde la
    // configuración queda pendiente: todavía no hay para qué tabla escribir
    // eso sin arriesgar romper el resto del equipo.
    await _db.update(_tableProjects, detail.projectId, {
      'name': detail.name,
      'description': detail.description,
      'cover_url': detail.coverUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    _cache.invalidate([_tableProjects]);
  }

  @override
  Future<ProjectMember> getCurrentUser() async {
    final user = await _authRepository.getLoggedUser();
    // Vacío y no una excepción: un visitante sin sesión también carga el
    // detalle, y solo se nota que no hay nadie cuando intenta algo que sí
    // lo exige (postularse, publicar).
    return ProjectMember(
      id: user?.id ?? '',
      name: user?.name ?? '',
      email: user?.email,
    );
  }

  @override
  Future<({int count, bool likedByMe})> getLikeStatus(String projectId) async {
    final rows = await _cache.read(_tableReactions);
    final likes = rows.where(
      (r) => r['project_id'] == projectId && r['reaction_type'] == _likeType,
    );
    final me = (await _authRepository.getLoggedUser())?.id;
    return (
      count: likes.length,
      likedByMe: me != null && likes.any((r) => r['user_id'] == me),
    );
  }

  @override
  Future<int> toggleLike(String projectId) async {
    final me = await _authRepository.ensureGuestSession();
    final existing = await _db.read(
      _tableReactions,
      filters: {
        'project_id': projectId,
        'user_id': me.id,
        'reaction_type': _likeType,
      },
    );
    if (existing.isNotEmpty) {
      await _db.delete(_tableReactions, existing.first['_id'] as String);
    } else {
      await _db.create(_tableReactions, {
        'project_id': projectId,
        'user_id': me.id,
        'reaction_type': _likeType,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
    _cache.invalidate([_tableReactions]);
    return (await getLikeStatus(projectId)).count;
  }

  @override
  Future<({bool saved, bool following})> getViewerFlags(
    String projectId,
  ) async {
    final me = await _accountId();
    if (me == null) return (saved: false, following: false);

    final rows = await _cache.readAll([_tableSaved, _tableFollowers]);
    bool mine(Map<String, dynamic> row) =>
        row['project_id'] == projectId && row['user_id'] == me;

    return (
      saved: rows[0].any(mine),
      following: rows[1].any((row) => mine(row) && row['status'] == 'active'),
    );
  }

  @override
  Future<bool> toggleSaved(String projectId) => _toggleMembership(
    table: _tableSaved,
    projectId: projectId,
    needsAccountMessage:
        'Inicia sesión para guardar proyectos y verlos luego en Mis '
        'Proyectos.',
  );

  @override
  Future<bool> toggleFollowing(String projectId) => _toggleMembership(
    table: _tableFollowers,
    projectId: projectId,
    withStatus: true,
    needsAccountMessage: 'Inicia sesión para seguir proyectos.',
  );

  /// Crea o borra la fila que une a esta persona con el proyecto, y devuelve
  /// si quedó unida.
  ///
  /// `project_saved` y `project_followers` son la misma idea con distinta
  /// tabla: una fila por (proyecto, persona) que existe o no existe.
  Future<bool> _toggleMembership({
    required String table,
    required String projectId,
    required String needsAccountMessage,
    bool withStatus = false,
  }) async {
    final me = await _accountId();
    if (me == null) throw AccountRequiredException(needsAccountMessage);

    final existing = await _db.read(
      table,
      filters: {'project_id': projectId, 'user_id': me},
    );

    final bool nowLinked;
    if (existing.isNotEmpty) {
      for (final row in existing) {
        await _db.delete(table, row['_id'] as String);
      }
      nowLinked = false;
    } else {
      await _db.create(table, {
        'project_id': projectId,
        'user_id': me,
        if (withStatus) 'status': 'active',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      nowLinked = true;
    }

    _cache.invalidate([table]);
    return nowLinked;
  }

  @override
  Future<List<ProjectComment>> getComments(String projectId) async {
    final tables = await _cache.readAll([_tableComments, _tableUsers]);
    final mine =
        tables[0].where((r) => r['project_id'] == projectId).toList()..sort(
          (a, b) => '${a['created_at']}'.compareTo('${b['created_at']}'),
        );
    if (mine.isEmpty) return const [];

    final nameById = {
      for (final user in tables[1])
        user['user_id'] as String: (user['user_name'] as String?) ?? 'Invitado',
    };

    return [
      for (final row in mine)
        ProjectComment(
          id: row['_id'] as String,
          authorId: row['author_id'] as String,
          authorName: nameById[row['author_id']] ?? 'Invitado',
          content: row['content'] as String,
          createdAt: DateTime.parse('${row['created_at']}').toLocal(),
        ),
    ];
  }

  @override
  Future<ProjectComment> addComment(String projectId, String content) async {
    final me = await _authRepository.ensureGuestSession();
    final created = await _db.create(_tableComments, {
      'project_id': projectId,
      'author_id': me.id,
      'content': content,
      'status': 'published',
    });
    _cache.invalidate([_tableComments]);
    return ProjectComment(
      id: created['_id'] as String,
      authorId: me.id ?? '',
      authorName: me.name.isEmpty ? 'Invitado' : me.name,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  /// El id de quien tiene sesión, solo si es una cuenta de verdad: un
  /// invitado no sirve para guardar ni seguir.
  Future<String?> _accountId() async {
    if (_authRepository.isAnonymous) return null;
    return (await _authRepository.getLoggedUser())?.id;
  }

  ProjectMember _toMember(
    Map<String, dynamic> membership,
    Map<String, Map<String, dynamic>> userById,
  ) {
    final userId = membership['user_id'] as String;
    final user = userById[userId];
    final isCreator = membership['is_creator'] == true;
    final isCoLeader = membership['is_co_leader'] == true;
    return ProjectMember(
      id: userId,
      name: (user?['user_name'] as String?) ?? 'Sin nombre',
      avatarUrl: user?['avatar_url'] as String?,
      isCreator: isCreator,
      isCoLeader: isCoLeader,
      roleLabel: isCreator ? 'LÍDER' : (isCoLeader ? 'CO-LÍDER' : null),
    );
  }

  ProjectMember? _creator(
    String? userId,
    Map<String, Map<String, dynamic>> userById,
  ) {
    if (userId == null) return null;
    final user = userById[userId];
    if (user == null) return null;
    return ProjectMember(
      id: userId,
      name: (user['user_name'] as String?) ?? 'Sin nombre',
      avatarUrl: user['avatar_url'] as String?,
      isCreator: true,
    );
  }
}
