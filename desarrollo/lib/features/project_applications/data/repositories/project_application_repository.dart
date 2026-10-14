import '../../domain/models/project_application.dart';
import '../../domain/repositories/i_project_application_repository.dart';
import '../datasources/i_project_application_source.dart';

class ProjectApplicationRepository implements IProjectApplicationRepository {
  ProjectApplicationRepository(this.source);

  final IProjectApplicationSource source;

  @override
  Future<List<ProjectApplication>> getForProject(String projectId) async =>
      await source.getForProject(projectId);

  @override
  Future<List<ProjectApplication>> getForUser(String applicantId) async =>
      await source.getForUser(applicantId);

  @override
  Future<bool> hasApplied({
    required String projectId,
    required String applicantId,
  }) async =>
      await source.hasApplied(projectId: projectId, applicantId: applicantId);

  @override
  Future<ProjectApplication?> getOwnApplication({
    required String projectId,
    required String applicantId,
  }) async => await source.getOwnApplication(
    projectId: projectId,
    applicantId: applicantId,
  );

  @override
  Future<ProjectApplication> submit(ProjectApplication application) async =>
      await source.submit(application);

  @override
  Future<ProjectApplication> updateStatus(
    String applicationId,
    ProjectApplicationStatus status,
  ) async => await source.updateStatus(applicationId, status);

  @override
  Future<ProjectApplication> update(ProjectApplication application) async =>
      await source.update(application);

  @override
  Future<void> withdraw(String applicationId) async =>
      await source.withdraw(applicationId);
}
