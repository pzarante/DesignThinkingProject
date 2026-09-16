import '../models/project_application.dart';

abstract class IProjectApplicationRepository {
  Future<List<ProjectApplication>> getForProject(String projectId);

  Future<ProjectApplication> submit(ProjectApplication application);

  Future<ProjectApplication> updateStatus(
    String applicationId,
    ProjectApplicationStatus status,
  );
}