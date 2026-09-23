import '../models/project_application.dart';

abstract class IProjectApplicationRepository {
  Future<List<ProjectApplication>> getForProject(String projectId);

  /// Todas las postulaciones hechas por un usuario — lo consume "Mis
  /// aplicaciones" (Persona 4), no reimplementar el filtro ahí.
  Future<List<ProjectApplication>> getForUser(String applicantId);

  Future<bool> hasApplied({
    required String projectId,
    required String applicantId,
  });

  Future<ProjectApplication> submit(ProjectApplication application);

  Future<ProjectApplication> updateStatus(
    String applicationId,
    ProjectApplicationStatus status,
  );
}
