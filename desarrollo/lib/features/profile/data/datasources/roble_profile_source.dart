import 'package:roble/roble.dart';

import '../../../../core/roble_read.dart';
import '../../domain/models/profile_project.dart';
import '../../domain/models/user_profile.dart';
import 'i_profile_source.dart';

/// Lee los perfiles de la tabla `users` de ROBLE y lo que cuelga de ellos.
///
/// Como en el resto de la app, los cruces se hacen en Dart: ROBLE no tiene
/// joins ni agregados, así que "cuántos proyectos creó" es contar filas de
/// `projects` con ese `creator_id`.
class RobleProfileSource implements IProfileSource {
  RobleProfileSource(this._db);

  final RobleApiDataBase _db;

  static const _tableUsers = 'users';
  static const _tableProjects = 'projects';
  static const _tableProjectMembers = 'project_members';
  static const _tableCommunityMembers = 'community_members';
  static const _tableStages = 'project_stages';
  static const _tableTags = 'tags';
  static const _tableProjectTags = 'project_tags';

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final rows = await readPublicOrPrivate(_db, _tableUsers);
    final row = rows.where((r) => r['user_id'] == userId).firstOrNull;
    if (row == null) return null;

    final projects = await readPublicOrPrivate(_db, _tableProjects);
    final memberships = await readPublicOrPrivate(_db, _tableProjectMembers);
    final communities = await readPublicOrPrivate(_db, _tableCommunityMembers);

    return _toProfile(row).copyWith(
      stats: ProfileStats(
        createdProjects: projects
            .where((p) => p['creator_id'] == userId && !_isDeleted(p))
            .length,
        memberships: memberships
            .where(
              (m) =>
                  m['user_id'] == userId &&
                  m['status'] == 'active' &&
                  m['is_creator'] != true,
            )
            .length,
        communities: communities
            .where((c) => c['user_id'] == userId && c['status'] == 'active')
            .length,
      ),
    );
  }

  @override
  Future<List<UserSummary>> getUsers() async {
    final rows = await readPublicOrPrivate(_db, _tableUsers);
    final users = [
      for (final row in rows)
        if (row['user_id'] != null && row['user_name'] != null)
          UserSummary(
            userId: row['user_id'] as String,
            userName: row['user_name'] as String,
            fullName: _fullName(row),
            avatarUrl: row['avatar_url'] as String?,
            career: row['career'] as String?,
          ),
    ];
    users.sort(
      (a, b) => a.userName.toLowerCase().compareTo(b.userName.toLowerCase()),
    );
    return users;
  }

  @override
  Future<List<ProfileProject>> getProjectsOf(String userId) async {
    final projects = await readPublicOrPrivate(_db, _tableProjects);
    final memberships = await readPublicOrPrivate(_db, _tableProjectMembers);

    final active = memberships.where((m) => m['status'] == 'active').toList();
    final myProjectIds = {
      for (final m in active)
        if (m['user_id'] == userId) m['project_id'] as String,
    };

    final memberCountByProject = <String, int>{};
    for (final m in active) {
      final projectId = m['project_id'] as String;
      memberCountByProject[projectId] =
          (memberCountByProject[projectId] ?? 0) + 1;
    }

    final mine = projects
        .where(
          (p) =>
              !_isDeleted(p) &&
              (p['creator_id'] == userId || myProjectIds.contains(p['_id'])),
        )
        .toList();
    if (mine.isEmpty) return const [];

    final stageNameById = {
      for (final row in await readPublicOrPrivate(_db, _tableStages))
        row['_id'] as String: row['name'] as String,
    };
    final tagNameById = {
      for (final row in await readPublicOrPrivate(_db, _tableTags))
        row['_id'] as String: row['name'] as String,
    };
    final tagNamesByProject = <String, List<String>>{};
    for (final link in await readPublicOrPrivate(_db, _tableProjectTags)) {
      final name = tagNameById[link['tag_id'] as String];
      if (name == null) continue;
      (tagNamesByProject[link['project_id'] as String] ??= []).add(name);
    }

    final result = [
      for (final row in mine)
        ProfileProject(
          id: row['_id'] as String,
          name: row['name'] as String,
          description: row['description'] as String?,
          coverUrl: row['cover_url'] as String?,
          stage: stageNameById[row['stage_id'] as String?],
          tags: tagNamesByProject[row['_id']] ?? const [],
          memberCount: memberCountByProject[row['_id']] ?? 1,
          createdAt: DateTime.tryParse('${row['created_at']}')?.toLocal(),
          isCreator: row['creator_id'] == userId,
        ),
    ];
    // Lo más reciente primero; los que no traen fecha quedan al final en vez
    // de romper la comparación.
    result.sort((a, b) {
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return result;
  }

  /// `projects.deleted_at` marca el borrado lógico: una fila con fecha ahí no
  /// debe contar ni aparecer, aunque siga en la tabla.
  bool _isDeleted(Map<String, dynamic> project) => project['deleted_at'] != null;

  String? _fullName(Map<String, dynamic> row) {
    final full = [row['first_name'], row['last_name']]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' ');
    return full.isEmpty ? null : full;
  }

  UserProfile _toProfile(Map<String, dynamic> row) => UserProfile(
    userId: row['user_id'] as String,
    userName: (row['user_name'] as String?) ?? 'Sin nombre',
    firstName: row['first_name'] as String?,
    lastName: row['last_name'] as String?,
    email: row['email'] as String?,
    avatarUrl: row['avatar_url'] as String?,
    career: row['career'] as String?,
    academicYear: (row['academic_year'] as num?)?.toInt(),
    bio: row['bio'] as String?,
    joinedAt: DateTime.tryParse('${row['created_at']}')?.toLocal(),
  );
}
