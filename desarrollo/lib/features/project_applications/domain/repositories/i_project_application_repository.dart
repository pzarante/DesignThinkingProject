import '../models/project_application.dart';

abstract class IProjectApplicationRepository {
  Future<List<ProjectApplication>> getForProject(String projectId);
  Future<List<ProjectApplication>> getForUser(String applicantId);

  Future<bool> hasApplied({
    required String projectId,
    required String applicantId,
  });

  /// La postulación propia y pendiente de un usuario en un proyecto, si
  /// existe. Se usa para editar/retirar desde el mismo botón que muestra
  /// "Postulación pendiente".
  Future<ProjectApplication?> getOwnApplication({
    required String projectId,
    required String applicantId,
  });

  Future<ProjectApplication> submit(ProjectApplication application);

  Future<ProjectApplication> updateStatus(
    String applicationId,
    ProjectApplicationStatus status,
  );

  /// Edita el rol, disponibilidad o motivación de una postulación propia
  /// que sigue pendiente.
  Future<ProjectApplication> update(ProjectApplication application);

  /// Retira una postulación propia antes de que sea resuelta.
  Future<void> withdraw(String applicationId);
}
