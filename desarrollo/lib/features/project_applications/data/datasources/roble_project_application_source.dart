import 'package:roble/roble.dart';

import '../../../../core/roble_read.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../../domain/models/project_application.dart';
import 'i_project_application_source.dart';

/// Postulaciones contra `project_applications` en ROBLE.
///
/// La fila solo guarda el cupo (`project_role_id`), no el proyecto: para
/// saber a qué proyecto pertenece una postulación se cruza con
/// `project_roles`, y el nombre de quien se postula sale de `users`. ROBLE
/// no hace joins, así que se lee cada tabla una vez y se cruza en Dart.
class RobleProjectApplicationSource implements IProjectApplicationSource {
  RobleProjectApplicationSource(this._db, this._authRepository);

  final RobleApiDataBase _db;
  final IAuthRepository _authRepository;

  static const _tableApplications = 'project_applications';
  static const _tableProjectRoles = 'project_roles';
  static const _tableUsers = 'users';

  @override
  Future<List<ProjectApplication>> getForProject(String projectId) async {
    // Sin sesión `readPublicOrPrivate` ignora los filtros: se vuelve a
    // filtrar aquí para no depender de eso.
    final roleRows = (await readPublicOrPrivate(
      _db,
      _tableProjectRoles,
      filters: {'project_id': projectId},
    )).where((r) => r['project_id'] == projectId).toList();
    final roleIds = {for (final r in roleRows) r['_id'] as String};
    if (roleIds.isEmpty) return const [];

    final rows = await _db.read(_tableApplications);
    final mine = rows.where((r) => roleIds.contains(r['project_role_id']));
    return _toApplications(mine, roleRows);
  }

  @override
  Future<List<ProjectApplication>> getForUser(String applicantId) async {
    final rows = await _db.read(
      _tableApplications,
      filters: {'applicant_id': applicantId},
    );
    if (rows.isEmpty) return const [];
    final roleRows = await readPublicOrPrivate(_db, _tableProjectRoles);
    return _toApplications(rows, roleRows);
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
    return application;
  }

  /// Borra la fila en vez de marcarla: una postulación retirada no deja
  /// rastro, y así se puede volver a postular más adelante.
  @override
  Future<void> withdraw(String applicationId) async {
    await _db.delete(_tableApplications, applicationId);
  }

  Future<ProjectApplication> _byId(String applicationId) async {
    final row = await _db.getById(_tableApplications, applicationId);
    if (row == null) throw StateError('No se encontró la postulación.');
    final roleRows = await readPublicOrPrivate(_db, _tableProjectRoles);
    return (await _toApplications([row], roleRows)).single;
  }

  Future<List<ProjectApplication>> _toApplications(
    Iterable<Map<String, dynamic>> rows,
    List<Map<String, dynamic>> roleRows,
  ) async {
    if (rows.isEmpty) return const [];
    final roleById = {for (final r in roleRows) r['_id'] as String: r};
    final users = await readPublicOrPrivate(_db, _tableUsers);
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
