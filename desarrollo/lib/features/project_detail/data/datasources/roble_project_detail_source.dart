import 'package:roble/roble.dart';

import '../../../../core/roble_read.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../../domain/models/project_comment.dart';
import '../../domain/models/project_detail.dart';
import '../../domain/models/project_member.dart';
import '../../domain/models/project_role.dart';
import '../../domain/models/viewer_role.dart';
import 'i_project_detail_source.dart';

/// Habla con ROBLE sobre el detalle de un proyecto ya publicado: la propia
/// fila de `projects`, más lo que hay que cruzar a mano porque ROBLE no hace
/// joins (etapa, etiquetas, equipo, roles, enlaces, "me gusta", comentarios).
class RobleProjectDetailSource implements IProjectDetailSource {
  RobleProjectDetailSource(this._db, this._authRepository);

  final RobleApiDataBase _db;
  final IAuthRepository _authRepository;

  static const _tableProjects = 'projects';
  static const _tableStages = 'project_stages';
  static const _tableTags = 'tags';
  static const _tableProjectTags = 'project_tags';
  static const _tableProjectMembers = 'project_members';
  static const _tableProjectRoles = 'project_roles';
  static const _tableProjectLinks = 'project_links';
  static const _tableUsers = 'users';
  static const _tableReactions = 'reactions';
  static const _tableComments = 'comments';
  static const _likeType = 'like';

  @override
  Future<ProjectDetail?> getDetail(String projectId) async {
    final row = await getByIdPublicOrPrivate(_db, _tableProjects, projectId);
    if (row == null) return null;

    final stageName = await _stageName(row['stage_id'] as String?);
    final tags = await _tagsFor(projectId);
    final members = await _membersFor(projectId);
    final roles = await _rolesFor(projectId);
    final links = await _linksFor(projectId);
    final creator = await _userAsMember(row['creator_id'] as String?);

    final myUserId = (await _authRepository.getLoggedUser())?.id;
    final viewerRole = myUserId == null
        ? ViewerRole.visitor
        : myUserId == row['creator_id']
        ? ViewerRole.creator
        : members.any((m) => m.id == myUserId)
        ? ViewerRole.member
        : ViewerRole.visitor;

    return ProjectDetail(
      projectId: projectId,
      name: row['name'] as String,
      coverUrl: row['cover_url'] as String?,
      stage: stageName,
      tags: tags,
      creator: creator,
      description: row['description'] as String?,
      problem: row['problem'] as String?,
      objective: row['objective'] as String?,
      scope: row['scope'] as String?,
      progressPercent: (row['progress_percent'] as num?)?.toInt() ?? 0,
      links: links,
      members: members,
      maxMembers: (row['max_members'] as num?)?.toInt() ?? 0,
      openRoles: roles,
      availability: row['availability'] as String?,
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
    final rows = await readPublicOrPrivate(_db, _tableReactions);
    final mine = rows.where(
      (r) => r['project_id'] == projectId && r['reaction_type'] == _likeType,
    );
    final me = (await _authRepository.getLoggedUser())?.id;
    return (
      count: mine.length,
      likedByMe: me != null && mine.any((r) => r['user_id'] == me),
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
    final status = await getLikeStatus(projectId);
    return status.count;
  }

  @override
  Future<List<ProjectComment>> getComments(String projectId) async {
    final rows = await readPublicOrPrivate(_db, _tableComments);
    final mine =
        rows.where((r) => r['project_id'] == projectId).toList()..sort(
          (a, b) => '${a['created_at']}'.compareTo('${b['created_at']}'),
        );
    if (mine.isEmpty) return const [];

    final userRows = await readPublicOrPrivate(_db, _tableUsers);
    final nameById = {
      for (final u in userRows)
        u['user_id'] as String: (u['user_name'] as String?) ?? 'Invitado',
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
    return ProjectComment(
      id: created['_id'] as String,
      authorId: me.id ?? '',
      authorName: me.name.isEmpty ? 'Invitado' : me.name,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  Future<String?> _stageName(String? stageId) async {
    if (stageId == null) return null;
    final rows = await readPublicOrPrivate(_db, _tableStages);
    return rows.where((r) => r['_id'] == stageId).firstOrNull?['name']
        as String?;
  }

  Future<List<String>> _tagsFor(String projectId) async {
    final links = await readPublicOrPrivate(_db, _tableProjectTags);
    final tagIds = links
        .where((l) => l['project_id'] == projectId)
        .map((l) => l['tag_id'] as String)
        .toSet();
    if (tagIds.isEmpty) return const [];

    final tags = await readPublicOrPrivate(_db, _tableTags);
    return [
      for (final t in tags)
        if (tagIds.contains(t['_id'])) t['name'] as String,
    ];
  }

  Future<List<ProjectMember>> _membersFor(String projectId) async {
    final rows = await readPublicOrPrivate(_db, _tableProjectMembers);
    final mine = rows.where(
      (r) => r['project_id'] == projectId && r['status'] == 'active',
    );
    if (mine.isEmpty) return const [];

    final users = await readPublicOrPrivate(_db, _tableUsers);
    ProjectMember toMember(Map<String, dynamic> membership) {
      final userId = membership['user_id'] as String;
      final userRow = users.where((u) => u['user_id'] == userId).firstOrNull;
      final isCreator = membership['is_creator'] == true;
      final isCoLeader = membership['is_co_leader'] == true;
      return ProjectMember(
        id: userId,
        name: (userRow?['user_name'] as String?) ?? 'Sin nombre',
        avatarUrl: userRow?['avatar_url'] as String?,
        isCreator: isCreator,
        isCoLeader: isCoLeader,
        roleLabel: isCreator ? 'LÍDER' : (isCoLeader ? 'CO-LÍDER' : null),
      );
    }

    return [for (final m in mine) toMember(m)];
  }

  Future<List<ProjectRole>> _rolesFor(String projectId) async {
    final rows = await readPublicOrPrivate(_db, _tableProjectRoles);
    return [
      for (final r in rows)
        if (r['project_id'] == projectId && r['status'] == 'open')
          ProjectRole(title: r['name'] as String),
    ];
  }

  Future<List<String>> _linksFor(String projectId) async {
    final rows = await readPublicOrPrivate(_db, _tableProjectLinks);
    return [
      for (final r in rows)
        if (r['project_id'] == projectId) r['url'] as String,
    ];
  }

  Future<ProjectMember?> _userAsMember(String? userId) async {
    if (userId == null) return null;
    final users = await readPublicOrPrivate(_db, _tableUsers);
    final row = users.where((u) => u['user_id'] == userId).firstOrNull;
    if (row == null) return null;
    return ProjectMember(
      id: userId,
      name: (row['user_name'] as String?) ?? 'Sin nombre',
      avatarUrl: row['avatar_url'] as String?,
      isCreator: true,
    );
  }
}
