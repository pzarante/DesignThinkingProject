import '../../domain/models/project_application.dart';

abstract class IProjectApplicationSource {
  Future<List<ProjectApplication>> getForProject(String projectId);

  Future<List<ProjectApplication>> getForUser(String applicantId);

  /// True si el usuario tiene una postulación pendiente en el proyecto.
  Future<bool> hasApplied({
    required String projectId,
    required String applicantId,
  });

  Future<ProjectApplication?> getOwnApplication({
    required String projectId,
    required String applicantId,
  });

  Future<ProjectApplication> submit(ProjectApplication application);

  Future<ProjectApplication> updateStatus(
    String applicationId,
    ProjectApplicationStatus status,
  );

  Future<ProjectApplication> update(ProjectApplication application);

  Future<void> withdraw(String applicationId);
}
