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
///
/// Cupos: cada fila de `project_roles` es un cupo, y un rol con varios cupos
/// son varias filas con el mismo `name`. Aquí se agrupan por nombre al leer
/// y se crean/borran filas al guardar para que el número de cupos coincida.
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
  static const _tableProjectRoleSkills = 'project_role_skills';
  static const _tableSkills = 'skills';
  static const _tableProjectLinks = 'project_links';
  static const _tableProjectCommunities = 'project_communities';
  static const _tableCommunities = 'communities';
  static const _tableUsers = 'users';
  static const _tableReactions = 'reactions';
  static const _tableComments = 'comments';
  static const _tableSaved = 'project_saved';
  static const _tableFollowers = 'project_followers';
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
    // Una sola tanda en paralelo en vez de doce lecturas encadenadas.
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
      _tableProjectRoleSkills,
      _tableSkills,
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
    final roleSkills = tables[10];
    final skills = tables[11];

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

    final roleRows = _roleRowsFor(projectId, roles);
    final team = _teamFor(projectId, members, userById, roleRows);

    // El líder vive en `project_members.is_creator`, que puede cambiar si el
    // líder original se sale; `projects.creator_id` queda como respaldo para
    // proyectos sin filas de equipo.
    final leader =
        team.where((m) => m.isCreator).firstOrNull ??
        _creator(row['creator_id'] as String?, userById);

    final myUserId = (await _authRepository.getLoggedUser())?.id;
    final me = team.where((m) => m.id == myUserId).firstOrNull;
    final viewerRole = myUserId == null
        ? ViewerRole.visitor
        : me == null
        ? (team.isEmpty && myUserId == row['creator_id']
              ? ViewerRole.creator
              : ViewerRole.visitor)
        : me.isCreator
        ? ViewerRole.creator
        : me.isCoLeader
        ? ViewerRole.coLeader
        : ViewerRole.member;

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
      creator: leader,
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
      openRoles: _rolesFrom(roleRows, _skillNamesByRoleId(roleSkills, skills)),
      availability: row['availability'] as String?,
      communityName: linkedCommunities.firstOrNull?.name,
      communities: linkedCommunities,
      viewerRole: viewerRole,
    );
  }

  @override
  Future<void> saveDetail(ProjectDetail detail) async {
    // Nombre, descripción y portada, igual que `RobleHomeSource.updateProject`,
    // más las vacantes. El equipo (quitar integrantes, co-líder) todavía no
    // se escribe desde aquí: la configuración trabaja sobre una copia que no
    // ve a quien entra mientras está abierta, y guardarla sacaría a esa
    // persona.
    await _db.update(_tableProjects, detail.projectId, {
      'name': detail.name,
      'description': detail.description,
      'cover_url': detail.coverUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    _cache.invalidate([_tableProjects]);
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
    final users = await _cache.read(_tableUsers);
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
    // Directo contra ROBLE y no por el caché: para escribir hace falta lo
    // último, no lo de hace un minuto.
    final roleRows = await _db.read(
      _tableProjectRoles,
      filters: {'project_id': projectId},
    );
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

    try {
      final active = await _db.read(
        _tableProjectMembers,
        filters: {
          'project_id': projectId,
          'user_id': userId,
          'status': ProjectMember.activeStatus,
        },
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
        'status': ProjectMember.activeStatus,
        'joined_at': now,
      });
    } finally {
      _cache.invalidate([_tableProjectRoles, _tableProjectMembers]);
    }
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
      filters: {'project_id': projectId, 'status': ProjectMember.activeStatus},
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
      _cache.invalidate([_tableProjectMembers]);
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
    _cache.invalidate([_tableProjectMembers, _tableProjectRoles]);
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

  /// Integrantes activos del proyecto: el líder primero, luego co-líder,
  /// luego el resto en orden de llegada.
  List<ProjectMember> _teamFor(
    String projectId,
    List<Map<String, dynamic>> memberRows,
    Map<String, Map<String, dynamic>> userById,
    List<Map<String, dynamic>> roleRows,
  ) {
    final roleNameById = {
      for (final r in roleRows) r['_id'] as String: r['name'] as String?,
    };

    final team = [
      for (final membership in memberRows)
        if (membership['project_id'] == projectId &&
            membership['status'] == ProjectMember.activeStatus)
          _toMember(membership, userById, roleNameById),
    ];
    int rank(ProjectMember m) => m.isCreator ? 0 : (m.isCoLeader ? 1 : 2);
    team.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return (a.joinedAt ?? DateTime(0)).compareTo(b.joinedAt ?? DateTime(0));
    });
    return team;
  }

  ProjectMember _toMember(
    Map<String, dynamic> membership,
    Map<String, Map<String, dynamic>> userById,
    Map<String, String?> roleNameById,
  ) {
    final userId = membership['user_id'] as String;
    final user = userById[userId];
    final isCreator = membership['is_creator'] == true;
    final isCoLeader = membership['is_co_leader'] == true;
    final roleId = membership['project_role_id'] as String?;
    final roleName = roleNameById[roleId];
    return ProjectMember(
      id: userId,
      name: _displayName(user),
      email: user?['email'] as String?,
      avatarUrl: user?['avatar_url'] as String?,
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

  ProjectMember? _creator(
    String? userId,
    Map<String, Map<String, dynamic>> userById,
  ) {
    if (userId == null) return null;
    final user = userById[userId];
    if (user == null) return null;
    return ProjectMember(
      id: userId,
      name: _displayName(user),
      avatarUrl: user['avatar_url'] as String?,
      isCreator: true,
    );
  }

  /// Filas de `project_roles` del proyecto, en orden de creación.
  List<Map<String, dynamic>> _roleRowsFor(
    String projectId,
    List<Map<String, dynamic>> roleRows,
  ) {
    return roleRows.where((r) => r['project_id'] == projectId).toList()
      ..sort((a, b) => '${a['created_at']}'.compareTo('${b['created_at']}'));
  }

  /// Agrupa los cupos por nombre en un [ProjectRole] por rol.
  List<ProjectRole> _rolesFrom(
    List<Map<String, dynamic>> roleRows,
    Map<String, List<String>> skillsByRoleId,
  ) {
    final visible = roleRows.where((r) => r['status'] != _slotArchived);
    final byName = <String, List<Map<String, dynamic>>>{};
    for (final row in visible) {
      (byName[row['name'] as String] ??= []).add(row);
    }
    if (byName.isEmpty) return const [];

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

  Map<String, List<String>> _skillNamesByRoleId(
    List<Map<String, dynamic>> links,
    List<Map<String, dynamic>> skills,
  ) {
    if (links.isEmpty) return const {};
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

    try {
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
    } finally {
      _cache.invalidate([
        _tableProjectRoles,
        _tableProjectRoleSkills,
        _tableSkills,
      ]);
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
