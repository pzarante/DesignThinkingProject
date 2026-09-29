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
///
/// Cupos: cada fila de `project_roles` es un cupo, y un rol con varios cupos
/// son varias filas con el mismo `name`. Aquí se agrupan por nombre al leer
/// y se crean/borran filas al guardar para que el número de cupos coincida.
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
  static const _tableProjectRoleSkills = 'project_role_skills';
  static const _tableSkills = 'skills';
  static const _tableProjectLinks = 'project_links';
  static const _tableUsers = 'users';
  static const _tableReactions = 'reactions';
  static const _tableComments = 'comments';
  static const _likeType = 'like';

  static const _slotOpen = 'open';
  static const _slotFilled = 'filled';

  /// Cupo de un rol que se quitó desde la configuración pero que alguien
  /// ocupa: no se borra (su integrante sigue apuntando a él), solo deja de
  /// mostrarse como vacante.
  static const _slotArchived = 'archived';

  static const _memberLeft = 'left';

  @override
  Future<ProjectDetail?> getDetail(String projectId) async {
    final row = await getByIdPublicOrPrivate(_db, _tableProjects, projectId);
    if (row == null) return null;

    final users = await readPublicOrPrivate(_db, _tableUsers);
    final roleRows = await _roleRowsFor(projectId);
    final stageName = await _stageName(row['stage_id'] as String?);
    final tags = await _tagsFor(projectId);
    final members = await _membersFor(projectId, users, roleRows);
    final roles = await _rolesFrom(roleRows);
    final links = await _linksFor(projectId);

    // El líder vive en `project_members.is_creator`, que puede cambiar si el
    // líder original se sale; `projects.creator_id` queda como respaldo para
    // proyectos sin filas de equipo.
    final leader =
        members.where((m) => m.isCreator).firstOrNull ??
        _userAsMember(row['creator_id'] as String?, users);

    final myUserId = (await _authRepository.getLoggedUser())?.id;
    final me = members.where((m) => m.id == myUserId).firstOrNull;
    final viewerRole = myUserId == null
        ? ViewerRole.visitor
        : me == null
        ? (members.isEmpty && myUserId == row['creator_id']
              ? ViewerRole.creator
              : ViewerRole.visitor)
        : me.isCreator
        ? ViewerRole.creator
        : me.isCoLeader
        ? ViewerRole.coLeader
        : ViewerRole.member;

    return ProjectDetail(
      projectId: projectId,
      name: row['name'] as String,
      coverUrl: row['cover_url'] as String?,
      stage: stageName,
      tags: tags,
      creator: leader,
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
    await _db.update(_tableProjects, detail.projectId, {
      'name': detail.name,
      'description': detail.description,
      'cover_url': detail.coverUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    // El equipo (quitar integrantes, co-líder) todavía no se escribe desde
    // aquí: la configuración trabaja sobre una copia que no ve a quien entra
    // mientras está abierta, y guardarla sacaría a esa persona.
    await _syncRoles(detail.projectId, detail.openRoles);
  }

  @override
  Future<ProjectMember> getCurrentUser() async {
    final user = await _authRepository.getLoggedUser();
    // Vacío y no una excepción: un visitante sin sesión también carga el
    // detalle, y solo se nota que no hay nadie cuando intenta algo que sí
    // lo exige (postularse, publicar).
    if (user?.id == null) {
      return ProjectMember(id: '', name: user?.name ?? '', email: user?.email);
    }
    final users = await readPublicOrPrivate(_db, _tableUsers);
    final row = users.where((u) => u['user_id'] == user!.id).firstOrNull;
    return ProjectMember(
      id: user!.id!,
      name: row == null ? user.name : _displayName(row),
      email: (row?['email'] as String?) ?? user.email,
      avatarUrl: row?['avatar_url'] as String?,
    );
  }

  @override
  Future<void> addMember({
    required String projectId,
    required ProjectMember member,
    required String projectRoleId,
  }) async {
    final userId = member.id;
    final now = DateTime.now().toUtc().toIso8601String();
    final roleRows = await _roleRowsFor(projectId);
    final requested = roleRows
        .where((r) => r['_id'] == projectRoleId)
        .firstOrNull;

    // El cupo pedido, o si otra aceptación ya lo llenó, cualquier otro libre
    // del mismo rol. Si el rol se borró, la persona entra sin cupo.
    final slot = requested != null && _isOpenSlot(requested)
        ? requested
        : roleRows
              .where(
                (r) => r['name'] == requested?['name'] && _isOpenSlot(r),
              )
              .firstOrNull;

    if (slot != null) {
      await _db.update(_tableProjectRoles, slot['_id'] as String, {
        'status': _slotFilled,
        'assigned_user_id': userId,
        'updated_at': now,
      });
    }

    final active = await _db.read(
      _tableProjectMembers,
      filters: {'project_id': projectId, 'user_id': userId, 'status': 'active'},
    );
    if (active.isNotEmpty) {
      await _db.update(_tableProjectMembers, active.first['_id'] as String, {
        'project_role_id': slot?['_id'],
      });
      return;
    }

    // Fila nueva aunque haya estado antes en el equipo: la vieja queda como
    // historial con su `left_at`.
    await _db.create(_tableProjectMembers, {
      'project_id': projectId,
      'user_id': userId,
      'project_role_id': slot?['_id'],
      'is_creator': false,
      'is_co_leader': false,
      'status': 'active',
      'joined_at': now,
    });
  }

  @override
  Future<void> leaveProject({
    required String projectId,
    String? newLeaderId,
  }) async {
    final me = (await _authRepository.getLoggedUser())?.id;
    if (me == null) throw StateError('Inicia sesión para salir del proyecto.');

    final rows = await _db.read(
      _tableProjectMembers,
      filters: {'project_id': projectId, 'status': 'active'},
    );
    final mine = rows.where((r) => r['user_id'] == me).firstOrNull;
    if (mine == null) throw StateError('Ya no formas parte de este proyecto.');

    final leaving = mine['is_creator'] == true;
    Map<String, dynamic>? successor;
    if (leaving) {
      successor = rows
          .where((r) => r['user_id'] == newLeaderId && r['user_id'] != me)
          .firstOrNull;
      if (successor == null) {
        throw StateError('Elige quién liderará el proyecto antes de salir.');
      }
      // Primero se nombra al nuevo líder: si algo falla después, el proyecto
      // no se queda nunca sin nadie a cargo.
      await _db.update(_tableProjectMembers, successor['_id'] as String, {
        'is_creator': true,
        'is_co_leader': false,
      });
    }

    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await _db.update(_tableProjectMembers, mine['_id'] as String, {
        'status': _memberLeft,
        'left_at': now,
        'is_creator': false,
        'is_co_leader': false,
      });
    } catch (_) {
      // ROBLE no tiene transacciones: se deshace el cambio de líder a mano
      // para no dejar dos líderes.
      if (successor != null) {
        await _db.update(_tableProjectMembers, successor['_id'] as String, {
          'is_creator': false,
          'is_co_leader': successor['is_co_leader'] == true,
        });
      }
      rethrow;
    }

    // Su cupo vuelve a quedar libre para otra postulación.
    final slotId = mine['project_role_id'] as String?;
    if (slotId != null) {
      await _db.update(_tableProjectRoles, slotId, {
        'status': _slotOpen,
        'assigned_user_id': null,
        'updated_at': now,
      });
    }
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

  Future<List<ProjectMember>> _membersFor(
    String projectId,
    List<Map<String, dynamic>> users,
    List<Map<String, dynamic>> roleRows,
  ) async {
    final rows = await readPublicOrPrivate(_db, _tableProjectMembers);
    final mine = rows.where(
      (r) => r['project_id'] == projectId && r['status'] == 'active',
    );
    if (mine.isEmpty) return const [];

    final roleNameById = {
      for (final r in roleRows) r['_id'] as String: r['name'] as String?,
    };

    ProjectMember toMember(Map<String, dynamic> membership) {
      final userId = membership['user_id'] as String;
      final userRow = users.where((u) => u['user_id'] == userId).firstOrNull;
      final isCreator = membership['is_creator'] == true;
      final isCoLeader = membership['is_co_leader'] == true;
      final roleId = membership['project_role_id'] as String?;
      final roleName = roleNameById[roleId];
      return ProjectMember(
        id: userId,
        name: _displayName(userRow),
        email: userRow?['email'] as String?,
        avatarUrl: userRow?['avatar_url'] as String?,
        isCreator: isCreator,
        isCoLeader: isCoLeader,
        roleLabel: isCreator
            ? 'LÍDER'
            : (isCoLeader ? 'CO-LÍDER' : roleName?.toUpperCase()),
        subtitle: roleName,
        membershipId: membership['_id'] as String?,
        projectRoleId: roleId,
        status: membership['status'] as String? ?? ProjectMember.activeStatus,
        joinedAt: _parseDate(membership['joined_at']),
        leftAt: _parseDate(membership['left_at']),
      );
    }

    // El líder primero, luego co-líder, luego el resto en orden de llegada.
    final members = [for (final m in mine) toMember(m)];
    int rank(ProjectMember m) => m.isCreator ? 0 : (m.isCoLeader ? 1 : 2);
    members.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return (a.joinedAt ?? DateTime(0)).compareTo(b.joinedAt ?? DateTime(0));
    });
    return members;
  }

  /// Filas de `project_roles` del proyecto, en orden de creación.
  ///
  /// Sin sesión `readPublicOrPrivate` ignora los filtros: se filtra otra vez
  /// en Dart para no depender de eso.
  Future<List<Map<String, dynamic>>> _roleRowsFor(String projectId) async {
    final rows = await readPublicOrPrivate(
      _db,
      _tableProjectRoles,
      filters: {'project_id': projectId},
    );
    return rows.where((r) => r['project_id'] == projectId).toList()
      ..sort((a, b) => '${a['created_at']}'.compareTo('${b['created_at']}'));
  }

  /// Agrupa los cupos por nombre en un [ProjectRole] por rol.
  Future<List<ProjectRole>> _rolesFrom(
    List<Map<String, dynamic>> roleRows,
  ) async {
    final visible = roleRows.where((r) => r['status'] != _slotArchived);
    final byName = <String, List<Map<String, dynamic>>>{};
    for (final row in visible) {
      (byName[row['name'] as String] ??= []).add(row);
    }
    if (byName.isEmpty) return const [];

    final skillsByRoleId = await _skillNamesByRoleId();

    return [
      for (final entry in byName.entries)
        ProjectRole(
          title: entry.key,
          description: entry.value
              .map((r) => r['description'] as String?)
              .firstWhere((d) => d != null && d.isNotEmpty, orElse: () => null),
          skills: {
            for (final r in entry.value) ...?skillsByRoleId[r['_id']],
          }.toList(),
          totalSlots: entry.value.length,
          filledSlots: entry.value.where((r) => !_isOpenSlot(r)).length,
          slotIds: [for (final r in entry.value) r['_id'] as String],
          openSlotIds: [
            for (final r in entry.value)
              if (_isOpenSlot(r)) r['_id'] as String,
          ],
        ),
    ];
  }

  Future<Map<String, List<String>>> _skillNamesByRoleId() async {
    final links = await readPublicOrPrivate(_db, _tableProjectRoleSkills);
    if (links.isEmpty) return const {};
    final skills = await readPublicOrPrivate(_db, _tableSkills);
    final nameById = {
      for (final s in skills) s['_id'] as String: s['name'] as String,
    };
    final result = <String, List<String>>{};
    for (final link in links) {
      final name = nameById[link['skill_id']];
      if (name == null) continue;
      (result[link['project_role_id'] as String] ??= []).add(name);
    }
    return result;
  }

  /// Deja `project_roles` igual a [roles]: renombra, agrega o quita cupos y
  /// actualiza sus habilidades.
  ///
  /// Un rol sin [ProjectRole.slotIds] se empareja por nombre con filas que
  /// todavía no reclamó nadie. Es el caso del asistente de creación, que ya
  /// insertó una fila por rol antes de guardar el detalle: sin esto, cada
  /// proyecto nuevo quedaría con sus roles duplicados.
  Future<void> _syncRoles(String projectId, List<ProjectRole> roles) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await _db.read(
      _tableProjectRoles,
      filters: {'project_id': projectId},
    );
    final claimed = <String>{};

    for (final role in roles) {
      final mine = role.slotIds.isNotEmpty
          ? rows.where((r) => role.hasSlot(r['_id'] as String)).toList()
          : rows
                .where(
                  (r) =>
                      r['name'] == role.title &&
                      r['status'] != _slotArchived &&
                      !claimed.contains(r['_id']),
                )
                .toList();
      claimed.addAll(mine.map((r) => r['_id'] as String));

      for (final row in mine) {
        if (row['name'] != role.title ||
            row['description'] != role.description) {
          await _db.update(_tableProjectRoles, row['_id'] as String, {
            'name': role.title,
            'description': role.description,
            'updated_at': now,
          });
        }
      }

      // Nunca menos cupos que los ya ocupados: la configuración no deja
      // bajar de ahí, y aquí se vuelve a asegurar.
      final filled = mine.where((r) => !_isOpenSlot(r)).length;
      final target = role.totalSlots < filled ? filled : role.totalSlots;
      final slotIds = [for (final r in mine) r['_id'] as String];

      for (var i = mine.length; i < target; i++) {
        final created = await _db.create(_tableProjectRoles, {
          'project_id': projectId,
          'name': role.title,
          'description': role.description,
          'status': _slotOpen,
          'created_at': now,
          'updated_at': now,
        });
        slotIds.add(created['_id'] as String);
      }

      final surplus = mine.length - target;
      if (surplus > 0) {
        final openRows = mine.where(_isOpenSlot).toList().reversed;
        for (final row in openRows.take(surplus)) {
          await _db.delete(_tableProjectRoles, row['_id'] as String);
          slotIds.remove(row['_id']);
        }
      }

      await _syncSkills(slotIds, role.skills);
    }

    // Roles quitados en la configuración.
    for (final row in rows) {
      if (claimed.contains(row['_id']) || row['status'] == _slotArchived) {
        continue;
      }
      if (_isOpenSlot(row)) {
        await _db.delete(_tableProjectRoles, row['_id'] as String);
      } else {
        await _db.update(_tableProjectRoles, row['_id'] as String, {
          'status': _slotArchived,
          'updated_at': now,
        });
      }
    }
  }

  Future<void> _syncSkills(List<String> roleIds, List<String> skillNames) async {
    if (roleIds.isEmpty) return;
    final links = await _db.read(_tableProjectRoleSkills);
    final wanted = <String>{};
    for (final name in skillNames) {
      wanted.add(await _findOrCreateSkill(name));
    }

    for (final roleId in roleIds) {
      final current = links.where((l) => l['project_role_id'] == roleId);
      final currentIds = {for (final l in current) l['skill_id'] as String};
      if (currentIds.length == wanted.length &&
          currentIds.containsAll(wanted)) {
        continue;
      }
      for (final link in current) {
        if (!wanted.contains(link['skill_id'])) {
          await _db.delete(_tableProjectRoleSkills, link['_id'] as String);
        }
      }
      for (final skillId in wanted.difference(currentIds)) {
        await _db.create(_tableProjectRoleSkills, {
          'project_role_id': roleId,
          'skill_id': skillId,
          'is_required': true,
        });
      }
    }
  }

  Future<String> _findOrCreateSkill(String name) async {
    final trimmed = name.trim();
    final all = await _db.read(_tableSkills);
    final existing = all
        .where(
          (s) =>
              (s['name'] as String?)?.toLowerCase() == trimmed.toLowerCase(),
        )
        .firstOrNull;
    if (existing != null) return existing['_id'] as String;
    final created = await _db.create(_tableSkills, {'name': trimmed});
    return created['_id'] as String;
  }

  Future<List<String>> _linksFor(String projectId) async {
    final rows = await readPublicOrPrivate(_db, _tableProjectLinks);
    return [
      for (final r in rows)
        if (r['project_id'] == projectId) r['url'] as String,
    ];
  }

  ProjectMember? _userAsMember(
    String? userId,
    List<Map<String, dynamic>> users,
  ) {
    if (userId == null) return null;
    final row = users.where((u) => u['user_id'] == userId).firstOrNull;
    if (row == null) return null;
    return ProjectMember(
      id: userId,
      name: _displayName(row),
      avatarUrl: row['avatar_url'] as String?,
      isCreator: true,
    );
  }

  bool _isOpenSlot(Map<String, dynamic> row) =>
      row['status'] == _slotOpen && row['assigned_user_id'] == null;

  String _displayName(Map<String, dynamic>? user) {
    final userName = user?['user_name'] as String?;
    if (userName != null && userName.isNotEmpty) return userName;
    final full = [user?['first_name'], user?['last_name']]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ');
    return full.isEmpty ? 'Sin nombre' : full;
  }

  DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.tryParse('$value')?.toLocal();
}
