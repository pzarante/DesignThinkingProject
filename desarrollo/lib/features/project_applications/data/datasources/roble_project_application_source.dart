import 'package:roble/roble.dart';

import '../../../../core/roble_cache.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../../domain/models/project_application.dart';
import 'i_project_application_source.dart';

/// Postulaciones contra `project_applications` en ROBLE.
///
/// La fila solo guarda el cupo (`project_role_id`), no el proyecto: para
/// saber a qué proyecto pertenece una postulación se cruza con
/// `project_roles`, y el nombre de quien se postula sale de `users`. ROBLE
/// no hace joins, así que las tablas se leen juntas por [RobleTableCache] y
/// se cruzan en Dart.
class RobleProjectApplicationSource implements IProjectApplicationSource {
  RobleProjectApplicationSource(this._db, this._cache, this._authRepository);

  final RobleApiDataBase _db;
  final RobleTableCache _cache;
  final IAuthRepository _authRepository;

  static const _tableApplications = 'project_applications';
  static const _tableProjectRoles = 'project_roles';
  static const _tableUsers = 'users';

  @override
  Future<List<ProjectApplication>> getForProject(String projectId) async {
    final tables = await _cache.readAll([
      _tableProjectRoles,
      _tableApplications,
      _tableUsers,
    ]);
    final roleRows = tables[0]
        .where((r) => r['project_id'] == projectId)
        .toList();
    final roleIds = {for (final r in roleRows) r['_id'] as String};
    if (roleIds.isEmpty) return const [];

    final mine = tables[1].where((r) => roleIds.contains(r['project_role_id']));
    return _toApplications(mine, roleRows, tables[2]);
  }

  @override
  Future<List<ProjectApplication>> getForUser(String applicantId) async {
    final tables = await _cache.readAll([
      _tableApplications,
      _tableProjectRoles,
      _tableUsers,
    ]);
    final mine = tables[0].where((r) => r['applicant_id'] == applicantId);
    return _toApplications(mine, tables[1], tables[2]);
  }

  @override
  Future<bool> hasApplied({
    required String projectId,
    required String applicantId,
  }) async {
    final own = await getOwnApplication(
      projectId: projectId,
      applicantId: applicantId,
    );
    return own != null;
  }

  @override
  Future<ProjectApplication?> getOwnApplication({
    required String projectId,
    required String applicantId,
  }) async {
    final all = await getForUser(applicantId);
    return all
        .where(
          (a) =>
              a.projectId == projectId &&
              a.status == ProjectApplicationStatus.pending,
        )
        .firstOrNull;
  }

  @override
  Future<ProjectApplication> submit(ProjectApplication application) async {
    final me = (await _authRepository.getLoggedUser())?.id;
    if (me == null) {
      throw StateError('Inicia sesión para postularte a un proyecto.');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final created = await _db.create(_tableApplications, {
      'applicant_id': me,
      'project_role_id': application.projectRoleId,
      'motivation': application.motivation,
      'availability': application.availability,
      'status': ProjectApplicationStatus.pending.name,
      'created_at': now,
      'updated_at': now,
    });
    _cache.invalidate([_tableApplications]);
    return ProjectApplication(
      id: created['_id'] as String,
      projectId: application.projectId,
      projectRoleId: application.projectRoleId,
      applicantId: me,
      applicantName: application.applicantName,
      applicantEmail: application.applicantEmail,
      motivation: application.motivation,
      availability: application.availability,
      roleTitle: application.roleTitle,
      createdAt: DateTime.parse(now).toLocal(),
    );
  }

  @override
  Future<ProjectApplication> updateStatus(
    String applicationId,
    ProjectApplicationStatus status,
  ) async {
    final me = (await _authRepository.getLoggedUser())?.id;
    await _db.update(_tableApplications, applicationId, {
      'status': status.name,
      'reviewed_by': me,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    _cache.invalidate([_tableApplications]);
    return _byId(applicationId);
  }

  @override
  Future<ProjectApplication> update(ProjectApplication application) async {
    await _db.update(_tableApplications, application.id, {
      'project_role_id': application.projectRoleId,
      'motivation': application.motivation,
      'availability': application.availability,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    _cache.invalidate([_tableApplications]);
    return application;
  }

  /// Borra la fila en vez de marcarla: una postulación retirada no deja
  /// rastro, y así se puede volver a postular más adelante.
  @override
  Future<void> withdraw(String applicationId) async {
    await _db.delete(_tableApplications, applicationId);
    _cache.invalidate([_tableApplications]);
  }

  Future<ProjectApplication> _byId(String applicationId) async {
    final tables = await _cache.readAll([
      _tableApplications,
      _tableProjectRoles,
      _tableUsers,
    ]);
    final row = tables[0].where((r) => r['_id'] == applicationId).firstOrNull;
    if (row == null) throw StateError('No se encontró la postulación.');
    final found = _toApplications([row], tables[1], tables[2]);
    if (found.isEmpty) {
      throw StateError('El cupo de esta postulación ya no existe.');
    }
    return found.single;
  }

  List<ProjectApplication> _toApplications(
    Iterable<Map<String, dynamic>> rows,
    List<Map<String, dynamic>> roleRows,
    List<Map<String, dynamic>> users,
  ) {
    if (rows.isEmpty) return const [];
    final roleById = {for (final r in roleRows) r['_id'] as String: r};
    final userById = {for (final u in users) u['user_id'] as String: u};

    final result = <ProjectApplication>[];
    for (final row in rows) {
      final roleId = row['project_role_id'] as String;
      final role = roleById[roleId];
      // Sin su cupo no hay forma de saber a qué proyecto pertenece.
      if (role == null) continue;
      final applicantId = row['applicant_id'] as String;
      final user = userById[applicantId];
      result.add(
        ProjectApplication(
          id: row['_id'] as String,
          projectId: role['project_id'] as String,
          projectRoleId: roleId,
          roleTitle: role['name'] as String?,
          applicantId: applicantId,
          applicantName: _displayName(user),
          applicantEmail: (user?['email'] as String?) ?? '',
          motivation: (row['motivation'] as String?) ?? '',
          availability: (row['availability'] as String?) ?? '',
          status: ProjectApplicationStatus.fromWire(row['status']),
          reviewedBy: row['reviewed_by'] as String?,
          createdAt:
              DateTime.tryParse('${row['created_at']}')?.toLocal() ??
              DateTime.now(),
        ),
      );
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  String _displayName(Map<String, dynamic>? user) {
    final userName = user?['user_name'] as String?;
    if (userName != null && userName.isNotEmpty) return userName;
    final full = [user?['first_name'], user?['last_name']]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ');
    return full.isEmpty ? 'Sin nombre' : full;
  }
}
